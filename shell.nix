{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    R
    pandoc
    qpdf
    rPackages.rix
    rPackages.devtools
    rPackages.roxygen2
    rPackages.testthat
    rPackages.knitr
    rPackages.rmarkdown
    rPackages.rvest
    rPackages.httr
    rPackages.dplyr
    rPackages.purrr
    rPackages.stringr
    rPackages.tibble
    rPackages.ggplot2
    rPackages.lubridate
    rPackages.tidyr
    rPackages.scales
    rPackages.covr
    rPackages.pkgdown
  ];
}
