#!/usr/bin/env Rscript
# _targets.R - targets pipeline for vignette data preprocessing
# Run with: tar_make() in R

library(targets)
library(tarchetypes)

# Load package from source (for development)
if (file.exists("DESCRIPTION")) {
  suppressMessages(pkgload::load_all())
}

# Set options
tar_option_set(
  packages = c(
    "statuesnamedjohn",
    "dplyr",
    "tidyr",
    "stringr",
    "ggplot2",
    "lubridate",
    "arrow",
    "quarto",      # For vignette rendering
    "pkgdown",     # For site building
    "sf"           # For spatial data in vignettes
  ),
  format = "parquet"
)

# Source plans
source("R/tar_plans/memorial_analysis_plan.R")
source("R/tar_plans/documentation_plan.R")

# Define pipeline
list(
  memorial_analysis_plan,
  documentation_plan
)
