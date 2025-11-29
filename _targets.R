#!/usr/bin/env Rscript
# _targets.R - targets pipeline for vignette data preprocessing
# Run with: tar_make() in R

library(targets)
library(tarchetypes)

# Load package from source (for development)
if (file.exists("DESCRIPTION")) {
  suppressMessages(devtools::load_all())
}

# Set options
tar_option_set(
  packages = c(
    "londonremembers", 
    "dplyr",
    "tidyr",
    "stringr",
    "ggplot2",
    "lubridate",
    "arrow" 
  ),
  format = "parquet" 
)

# Source plans
source("R/tar_plans/memorial_analysis_plan.R")

# Define pipeline
list(
  memorial_analysis_plan
)
