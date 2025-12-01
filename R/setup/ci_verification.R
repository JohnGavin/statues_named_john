# R/setup/ci_verification.R
# This script performs R-level verification steps for CI.
# It is meant to be run *within* a Nix shell where necessary packages are available.

# 0. Load necessary R packages
library(roxygen2)
library(testthat)
library(targets)
library(methods) # For generic functions like `check()`
library(pkgload) # For load_all()
library(rcmdcheck) # For rcmdcheck()

# Helper function to run R code and check for errors
run_r_code <- function(expr, error_message = "R code failed.") {
  cat(paste("Running:", deparse(substitute(expr)), "\n"))
  result <- try(eval(substitute(expr)), silent = TRUE)
  if (inherits(result, "try-error")) {
    cat(result) # Print the error message
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
cat("\n--- Loading local package (pkgload::load_all()) ---
")
run_r_code(pkgload::load_all(), "❌ pkgload::load_all() failed.")

# 2. Generate documentation
cat("\n--- 2. Generating documentation (roxygen2::roxygenise()) ---
")
run_r_code(roxygen2::roxygenise(), "❌ roxygen2::roxygenise() failed.")

# 3. Run unit tests
cat("\n--- 3. Running unit tests (testthat::test_local()) ---
")
run_r_code(testthat::test_local(stop_on_failure = TRUE), "❌ testthat::test_local() failed.")

# 4. Run R CMD check
cat("\n--- 4. Running R CMD check (rcmdcheck::rcmdcheck()) ---
")
run_r_code(rcmdcheck::rcmdcheck(error_on = "note", args = c("--no-build-vignettes", "--no-manual")), "❌ rcmdcheck::rcmdcheck() found errors, warnings, or notes.")

# 5. Build targets pipeline locally (optional, can be done in a separate CI job if needed)
# For now, we'll just check if it can be loaded.
cat("\n--- 5. Verifying targets pipeline can be built (targets::tar_make(callr_function = NULL)) ---
")
run_r_code(targets::tar_make(callr_function = NULL), "❌ targets::tar_make() failed.")

cat("✅ All R-level CI verification steps passed.
")
