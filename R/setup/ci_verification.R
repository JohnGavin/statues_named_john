# R/setup/ci_verification.R
# This script performs R-level verification steps for CI.
# It is meant to be run *within* a Nix shell where necessary packages are available.

# 0. Load necessary R packages
library(devtools)
library(roxygen2)
library(testthat)
library(targets)
library(methods) # For generic functions like `check()`

# Helper function to run R code and check for errors
run_r_code <- function(expr, error_message = "R code failed.") {
  cat(paste("Running:", deparse(substitute(expr)), "\n"))
  result <- try(eval(substitute(expr)), silent = TRUE)
  if (inherits(result, "try-error")) {
    stop(error_message, call. = FALSE)
  }
}

# 1. Verify all DESCRIPTION dependencies are loadable
cat("--- 1. Verifying DESCRIPTION dependencies are loadable in Nix shell ---
")
d <- read.dcf("DESCRIPTION")
pkgs_raw <- unique(trimws(unlist(strsplit(c(
  if("Imports" %in% colnames(d)) d[,"Imports"] else NULL, 
  if("Suggests" %in% colnames(d)) d[,"Suggests"] else NULL, 
  if("Depends" %in% colnames(d)) d[,"Depends"] else NULL
), ","))))
  pkgs <- gsub("\\s*\\(.*\\)", "", pkgs_raw); 
pkgs <- pkgs[pkgs != "R"]

missing <- c();
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    missing <- c(missing, p)
  }
}

if(length(missing) > 0) { 
  cat("❌ Missing packages (not available/loadable in Nix shell):", paste(missing, collapse = ", "), "\n"); 
  quit(status = 1) 
} else { 
  cat("✅ All DESCRIPTION dependencies are available in the Nix shell.
") 
}

# Load the local package for subsequent checks
cat("\n--- Loading local package (devtools::load_all()) ---
")
run_r_code(devtools::load_all(), "❌ devtools::load_all() failed.")

# 2. Generate documentation
cat("\n--- 2. Generating documentation (roxygen2::roxygenise()) ---
")
run_r_code(roxygen2::roxygenise(), "❌ roxygen2::roxygenise() failed.")

# 3. Run unit tests
cat("\n--- 3. Running unit tests (devtools::test()) ---
")
run_r_code(devtools::test(), "❌ devtools::test() failed.")

# 4. Run R CMD check
cat("\n--- 4. Running R CMD check (devtools::check()) ---
")
run_r_code(devtools::check(error_on = "note", build_args = c("--no-build-vignettes", "--no-manual")), "❌ devtools::check() found errors, warnings, or notes.")

# 5. Build targets pipeline locally (optional, can be done in a separate CI job if needed)
# For now, we'll just check if it can be loaded.
cat("\n--- 5. Verifying targets pipeline can be built (targets::tar_make(callr_function = NULL)) ---
")
run_r_code(targets::tar_make(callr_function = NULL), "❌ targets::tar_make() failed.")

cat("✅ All R-level CI verification steps passed.
")
