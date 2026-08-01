library(readxl)
library(sf)
library(dplyr)
library(spdep)
library(splm)
library(plm)
library(did)
library(ggplot2)
library(MASS)
library(tidyr)
library(purrr)

##### Import Data
dat = read_xlsx("dat.xlsx")   #original data 
dat = dat %>% arrange(id, year)

korea = geojsonsf::geojson_sf("korea.geojson")   #shp file for korea si-gun-gu units
final = merge(dat, korea, all.x = TRUE, by = c("province", "sigungu")) %>%
  st_as_sf() %>% 
  arrange(id, year)

#######  COVID-19 sensitivity analysis (Table S5): exclude 2020-2022   ######
# final = final %>% filter(!(year %in% 2020:2022))

#################################################
#        Generate Spatial Weight Matrices       #
#################################################
geo_base = final %>%
  filter(year == max(year)) %>%
  arrange(id)

geo_base_proj = st_transform(geo_base, 5179)

cent = st_centroid(
  st_geometry(geo_base_proj),
  of_largest_polygon = TRUE
)

coords = st_coordinates(cent)

Dmat = as.matrix(dist(coords))
diag(Dmat) = Inf

### kNN weights
make_knn_listw = function(k) {
  knn = knearneigh(coords, k = k)
  nb = knn2nb(knn)
  nb2listw(nb, style = "W")
}


### Inverse-distance cutoff matrix
make_inv_cutoff_listw = function(cutoff) {
  W = ifelse(Dmat <= cutoff, 1 / Dmat, 0)
  diag(W) = 0
  W[!is.finite(W)] = 0
  
  zero_rows = which(rowSums(W) == 0)
  if (length(zero_rows) > 0) {
    stop(paste0(
      "Zero-neighbor rows exist: ",
      paste(zero_rows, collapse = ", "),
      ". Increase cutoff or use kNN."
    ))
  }
  
  mat2listw(W, style = "W")
}



listw_k3 = make_knn_listw(3)
listw_k5 = make_knn_listw(5)  ## main spatial weight
listw_k7 = make_knn_listw(7)
listw_d50 = make_inv_cutoff_listw(50000)
listw_d70 = make_inv_cutoff_listw(70000)



##################################################
#       WX: Manually Generated Durbin Terms      # 
##################################################
urban = 'pop_density + industrial_area + commercial_area + green_area_per_capita'
car = 'daily_km + road_paving_rate + cars_per_capita'
climate = 'avg_rain + annual_humid + summer_temp + winter_temp + summer_sun + stagnation_days'

vars = c(
  "did",
  "pop_density",
  "industrial_area",
  "commercial_area",
  "green_area_per_capita",
  "daily_km",
  "road_paving_rate",
  "cars_per_capita",
  "avg_rain",
  "annual_humid",
  "summer_temp",
  "winter_temp",
  "summer_sun",
  "stagnation_days"
)

######## Robustness Check(Rain Sensitivity, Table S6): Exclude avg_rain  #######
## climate = climate[climate != 'avg_rain']
## vars = vars[vars != "avg_rain"]

make_wvars = function(data, listw_obj, vars) {
  
  out = data %>%
    arrange(id, year)
  
  for (v in vars) {
    out[[paste0("w_", v)]] = NA_real_
  }
  
  yrs = sort(unique(out$year))
  
  for (yy in yrs) {
    
    idx = which(out$year == yy)
    
    tmp = out[idx, ] %>%
      arrange(id)
    
    for (v in vars) {
      wv = lag.listw(
        listw_obj,
        tmp[[v]],
        zero.policy = TRUE
      )
      
      out[[paste0("w_", v)]][idx[order(out$id[idx])]] = as.numeric(wv)
    }
  }
  
  out %>% arrange(id, year)
}

# data with Wx
final_k3     = make_wvars(final, listw_k3, vars)   
final_k5     = make_wvars(final, listw_k5, vars)  #knn=5
final_k7     = make_wvars(final, listw_k7, vars)
final_d50   = make_wvars(final, listw_d50, vars)  
final_d70   = make_wvars(final, listw_d70, vars)

#################################################
#       Direct, Indirect, Total Effect          #
#################################################
w_urban = 'w_pop_density + w_industrial_area + w_commercial_area + w_green_area_per_capita'
w_car = 'w_daily_km + w_road_paving_rate + w_cars_per_capita'
w_climate = 'w_avg_rain + w_annual_humid + w_summer_temp + w_winter_temp + w_summer_sun + w_stagnation_days'

sdid_fn = function(data, listw_obj, y, R = R) {
  
  dat = data %>%
    st_drop_geometry() %>%
    arrange(id, year)
  
  fml = as.formula(paste0(
    y, " ~ did + w_did + ",
    " + ", urban, " + ", car, " + ", climate, " + ",
    " + ", w_urban, " + ", w_car, " + ", w_climate
  ))
  
  fit = spml(
    fml,
    data = dat,
    listw = listw_obj,
    index = c("id", "year"),
    model = "within",
    effect = "twoways",
    lag = TRUE,
    spatial.error = "none"
  )
  
  b = coef(fit)
  V = vcov(fit)
  
  W = listw2mat(listw_obj)
  n = nrow(W)
  I = diag(n)
  
  calc_impacts = function(coefs) {
    
    rho = as.numeric(coefs["lambda"])
    Ainv = solve(I - rho * W)
    
    out = lapply(vars, function(v) {
      
      beta = coefs[v]
      theta = coefs[paste0("w_", v)]
      
      if (is.na(beta)) beta = 0
      if (is.na(theta)) theta = 0
      
      S = Ainv %*% (beta * I + theta * W)
      
      direct = mean(diag(S))
      total = mean(rowSums(S))
      indirect = total - direct
      
      c(
        Direct = direct,
        Indirect = indirect,
        Total = total
      )
    })
    
    out = do.call(rbind, out)
    rownames(out) = vars
    out
  }
  
  est = calc_impacts(b)
  
  set.seed(123)
  sim_b = MASS::mvrnorm(R, mu = b, Sigma = V)
  
  sim_arr = array(
    NA,
    dim = c(length(vars), 3, R),
    dimnames = list(vars, c("Direct", "Indirect", "Total"), NULL)
  )
  
  for (r in 1:R) {
    sim_arr[, , r] = calc_impacts(sim_b[r, ])
  }
  
  se = apply(sim_arr, c(1, 2), sd)
  z = est / se
  p = 2 * pnorm(abs(z), lower.tail = FALSE)
  
  list(
    model = fit,
    estimate = est,
    se = se,
    z = z,
    p = p
  )
}



outcomes = c("no2", "so2", "co", "pm10", "o3")

R = 2000
run_weight_models = function(data, listw_obj, weight_name) {
  
  res = lapply(outcomes, function(y) {
    sdid_fn(data, listw_obj, y, R = R)
  })
  
  names(res) = outcomes
  attr(res, "weight") = weight_name
  
  res
}

res_k3     = run_weight_models(final_k3, listw_k3, "kNN k=3")
res_k5     = run_weight_models(final_k5, listw_k5, "kNN k=5")
res_k7     = run_weight_models(final_k7, listw_k7, "kNN k=7")
res_d50   = run_weight_models(final_d50, listw_d50, "Inverse distance cutoff 50km")
res_d70   = run_weight_models(final_d70, listw_d70, "Inverse distance cutoff 70km")


#### Lambda Estimate
outcomes = c("no2", "co", "so2", "o3", "pm10")
data.frame(
  Lambda = sapply(outcomes, function(x)
    sprintf("%.3f%s",
            coef(res_k5[[x]]$model)["lambda"],
            ifelse(summary(res_k5[[x]]$model)$Coef["lambda","Pr(>|t|)"] < 0.001, "***",
                   ifelse(summary(res_k5[[x]]$model)$Coef["lambda","Pr(>|t|)"] < 0.01, "**",
                          ifelse(summary(res_k5[[x]]$model)$Coef["lambda","Pr(>|t|)"] < 0.05, "*", ""))))
  ))

### Direct, Indirect, Total
add_star = function(est, p) {
  star = case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    p < 0.10  ~ ".",
    TRUE      ~ ""
  )
  
  paste0(sprintf("%.3f", est), star)
}

result_knn5 = map_dfr(outcomes, function(outcome){
  
  est = res_k5[[outcome]]$estimate["did", ]
  se  = res_k5[[outcome]]$se["did", ]
  p   = res_k5[[outcome]]$p["did", ]
  
  tibble(
    outcome = toupper(outcome),
    
    direct_estimate   = add_star(est[1], p[1]),
    direct_se         = sprintf("%.3f", se[1]),
    
    indirect_estimate = add_star(est[2], p[2]),
    indirect_se       = sprintf("%.3f", se[2]),
    
    total_estimate    = add_star(est[3], p[3]),
    total_se          = sprintf("%.3f", se[3])
  )
})

result_knn5


####### Robustness Check(Alternative Matrix): Direct, Indirect, Total Effect
stars = function(p){
  ifelse(p < 0.01, "***",
         ifelse(p < 0.05, "**",
                ifelse(p < 0.1, "*", "")))
}

make_table = function(res, outcome){
  
  est = res[[outcome]]$estimate["did", ]
  p   = res[[outcome]]$p["did", ]
  
  c(
    sprintf("%.3f%s", est["Direct"],   stars(p["Direct"])),
    sprintf("%.3f%s", est["Indirect"], stars(p["Indirect"])),
    sprintf("%.3f%s", est["Total"],    stars(p["Total"]))
  )
}

weights = list(
  "KNN (k = 3)" = res_k3,
  "KNN (k = 7)" = res_k7,
  "Inverse-distance 50 km" = res_d50,
  "Inverse-distance 70 km" = res_d70
)

outcomes = c("no2","co","so2","o3","pm10")

alt_result = lapply(outcomes, function(y){
  
  out = do.call(rbind,
                 lapply(weights, make_table, outcome = y))
  
  out = data.frame(out, check.names = FALSE)
  colnames(out) = c("Direct","Indirect","Total")
  out
})


names(alt_result) = toupper(outcomes)
alt_result




