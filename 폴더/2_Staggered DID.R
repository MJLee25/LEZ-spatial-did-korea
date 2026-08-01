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

korea = geojsonsf::geojson_sf("korea.geojson")   #shp file for korea si-gun-gu units
final = merge(dat, korea, all.x = TRUE, by = c("province", "sigungu")) %>%
  st_as_sf() %>% 
  arrange(id, year)


################################################
#      Staggered DID
################################################
urban = 'pop_density + industrial_area + commercial_area + green_area_per_capita'
car = 'daily_km + road_paving_rate + cars_per_capita'
climate = 'avg_rain + annual_humid + summer_temp + winter_temp + summer_sun + stagnation_days'

##### 0. FE only
twfe_did0 = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did")
  )
  
  model = plm(fml, data = dat, effect = "twoways", model = "within", index = c('id','year'))  
  summary(model)
}

twfe_did0('no2')   
twfe_did0('co') 
twfe_did0('so2') 
twfe_did0('o3')  
twfe_did0('pm10') 


##### 1. urban controls
twfe_did1 = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did", "+", urban)
  )
  
  model = plm(fml, data = dat, effect = "twoways", model = "within", index = c('id','year'))  
  summary(model)
}

twfe_did1('no2') 
twfe_did1('co') 
twfe_did1('so2')   
twfe_did1('o3')    
twfe_did1('pm10') 


##### 2. Urban + transport controls
twfe_did2 = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did", "+", urban,  '+', car)
  )
  
  model = plm(fml, data = dat, effect = "twoways", model = "within", index = c('id','year'))  
  summary(model)
}

twfe_did2('no2')   
twfe_did2('co')   
twfe_did2('so2')   
twfe_did2('o3')    
twfe_did2('pm10') 


##### 3. Urban + transport + meteorological controls 
twfe_did3 = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did", '+', urban, '+', car, '+', climate)
  )
  
  model = plm(fml, data = dat, effect = "twoways", model = "within", index = c('id','year'))  
  summary(model)
}

twfe_did3('no2')   
twfe_did3('co')   
twfe_did3('so2')   
twfe_did3('o3')    
twfe_did3('pm10') 



####################################################
#   Table S2: Estimate and extract DID coefficients
###################################################
extract_did = function(model_summary) {
  
  coef_table = model_summary$coefficients
  
  estimate = coef_table["did", "Estimate"]
  se       = coef_table["did", "Std. Error"]
  p_value  = coef_table["did", "Pr(>|t|)"]
  
  star = case_when(
    p_value < 0.01 ~ "***",
    p_value < 0.05 ~ "**",
    p_value < 0.10 ~ "*",
    TRUE ~ ""
  )
  
  paste0(
    sprintf("%.3f", estimate),
    star,
    "\n(",
    sprintf("%.3f", se),
    ")"
  )
}


# FE only
m0_no2   = twfe_did0("no2")
m0_co   = twfe_did0("co")
m0_so2   = twfe_did0("so2")
m0_o3    = twfe_did0("o3")
m0_pm10 = twfe_did0("pm10")

# + Urban
m1_no2   = twfe_did1("no2")
m1_co   = twfe_did1("co")
m1_so2   = twfe_did1("so2")
m1_o3    = twfe_did1("o3")
m1_pm10 = twfe_did1("pm10")

# + Urban + Transport
m2_no2   = twfe_did2("no2")
m2_co   = twfe_did2("co")
m2_so2   = twfe_did2("so2")
m2_o3    = twfe_did2("o3")
m2_pm10 = twfe_did2("pm10")

# + Urban + Transport + Meteorological
m3_no2   = twfe_did3("no2")
m3_co   = twfe_did3("co")
m3_so2   = twfe_did3("so2")
m3_o3    = twfe_did3("o3")
m3_pm10 = twfe_did3("pm10")


result_table = tibble(
  Specification = c(
    "FE only",
    "+ Urban",
    "+ Urban + Transport",
    "+ Urban + Transport + Meteorological"
  ),
  
  NO2 = c(
    extract_did(m0_no2),
    extract_did(m1_no2),
    extract_did(m2_no2),
    extract_did(m3_no2)
  ),
  
  CO = c(
    extract_did(m0_co),
    extract_did(m1_co),
    extract_did(m2_co),
    extract_did(m3_co)
  ),
  
  SO2 = c(
    extract_did(m0_so2),
    extract_did(m1_so2),
    extract_did(m2_so2),
    extract_did(m3_so2)
  ),
  
  O3 = c(
    extract_did(m0_o3),
    extract_did(m1_o3),
    extract_did(m2_o3),
    extract_did(m3_o3)
  ),
  
  PM10 = c(
    extract_did(m0_pm10),
    extract_did(m1_pm10),
    extract_did(m2_pm10),
    extract_did(m3_pm10)
  )
)

result_table
