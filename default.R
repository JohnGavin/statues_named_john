#!/usr/bin/env Rscript
# Generate default.nix using rix for reproducible R environment
# This should be run once to set up the project's nix environment

library(rix)
# system_pkgs <- c(
#   "locale", "direnv", "jq", 
#   "nodejs", 
#   # "tinytex", 
#   "curlMinimal", 
#   "nano", 
#   # https://jebyrnes.github.io/bayesian_sem/bayesian_sem.html
#   # "stanc", 
#   "cmdstan", 
#   # "python312", # "python312Packages\\.statsmodels",
#   # "glibcLocales",
#   # "nix",
#   # https://positron.posit.co/rstudio-rproj-file.html#use-an-application-launcher
#     # https://www.andrewheiss.com/blog/2025/07/22/positron-open-with-finder/
#     # "raycast", 
#   # "podman", 
#   "duckdb", "tree", 
#   "awscli2",
#   "bc", # calculator
#   "htop", "btop", 
#   "typst", 
#   "copilot-cli", 
#   "gemini-cli",
#   "claude-code", # https://blog.stephenturner.us/p/positron-assistant-copilot-chat-agent
#   "ollama",
#   "cacert", # CA certs / trusted TLS/SSL root certs
#   # echo $SSL_CERT_FILE ; echo $NIX_SSL_CERT_FILE
#   # "radianWrapper",
#   "gh", "git", # "node", "npm", 
#   "gnupg", 
#   "toybox", # coreutils-full # else 'which' etc is missing with nix-shell --pure
#   # translation tools - gettext
#   #   else brms 'intl' error libintl-dev
#   "gettext",
#   "quarto", "pandoc", # ?
#   # 'pdflatex' is needed to make vignettes but is missing on your system.
#   "texliveBasic",
#   "less", # pager needs less
#   # , "gmp", "mpfr"
#     # --- Julia ---
#   "unzip",      # Solves "unzip: command not found"
#   "libiconv",   # Often a good idea on macOS for various tools, helps with character encoding.
#   "gcc", "libgcc", 
#   # For the "xcode-select" issue:
#   # There isn't a Nix package that *is* `xcode-select`.
#   # We need to provide the underlying tools. `stdenv` (which `rix` should use for Julia)
#   # already does this for the compilation of Julia itself.
#   # If a script *still* calls `xcode-select`, it's a script issue.
#   #
#   # `pkgs.darwin.XCRun` provides the `xcrun` command, which is often used by scripts
#   # that also interact with Xcode tools. Adding it might help if the script
#   # falls back to `xcrun` or uses it after an `xcode-select` check.
#   # "darwin.XCRun"
#   #
#   # `pkgs.cctools` (contains linker, assembler) and `pkgs.clang` (the compiler) are
#   # fundamental. On macOS, these are typically part of `stdenv` (`pkgs.clangStdenv`).
#   # `rix` should ensure Julia is built with this. Explicitly adding them to `system_pkgs`
#   # might make them available in the top-level shell if `rix`'s Julia setup script
#   # (not Julia's Nix build, but a script `rix` runs) needs them directly in the PATH
#   # and isn't inheriting them properly.
#   # However, start without these two explicitly, as `darwin.XCRun` and `stdenv` should cover most cases.
#   # "cctools",
#   "clang"
#   # --- END Julia ---

#   ) |>
#   unique() |>
#   sort()

# Generate default.nix for the project
#(latest <- available_dates() |> sort() |> tail(2) |> head(1))
#print(latest)

rix(
  date = "2025-11-24",
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
    "rcmdcheck" # New dependency for ci_verification.R
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