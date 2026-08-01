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


#################################################
#  Lagrange Multiplier Test
################################################
#### Spatial Weight Matrice
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

make_knn_listw = function(k) {
  knn = knearneigh(coords, k = k)
  nb = knn2nb(knn)
  nb2listw(nb, style = "W")
}

listw_k5 = make_knn_listw(5)  #KNN=5

urban = 'pop_density + industrial_area + commercial_area + green_area_per_capita'
car = 'daily_km + road_paving_rate + cars_per_capita'
climate = 'avg_rain + annual_humid + summer_temp + winter_temp + summer_sun + stagnation_days'


lm_test_error = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did", '+', urban, '+', car, '+', climate)
  )
  
  slmtest(fml, data = dat, listw = listw_k5, test = 'lme',
          index = c('id'), model = 'within', effect = 'twoways')
}


lm_test_lag = function(y){
  dat = final %>% st_drop_geometry()
  
  fml = as.formula(
    paste0(y, " ~ did", '+', urban, '+', car, '+', climate)
  )
  
  slmtest(fml, data = dat, listw = listw_k5, test = 'lml',
          index = c('id'), model = 'within', effect = 'twoways')
}


## Result
data.frame(col = c('no2', 'so2', 'co','o3','pm10'),
           
           sar_stat = round(c(lm_test_lag('no2')$statistic, 
                              lm_test_lag('so2')$statistic, 
                              lm_test_lag('co')$statistic, 
                              lm_test_lag('o3')$statistic, 
                              lm_test_lag('pm10')$statistic), 3),
           
           sar_pval = round(c(lm_test_lag('no2')$p.value, 
                              lm_test_lag('so2')$p.value, 
                              lm_test_lag('co')$p.value, 
                              lm_test_lag('o3')$p.value, 
                              lm_test_lag('pm10')$p.value), 3),
           
           sem_stat = round(c(lm_test_error('no2')$statistic, 
                              lm_test_error('so2')$statistic, 
                              lm_test_error('co')$statistic, 
                              lm_test_error('o3')$statistic, 
                              lm_test_error('pm10')$statistic),3),
           
           sem_pval = round(c(lm_test_error('no2')$p.value, 
                              lm_test_error('so2')$p.value, 
                              lm_test_error('co')$p.value, 
                              lm_test_error('o3')$p.value, 
                              lm_test_error('pm10')$p.value),3))



