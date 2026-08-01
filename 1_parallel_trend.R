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

korea = geojsonsf::geojson_sf("korea.geojson")  #shp file for korea si-gun-gu units
final = merge(dat, korea, all.x = TRUE, by = c("province", "sigungu")) %>%
  st_as_sf() %>% 
  arrange(id, year)
final$g = as.numeric(final$g)

#########################################
#    parallel trend
#########################################
urban = 'pop_density + industrial_area + commercial_area + green_area_per_capita'
car = 'daily_km + road_paving_rate + cars_per_capita'
climate = 'avg_rain + annual_humid + summer_temp + winter_temp + summer_sun + stagnation_days'


parallel_bin = function(y){
  
  att_t = did::att_gt(
    yname = y,
    tname = "year",
    idname = "id",
    gname = "g",
    control_group = "notyettreated",
    data = final %>% sf::st_drop_geometry(),
    base_period = "varying",
    est_method = "reg",
    xformla = as.formula(
      paste0("~ ", urban, " + ", car, " + ", climate)
    )
  )
  
  dyn = did::aggte(att_t, type = "dynamic")
  
  out = data.frame(
    event.time = dyn$egt,
    estimate   = dyn$att.egt,
    se         = dyn$se.egt
  )
  
  ## Binned Event Time (l≤−3, l>3)
  out = out %>%
    mutate(
      event_bin = case_when(
        event.time <= -3 ~ "≤ -3",
        event.time == -2 ~ "-2",
        event.time ==  0 ~ "0",
        event.time ==  1 ~ "+1",
        event.time ==  2 ~ "+2",
        event.time >=  3 ~ "≥ +3"
      )
    ) %>%
    filter(!is.na(event_bin)) %>%
    group_by(event_bin) %>%
    summarise(
      estimate = mean(estimate),
      se = sqrt(mean(se^2)),   
      .groups = "drop"
    )
  
  out$event_bin = factor(
    out$event_bin,
    levels = c("≤ -3","-2","0","+1","+2","≥ +3")
  )
  
  out
}

no2_parallel = parallel_bin('no2')
pm10_parallel = parallel_bin('pm10')
co_parallel = parallel_bin('co')
o3_parallel = parallel_bin('o3')
so2_parallel = parallel_bin('so2')

## Check only ≤ −3 and −2 (0 included; pre-trend satisfied).
## NO2
data.frame(event_bin = no2_parallel$event_bin,
           ymin = c(no2_parallel$estimate - 1.96 * no2_parallel$se), 
           ymax = c(no2_parallel$estimate + 1.96 * no2_parallel$se)) 

## PM10
data.frame(event_bin = pm10_parallel$event_bin,
           ymin = c(pm10_parallel$estimate - 1.96 * pm10_parallel$se), 
           ymax = c(pm10_parallel$estimate + 1.96 * pm10_parallel$se)) 

## CO
data.frame(event_bin = co_parallel$event_bin,
           ymin = c(co_parallel$estimate - 1.96 * co_parallel$se), 
           ymax = c(co_parallel$estimate + 1.96 * co_parallel$se)) 

## O3
data.frame(event_bin = o3_parallel$event_bin,
           ymin = c(o3_parallel$estimate - 1.96 * o3_parallel$se), 
           ymax = c(o3_parallel$estimate + 1.96 * o3_parallel$se)) 

## SO2
data.frame(event_bin = so2_parallel$event_bin,
           ymin = c(so2_parallel$estimate - 1.96 * so2_parallel$se), 
           ymax = c(so2_parallel$estimate + 1.96 * so2_parallel$se)) 


#########################################
#   Visualization (parallel trend)
#########################################
plot_parallel_bin = function(y, ttl){
  
  dd = parallel_bin(y)
  
  ggplot(dd, aes(x = event_bin, y = estimate)) +
    geom_point(size = 1, color = "blue") +
    geom_errorbar(
      aes(
        ymin = estimate - 1.96 * se,
        ymax = estimate + 1.96 * se
      ),
      width = 0.15
    ) +
    geom_hline(yintercept = 0, linetype = 2) + xlab("") +
    theme_bw() +
    ggtitle(ttl)
}

b1 = plot_parallel_bin("no2", "Parallel Trend Test for NO2")
b2 = plot_parallel_bin("pm10", "Parallel Trend Test for PM10")
b3 = plot_parallel_bin("so2", "Parallel Trend Test for SO2")
b4 = plot_parallel_bin("co", "Parallel Trend Test for CO")
b5 = plot_parallel_bin("o3", "Parallel Trend Test for O3")

gridExtra::grid.arrange(
  grobs = list(b1, b2, b3, b4, b5),
  layout_matrix = rbind(
    c(1, 1, 2, 2),
    c(3, 3, 4, 4),
    c(NA, 5, 5, NA)
  )
)





