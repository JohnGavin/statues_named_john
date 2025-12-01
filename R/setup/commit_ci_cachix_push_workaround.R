# R/setup/commit_ci_cachix_push_workaround.R
library(gert)

message("Staging files...")
gert::git_add(".github/workflows/R-CMD-check.yml")

message("Committing...")
gert::git_commit("feat(ci): Add temporary Cachix push workaround for #45")
message("Pushing...")
gert::git_push(verbose = TRUE)