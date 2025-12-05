# package.nix
{ pkgs ? import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-11-24.tar.gz") {} }: # Using the same hash as default.nix

pkgs.rPackages.buildRPackage {
  name = "statuesnamedjohn";
  src = ./.; # Source is current directory

  # Runtime dependencies (from DESCRIPTION Imports)
  propagatedBuildInputs = with pkgs.rPackages; [
    rvest
    httr
    dplyr
    purrr
    stringr
    tibble
    sf
    R_utils # R.utils
    WikidataQueryServiceR
    osmdata
    leaflet
    jsonlite
    httr2
    gert
    gh
    usethis
    gender # Added for conditional use in analyze_statues.R
    rprojroot # if used in runtime (Suggests)
    quarto # if used in runtime (Suggests)
  ];

  # Build dependencies (from DESCRIPTION Suggests, typically)
  nativeBuildInputs = with pkgs.rPackages; [
    testthat # For devtools::test()
    knitr # For building vignettes
    rmarkdown # For building vignettes
    ggplot2 # For plotting in vignettes/examples
    lubridate # Used in examples/analysis
    tidyr # Used in examples/analysis
    scales # Used in examples/analysis
    targets # For pipeline
    tarchetypes # For pipeline
    arrow # For caching
    visNetwork # For pipeline visualization
    # quarto # For rendering .qmd (also in propagated)
  ];
}
