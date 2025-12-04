# R/setup/fix_ci_shell_syntax.R
library(gert)

message("Staging workflow files...")
files <- c(".github/workflows/R-CMD-check.yml", ".github/workflows/pkgdown.yml", ".github/workflows/test-coverage.yml")
gert::git_add(files)

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% files)) {
  gert::git_commit("fix: Correct Nix shell syntax in GitHub Actions workflows")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to workflow files.")
}
