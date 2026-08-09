# LEZ Spatial DID Korea

Replication code for the study:

**Pollutant-Specific and Spatial Air-Quality Responses to Low Emission Zones in South Korea: A Spatial Panel Analysis of Staggered Adoption**

## Overview

This repository contains the R code used for the main empirical analyses presented in the manuscript. The study examines pollutant-specific and spatial air-quality responses associated with South Korea's phased Low Emission Zone (LEZ) expansion over 2014–2024.

The analysis combines group-time event-study diagnostics for staggered LEZ adoption with non-spatial two-way fixed-effects (TWFE) models and spatial panel models. The repository also includes code for spatial autocorrelation diagnostics, robustness analyses using alternative spatial-weight matrices, and placebo tests.


### Data Sources

- **Air pollution**
  - **Source:** Air Korea
  - **Variables:** CO, SO2, NO2, O3, and PM10 concentrations
  - **Processing:** Station-level observations were spatially interpolated to si-gun-gu-level values using inverse-distance weighting (IDW; power = 2).

- **Meteorology**
  - **Source:** Korea Meteorological Administration (KMA) Automated Synoptic Observing System (ASOS) 
  - **Variables:** Annual average daily precipitation(`avg_rain`), annual average relative humidity(`annual_humid`), summer(june-august) average temperature(`summer_temp`), winter(december-february) average temperature(`winter_temp`), summer total sunshine duration(`summer_sun`), and stagnation days(`stagnation_days`).
  - **Construction:** Annual average daily precipitation was calculated as annual total precipitation divided by 365 days. Atmospheric stagnation days were defined as days with mean wind speed ≤ 2 m/s.
  - **Processing:** Station-level observations were spatially interpolated to si-gun-gu-level values using IDW (power = 2).

- **Urban Structure**
  - **Sources:** Korea Land and Geospatial Informatix Corporation (LX) and Korean Statistical Information Service (KOSIS)
  - **Variables:** Population density(`pop_density`), industrial area(`industrial_area`), commercial area(`commercial_area`), and green area(`green_area`).
  - **Construction:** Population density was calculated as resident registered population divided by the land area (km²) of each si-gun-gu derived from the administrative boundary data. Green area was expressed on a per-capita basis.

- **Transportation**
  - **Sources:** Ministry of Land, Infrastructure and Transport (MOLIT) and Korea Transportation Safety Authority (KTSA)
  - **Variables:** Road paving rate(`road_paving_rate`), registered vehicles(`cars_per_capita`), and average daily vehicle distance traveled(`daily_km`).
  - **Construction:** Cars per capita was calculated as registered vehicles divided by resident registered population. Average daily vehicle distance traveled is expressed in km per vehicle per day.

The final analysis sample consists of 247 si-gun-gu units observed annually from 2014 to 2024, excluding Ongjin-gun and Ulleung-gun.

The analysis scripts require two input files:

- `dat.xlsx`: the processed si-gun-gu-year panel containing outcomes, treatment variables, and covariates.
- `korea.geojson`: the si-gun-gu administrative boundary file used for spatial operations and construction of spatial weight matrices.

Due to licensing and data-sharing restrictions, these input datasets are **not** included in this repository. Users should obtain the original data from the corresponding public agencies before running the replication code.

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
