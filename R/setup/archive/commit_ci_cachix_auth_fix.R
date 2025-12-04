# R/setup/commit_ci_cachix_auth_fix.R
library(gert)

message("Staging files...")
gert::git_add(".github/workflows/R-CMD-check.yml")

message("Committing...")
gert::git_commit("fix(ci): Pass CACHIX_AUTH_TOKEN to nix-shell in R-CMD-check workflow")
message("Pushing...")
gert::git_push(verbose = TRUE)