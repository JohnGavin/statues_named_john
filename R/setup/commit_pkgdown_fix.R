# R/setup/commit_pkgdown_fix.R
library(gert)

message("Staging files...")
gert::git_add(".github/workflows/pkgdown.yml")

message("Committing...")
gert::git_commit("fix(ci): Set R_LIBS_SITE explicitly for pkgdown workflow")
message("Pushing...")
gert::git_push(verbose = TRUE)