# R/setup/cleanup_scripts.R
library(gert)

message("Staging all R scripts in R/setup...")
files <- list.files("R/setup", pattern = "\\.R$", full.names = TRUE)
gert::git_add(files)

message("Committing...")
# Check for changes
st <- gert::git_status()
if (nrow(st) > 0) {
  gert::git_commit("docs: Add R/setup maintenance scripts")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to commit.")
}

