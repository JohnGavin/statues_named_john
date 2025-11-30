# R/setup/local_full_verification.R
# This script performs a full local verification of the R project
# within a fresh nix-shell context, and pushes the package to Cachix.

# 0. Load necessary R packages for the script itself
# This script is meant to be run *within* a Nix shell where these are available.
library(devtools)
library(roxygen2)
library(testthat)
library(targets)
library(methods) # For generic functions like `check()`
library(utils) # For `packageVersion`

# Helper function to run system commands and check exit status
run_system_command <- function(cmd, error_message = "Command failed.") {
  cat(paste("Running:", cmd, "\n"))
  status <- system(cmd)
  if (status != 0) {
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
  cat("✅ All DESCRIPTION dependencies are available in the Nix shell.\n") 
}

# Load the local package for subsequent checks
cat("\n--- Loading local package (devtools::load_all()) ---
")
devtools::load_all()

# 2. Generate documentation
cat("\n--- 2. Generating documentation (roxygen2::roxygenise()) ---
")
roxygen2::roxygenise() # This will run devtools::document() implicitly if needed

# 3. Run unit tests
cat("\n--- 3. Running unit tests (devtools::test()) ---
")
devtools::test()

# 4. Run R CMD check
cat("\n--- 4. Running R CMD check (devtools::check()) ---
")
# Use --no-build-vignettes --no-manual for faster checks, remove later for full check
devtools::check(error_on = "note", build_args = c("--no-build-vignettes", "--no-manual"))

# 5. Build targets pipeline locally
cat("\n--- 5. Building targets pipeline (targets::tar_make()) ---
")
targets::tar_make()

# 6. Build R package derivation and push to Cachix (johngavin)
cat("\n--- 6. Building R package derivation and pushing to Cachix (johngavin) ---
")
# Check for cachix/nix-build presence
run_system_command("command -v cachix", error_message = "❌ cachix not found. Ensure Nix tools are in PATH.")
run_system_command("command -v nix-build", error_message = "❌ nix-build not found. Ensure Nix tools are in PATH.")

if (!file.exists("package.nix")) {
    stop("❌ package.nix not found in root. Cannot build Nix derivation.", call. = FALSE)
}

# Build the R package as a Nix derivation
run_system_command("nix-build package.nix", error_message = "❌ Failed to build Nix derivation for package.")
result_path <- system("readlink -f result", intern = TRUE) # Get the absolute path of the built derivation

# Push the built derivation to Cachix
run_system_command(paste("cachix push johngavin", shQuote(result_path)), 
                   error_message = paste("❌ Failed to push", result_path, "to Cachix."))

cat("✅ Full local verification and Cachix push complete.\n")
