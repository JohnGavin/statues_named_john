# Template for setting up a new Nix/Rix R environment
# Copy this file to your project root and customize as needed

library(rix)

# =============================================================================
# 1. DEFINE YOUR R PACKAGES
# =============================================================================

r_pkgs <- c(
  # Core tidyverse
  "dplyr",
  "ggplot2",
  "tidyr",
  "purrr",
  "readr",
  "stringr",

  # Development tools
  "devtools",
  "usethis",
  "roxygen2",
  "testthat",
  "covr",

  # Git/GitHub integration
  "gert",
  "gh",

  # Documentation
  "pkgdown",
  "knitr",
  "rmarkdown",
  "quarto",

  # Pipeline/workflow
  "targets",
  "tarchetypes",

  # Logging
  "logger",

  # Add your project-specific packages here:
  # "your_package_name"
) |>
  unique() |>
  sort()

# =============================================================================
# 2. DEFINE SYSTEM PACKAGES
# =============================================================================

system_pkgs <- c(
  "git",
  "gh",          # GitHub CLI
  "quarto",
  "pandoc",
  "tree",

  # Add other system tools you need:
  # "curl", "jq", etc.
) |>
  unique() |>
  sort()

# =============================================================================
# 3. DEFINE GIT PACKAGES (if needed)
# =============================================================================

# Example:
# git_pkgs <- list(
#   list(
#     package_name = "yourpackage",
#     repo_url = "https://github.com/user/repo",
#     commit = "abc123"
#   )
# )

git_pkgs <- NULL  # Set to NULL if not using git packages

# =============================================================================
# 4. GET LATEST NIXPKGS DATE (optional)
# =============================================================================

# Check available dates
# available_dates() |> tail(10)

# Or use a specific date for reproducibility
nixpkgs_date <- "2025-11-01"  # Use format YYYY-MM-DD

# =============================================================================
# 5. GENERATE default.nix
# =============================================================================

rix(
  date = nixpkgs_date,
  r_pkgs = r_pkgs,
  system_pkgs = system_pkgs,
  git_pkgs = git_pkgs,
  project_path = ".",
  overwrite = TRUE,
  ide = "none"  # Options: "none", "rstudio", "positron"
)

# =============================================================================
# 6. VERIFY
# =============================================================================

cli::cli_alert_success("Generated default.nix")
cli::cli_alert_info("Next steps:")
cli::cli_bullets(c(
  "Review the generated default.nix",
  "Enter nix shell: nix-shell default.nix",
  "Verify R version: R --version",
  "Check packages: Rscript -e 'library(dplyr)'",
  "Start development!"
))
