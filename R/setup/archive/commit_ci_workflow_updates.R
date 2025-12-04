# R/setup/commit_ci_workflow_updates.R
library(gert)

message("Staging files...")
gert::git_add("R/setup/ci_verification.R")
gert::git_add(".github/workflows/R-CMD-check.yml")

message("Committing...")
gert::git_commit("chore: Update R-CMD-check workflow to use ci_verification.R")
message("Pushing...")
gert::git_push(verbose = TRUE)