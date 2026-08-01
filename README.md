# LEZ-spatial-did-korea

# LEZ Spatial DID Korea

Replication code for the study:

**Regional Spillover Effects of Low Emission Zones on Air Quality: Evidence from South Korea**

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
├── data/
│   ├── raw/            # Original data (not included)
│   └── processed/      # Processed analysis datasets
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
│   ├── figures/
│   └── models/
│
├── README.md
└── LICENSE
```

## Software Requirements

* R (version 4.3 or later recommended)

Main R packages include:

* sf
* spdep
* splm
* did
* fixest
* dplyr
* tidyr
* ggplot2
* MASS
* broom
* modelsummary

## Replication

Run the scripts in the following order:

1. `01_prepare_data.R`
2. `02_descriptive_analysis.R`
3. `03_staggered_DID.R`
4. `04_spatial_DID.R`
5. `05_robustness_checks.R`
6. `06_figures_tables.R`

The scripts reproduce the main estimation results, robustness analyses, supplementary analyses, and manuscript figures.

## Reproducibility

Random-number generation used for simulation-based inference is initialized with fixed seeds to ensure reproducibility.

Minor numerical differences may occur across operating systems or package versions.

## Citation

If you use this code, please cite the corresponding article:

> **Authors.** *Regional Spillover Effects of Low Emission Zones on Air Quality: Evidence from South Korea.* (Manuscript under review.)

## License

This repository is released under the MIT License unless otherwise noted.

## Contact

For questions regarding the replication materials, please open a GitHub Issue or contact the corresponding author.
