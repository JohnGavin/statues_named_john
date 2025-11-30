#!/usr/bin/env Rscript
# Generate default.nix using rix for reproducible R environment
# This should be run once to set up the project's nix environment

library(rix)

# Generate default.nix for the project
rix(
  r_ver = "71f14cf4ab060eb861de5b09f83540fee466e1d2",
  r_pkgs = c(
    "devtools",
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
    "httr2",
    "gert",
    "gh",
    "usethis",
    "R.utils",
    "rprojroot",
    "quarto"
  ),
  system_pkgs = c("pandoc", "qpdf", "libomp"),
  git_pkgs = NULL,
  ide = "none",
  project_path = ".",
  overwrite = TRUE,
  print = TRUE
)

message("default.nix generated successfully!")
message("Now run: nix-shell --run R")