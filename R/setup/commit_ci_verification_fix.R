# R/setup/commit_ci_verification_fix.R
library(gert)

message("Staging files...")
gert::git_add("R/setup/ci_verification.R")

message("Committing...")
gert::git_commit("fix: Correct backslash escaping in ci_verification.R")
message("Pushing...")
gert::git_push(verbose = TRUE)