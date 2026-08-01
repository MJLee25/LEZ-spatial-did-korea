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


##### Import Data
dat = read_xlsx("dat.xlsx")   
dat = dat %>% arrange(id, year)

korea = geojsonsf::geojson_sf("korea.geojson")    #shp file for korea si-gun-gu units
final = merge(dat, korea, all.x = TRUE, by = c("province", "sigungu")) %>%
  st_as_sf() %>% 
  arrange(id, year)



#####################################################################
#                                                                   #
#                         Placebo Test                              #
#                                                                   #
#####################################################################
urban = 'pop_density + industrial_area + commercial_area + green_area_per_capita'
car = 'daily_km + road_paving_rate + cars_per_capita'
climate = 'avg_rain + annual_humid + summer_temp + winter_temp + summer_sun + stagnation_days'

R = 500    # 500 random simulation for placebo test
placebo_loop = function(y, R = R, seed = 123){
  
  set.seed(seed)
  
  dat0 = final %>% 
    st_drop_geometry() %>% 
    arrange(id, year)
  
  id_level = dat0 %>%
    group_by(id) %>%
    summarise(
      D1 = max(D1, na.rm = TRUE),
      D2 = max(D2, na.rm = TRUE),
      D3 = max(D3, na.rm = TRUE),
      .groups = "drop"
    )
  
  ids = id_level$id
  
  n_D1 = sum(id_level$D1 == 1)
  n_D2 = sum(id_level$D2 == 1)
  n_D3 = sum(id_level$D3 == 1)
  
  res = data.frame(
    iter = 1:R,
    coef_did = NA_real_,
    p_did = NA_real_
  )
  
  for(r in 1:R){
    
    fake_D3_ids = sample(ids, n_D3, replace = FALSE)
    fake_D2_ids = sample(fake_D3_ids, n_D2, replace = FALSE)
    fake_D1_ids = sample(fake_D2_ids, n_D1, replace = FALSE)
    
    dat = dat0 %>%
      mutate(
        fake_D3 = ifelse(id %in% fake_D3_ids, 1, 0),
        fake_D2 = ifelse(id %in% fake_D2_ids, 1, 0),
        fake_D1 = ifelse(id %in% fake_D1_ids, 1, 0),
        
        g_fake = case_when(
          fake_D1 == 1 ~ 2017,
          fake_D1 == 0 & fake_D2 == 1 ~ 2018,
          fake_D2 == 0 & fake_D3 == 1 ~ 2020,
          TRUE ~ Inf
        ),
        
        did_fake = ifelse(year >= g_fake, 1, 0),
        did_fake = ifelse(is.infinite(g_fake), 0, did_fake)
      )
    
    fml = as.formula(
      paste0(y, " ~ did_fake + ", urban, "+", car, "+", climate)
    )
    
    model = plm(
      fml,
      data = dat,
      effect = "twoways",
      model = "within",
      index = c("id", "year")
    )
    
    sm = summary(model)
    
    res$coef_did[r] = sm$coefficients["did_fake", "Estimate"]
    res$p_did[r] = sm$coefficients["did_fake", "Pr(>|t|)"]
  }
  
  return(res)
}

pl_no2 = placebo_loop("no2", R = R)
pl_so2 = placebo_loop("so2", R = R)
pl_co = placebo_loop("co", R = R)
pl_o3 = placebo_loop("o3", R = R)
pl_pm10 = placebo_loop("pm10", R = R)



#### True coefficient
twfe_did = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did", '+', urban, '+', car, '+', climate)
  )
  
  model = plm(fml, data = dat, effect = "twoways", model = "within", index = c('id','year'))  
  summary(model)
}


pl_no2_real = twfe_did('no2')$coefficients['did',"Estimate"]
pl_so2_real = twfe_did('so2')$coefficients['did',"Estimate"]
pl_co_real = twfe_did('co')$coefficients['did',"Estimate"]
pl_pm10_real = twfe_did('pm10')$coefficients['did',"Estimate"]
pl_o3_real = twfe_did('o3')$coefficients['did',"Estimate"]


p1 = ggplot(pl_no2, aes(x = coef_did)) +
  geom_density(linewidth = 1) + 
  geom_vline(xintercept = pl_no2_real, col = 'red') +
  labs(
    x = "Estimated coefficient",
    y = "Density",
    title = "Placebo test for NO2"
  ) +
  theme_bw()


p2 = ggplot(pl_so2, aes(x = coef_did)) +
  geom_density(linewidth = 1) + 
  geom_vline(xintercept = pl_so2_real, col = 'red') +
  labs(
    x = "Estimated coefficient",
    y = "Density",
    title = "Placebo test for SO2"
  ) +
  theme_bw()



p3 = ggplot(pl_co, aes(x = coef_did)) +
  geom_density(linewidth = 1) + 
  geom_vline(xintercept = pl_co_real, col = 'red') +
  labs(
    x = "Estimated coefficient",
    y = "Density",
    title = "Placebo test for CO"
  ) +
  theme_bw()



p4 = ggplot(pl_o3, aes(x = coef_did)) +
  geom_density(linewidth = 1) + 
  geom_vline(xintercept = pl_o3_real, col = 'red') +
  labs(
    x = "Estimated coefficient",
    y = "Density",
    title = "Placebo test for O3"
  ) +
  theme_bw()


p5 = ggplot(pl_pm10, aes(x = coef_did)) +
  geom_density(linewidth = 1) + 
  geom_vline(xintercept = pl_pm10_real, col = 'red') +
  labs(
    x = "Estimated coefficient",
    y = "Density",
    title = "Placebo test for PM10"
  ) +
  theme_bw()

gridExtra::grid.arrange(p1,p2,p3,p4,p5, nrow = 2)





