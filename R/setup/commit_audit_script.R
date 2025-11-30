# R/setup/commit_audit_script.R
library(gert)

message("Staging audit script...")
gert::git_add("R/setup/audit_dependencies.R")

message("Committing...")
st <- gert::git_status()
if (any(st$file == "R/setup/audit_dependencies.R")) {
  gert::git_commit("docs: Add dependency audit script")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to commit.")
}
