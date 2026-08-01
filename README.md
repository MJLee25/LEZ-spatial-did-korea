# LEZ Spatial DID Korea

Replication code for the study:

**Pollutant-Specific and Spatial Spillover Effects of Low Emission Zones in South Korea: A Staggered Spatial DID Analysis**

## Overview

This repository contains the R code used to reproduce the empirical analyses presented in the manuscript. The study evaluates the effects of Low Emission Zone (LEZ) policies on ambient air quality in South Korea using staggered Difference-in-Differences (DID) and Spatial Difference-in-Differences (Spatial DID) models.

The repository includes scripts for data preparation, descriptive analyses, econometric estimation, robustness checks, and figure generation.

## Data

The empirical analysis combines multiple publicly available datasets, including:

* Air pollution monitoring data
* Meteorological variables
* Urban and transportation characteristics
* Administrative boundary data
* LEZ implementation information

Due to licensing and data-sharing restrictions, some raw datasets are **not** included in this repository. Users should obtain the original data from the corresponding public agencies before running the replication code.

## Repository Structure

```text

├──data/
│   └── raw/
│       └── README.md          # Original data and data source
│   └── processed/             # Spatial weight matrices
│         ├── listw_k3.rds
│         ├── listw_k5.rds
│         ├── listw_k7.rds
│         ├── listw_50km.rds
│         └── listw_70km.rds
│ 
├── code/
│   ├── 01_prepare_data.R
│   ├── 02_descriptive_analysis.R
│   ├── 03_staggered_DID.R
│   ├── 04_spatial_DID.R
│   ├── 05_robustness_checks.R
│   ├── 06_figures_tables.R
│   └── functions.R
│
├── output/
│   ├── tables/
│   └── figures/
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

1. `01_prepare_data.R`
2. `02_descriptive_analysis.R`
3. `03_staggered_DID.R`
4. `04_spatial_DID.R`
5. `05_robustness_checks.R`
6. `06_figures_tables.R`

The scripts reproduce the main estimation results, robustness analyses, supplementary analyses, and manuscript figures.

## Citation

If you use this code, please cite the corresponding article:

> **Minju Lee, Mijeong Kim,** *Pollutant-Specific and Spatial Spillover Effects of Low Emission Zones in South Korea: A Staggered Spatial DID Analysis.* (Manuscript under review.)

## License

This repository is released under the MIT License unless otherwise noted.

## Contact

For questions regarding the replication materials, please open a GitHub Issue or contact the corresponding author.
