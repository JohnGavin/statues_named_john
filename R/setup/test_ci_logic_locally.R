# R/setup/test_ci_logic_locally.R
# Simulates the CI workflow logic to debug failures locally
# Usage: Rscript R/setup/test_ci_logic_locally.R

# 1. Setup temporary library to simulate clean CI env
# (Optional: set to FALSE to use your actual library for speed, 
# but TRUE is safer for reproduction)
USE_TEMP_LIB <- TRUE 

if (USE_TEMP_LIB) {
  lib_dir <- file.path(tempdir(), "ci_sim_lib")
  dir.create(lib_dir, showWarnings = FALSE)
  .libPaths(c(lib_dir, .libPaths()))
  message("Using temporary library: ", lib_dir)
}

# 2. Install setup tools
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

# 3. Simulate "Setup R dependencies" (The failing step)
message("\n--- Step 1: Installing Dependencies (pak) ---")
# Mimics: packages: any::pkgdown, any::remotes, deps::.
tryCatch({
  pak::pkg_install(c("pkgdown", "remotes", "deps::."), upgrade = TRUE)
  message("✅ Dependencies installed successfully")
}, error = function(e) {
  message("❌ Dependency installation failed: ", e$message)
  quit(status = 1)
})

# 4. Simulate "Install local package"
message("\n--- Step 2: Installing Local Package (remotes) ---")
tryCatch({
  remotes::install_local(".", dependencies = FALSE, force = TRUE)
  message("✅ Local package installed successfully")
}, error = function(e) {
  message("❌ Local package installation failed: ", e$message)
  quit(status = 1)
})

# 5. Verify Loading
message("\n--- Step 3: Verification ---")
tryCatch({
  library(londonremembers)
  message("✅ Package loaded successfully")
}, error = function(e) {
  message("❌ Failed to load package: ", e$message)
  quit(status = 1)
})

message("\n🎉 CI Logic Logic Verification Passed!")
