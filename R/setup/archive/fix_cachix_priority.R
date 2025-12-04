# R/setup/fix_cachix_priority.R
library(gert)

message("Staging workflow files...")
files <- c(".github/workflows/pkgdown.yml", ".github/workflows/R-CMD-check.yml", ".github/workflows/test-coverage.yml")
gert::git_add(files)

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% files)) {
  gert::git_commit("fix: Prioritize rstats-on-nix in Cachix pull list for workflows")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to workflow files to commit.")
}
