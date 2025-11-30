# R/setup/push_latest.R
library(gert)
message("Pushing to origin...")
gert::git_push(verbose = TRUE)
