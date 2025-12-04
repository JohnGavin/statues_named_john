# R/setup/commit_ci_explicit_nix_fix.R
library(gert)

message("Staging files...")
gert::git_add(".github/workflows/R-CMD-check.yml")

message("Committing...")
gert::git_commit("fix(ci): Explicitly name default.nix and add debug cat to R-CMD-check workflow")
message("Pushing...")
gert::git_push(verbose = TRUE)