# R/setup/fix_ci_workflows.R
library(gert)

message("Staging workflow files...")
files <- c(".github/workflows/test-coverage.yml", ".github/workflows/R-CMD-check.yml", ".github/workflows/pkgdown.yml")
gert::git_add(files)

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% files)) {
  gert::git_commit("fix: Update GitHub Actions workflows for persistent Nix shell")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to workflow files to commit.")
}
