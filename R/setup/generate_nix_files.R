# R/setup/generate_nix_files.R

generate_all_nix_files <- function(verify = FALSE) {
  message("Regenerating default.nix via default.R...")
  # Use local=TRUE to ensure objects created in default.R don't clutter global env,
  # but rix needs to run.
  source("default.R", local = TRUE)
  
  message("package.nix is currently manually maintained.")
  message("Please ensure it is consistent with DESCRIPTION.")
  
  if (verify) {
    if (!file.exists("default.nix")) stop("default.nix not found")
    if (!file.exists("package.nix")) stop("package.nix not found")
    message("Verification complete: default.nix and package.nix exist.")
  }
}

update_nix_files <- function() {
  generate_all_nix_files()
}
