# LEZ Spatial DID Korea

Replication code for the study:

**Pollutant-Specific and Spatial Air-Quality Responses to Low Emission Zones in South Korea: A Spatial Panel Analysis of Staggered Adoption**

## Overview

This repository contains the R code used to reproduce the empirical analyses presented in the manuscript. The study evaluates the effects of Low Emission Zone (LEZ) policies on ambient air quality in South Korea using staggered Difference-in-Differences (DID) and Spatial Difference-in-Differences (Spatial DID) models.

The repository includes scripts for data preparation, descriptive analyses, econometric estimation, robustness checks, and figure generation.

## Data

The empirical analysis combines multiple publicly available datasets at the si-gun-gu level for 2014–2024. The main data sources are:

- **Air pollution data:** Air Korea monitoring data for CO, SO2, NO2, O3, and PM10.
- **Meteorological data:** Korea Meteorological Administration (KMA) Open MET Data Portal, including precipitation, relative humidity, summer and winter temperature, summer sunshine duration, and atmospheric stagnation days.
- **Urban and demographic data:** Korea Land and Geospatial Informatix Corporation (LX) and the Korean Statistical Information Service (KOSIS), including industrial, commercial, and green-area variables and resident registered population. Population density was calculated as resident registered population divided by the si-gun-gu land area (km²) derived from the administrative boundary shapefile.
- **Transportation data:** Ministry of Land, Infrastructure and Transport (MOLIT) for road paving rates and vehicle registrations, and the Korea Transportation Safety Authority (KTSA) for average daily vehicle distance traveled.

Station-level air-pollution and meteorological observations were spatially interpolated to si-gun-gu-level values using inverse-distance weighting (IDW). The final analysis sample consists of 247 si-gun-gu units observed annually from 2014 to 2024, excluding Ongjin-gun and Ulleung-gun.

Due to licensing and data-sharing restrictions, raw/preprocessed datasets are **not** included in this repository. Users should obtain the original data from the corresponding public agencies before running the replication code.

## Repository Structure

```text
├── code/
│   ├── 1_parallel_trend.R
│   ├── 2_global morans I.R
│   ├── 3_LM Test.R
│   ├── 4_TWFE-DID.R
│   ├── 5_Spatial Staggered DID.R
│   └── 6_Placebo Test.R
│
├── README.md
└── LICENSE
```

## Software Requirements

* R (version 4.3 or later recommended)

Main R packages include:

* readxl
* sf
* dplyr
* spdep
* splm
* plm
* did
* ggplot2
* MASS
* tidyr
* purrr

## Replication

Run the scripts in the following order:

1. `1_parallel_trend.R`
2. `2_global morans I.R`
3. `3_LM Test.R`
4. `4_TWFE-DID.R`
5. `5_Spatial Staggered DID.R`
6. `6_Placebo Test.R`

The scripts reproduce the main estimation results, robustness analyses, supplementary analyses, and manuscript figures.

`5_Spatial Staggered DID.R` contains all the robustness analysis(COVID-19, Rainfall sensitivity, Alternative Matrix), however, requires the user to run additional code lines states as annotations in the R code.

* Rainfall Sensitivity(Table 6): run line 315-354
* COVID-19 Sensitivity(Table S3): run line 23 (exclude 2020-2022 in dataset)
* Alternative Matrix(Table S4): run line 105-106 (exclude `avg_rain` in dataset)

## Citation

If you use this code, please cite the corresponding article:

> **Minju Lee, Mijeong Kim,** *Pollutant-Specific and Spatial Air-Quality Responses to Low Emission Zones in South Korea: A Spatial Panel Analysis of Staggered Adoption* (Manuscript under review.)

## License

This repository is released under the MIT License unless otherwise noted.

## Contact

For questions regarding the replication materials, please open a GitHub Issue or contact the corresponding author.
