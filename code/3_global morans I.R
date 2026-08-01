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

############################################
#    Global Moran's I
############################################
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

#### Moran's I
moran_by_year = function(data, var, year, listw, zero.policy = TRUE, alternative = "greater") {
  
  var = deparse(substitute(var))
  
  res = lapply(year, function(y) {
    mt = moran.test(
      data[data$year == y, var][[1]],
      listw = listw,
      zero.policy = zero.policy,
      alternative = alternative
    )
    
    data.frame(
      year    = y,
      name    = var,
      Moran_I = round(mt$estimate[["Moran I statistic"]], 3),
      E_I     = round(mt$estimate[["Expectation"]], 3),
      Var_I   = round(mt$estimate[["Variance"]], 3),
      Z_I     = round(as.numeric(mt$statistic), 3),
      pval    = round(mt$p.value, 3)
    )
  })
  
  bind_rows(res)
}

moran_by_year(data = final, var = co, year = c(2014:2024),
              listw = listw_k5, zero.policy = TRUE, alternative = "greater")

moran_by_year(data = final, var = no2, year = c(2014:2024),
              listw = listw_k5, zero.policy = TRUE, alternative = "greater")

moran_by_year(data = final, var = so2, year = c(2014:2024),
              listw = listw_k5, zero.policy = TRUE, alternative = "greater")

moran_by_year(data = final, var = o3, year= c(2014:2024),
              listw = listw_k5, zero.policy = TRUE, alternative = "greater")

moran_by_year(data = final, var = pm10, year = c(2014:2024),
              listw = listw_k5, zero.policy = TRUE, alternative = "greater")


moran_table = bind_rows(
  moran_by_year(final, no2,   year = c(2014:2024),listw_k5),
  moran_by_year(final, co,    year = c(2014:2024),listw_k5),
  moran_by_year(final, so2,   year = c(2014:2024), listw_k5),
  moran_by_year(final, o3,    year = c(2014:2024), listw_k5),
  moran_by_year(final, pm10,  year = c(2014:2024), listw_k5)
) %>%
  mutate(
    Moran_I = paste0(
      sprintf("%.3f", Moran_I),
      case_when(
        pval < 0.01 ~ "***",
        pval < 0.05 ~ "**",
        pval < 0.10 ~ "*",
        TRUE ~ ""
      )
    )
  ) %>%
  dplyr::select(year, name, Moran_I) %>%
  pivot_wider(
    names_from = name,
    values_from = Moran_I
  ) %>%
  rename(year = year)

moran_table
