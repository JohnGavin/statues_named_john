#!/usr/bin/env Rscript
# Generate default.nix using rix for reproducible R environment
# This should be run once to set up the project's nix environment

library(rix)
# Generate default.nix for the project
#(latest <- available_dates() |> sort() |> tail(2) |> head(1))
#print(latest)

rix(
  date = "2025-11-24",  # Reverted from 2025-11-10 - older snapshot broke R-CMD-check
  r_pkgs = c(
    "roxygen2",
    "testthat",
    "knitr",
    "rmarkdown",
    "rvest",
    "httr",
    "dplyr",
    "purrr",
    "stringr",
    "tibble",
    "ggplot2",
    "lubridate",
    "tidyr",
    "scales",
    "covr",
    "pkgdown",
    "targets",
    "tarchetypes",
    "sf",
    "arrow",
    "WikidataQueryServiceR",
    "osmdata",
    "leaflet",
    "jsonlite",
    "readr", # Added from DESCRIPTION
    "httr2",
    "gert",
    "gh",
    "usethis",
    "R.utils",
    "rprojroot",
    "quarto",
    "pkgload", # New dependency for ci_verification.R
    "rcmdcheck", # New dependency for ci_verification.R
    "visNetwork",
    "gender"
  ),
  system_pkgs = NULL,
  git_pkgs = NULL,
  ide = "none",
  project_path = ".",
  overwrite = TRUE,
  print = TRUE
)

message("default.nix generated successfully!")
#print(latest)
message("Now run: nix-shell --run R")