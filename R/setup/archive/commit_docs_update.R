# R/setup/commit_docs_update.R
library(gert)

message("Staging files...")
gert::git_add("inst/qmd/README.qmd")
gert::git_add("README.md")
gert::git_add("vignettes/memorial-analysis.qmd")
gert::git_add("DESCRIPTION")
gert::git_add("man/")
gert::git_add("NAMESPACE")

message("Committing...")
st <- gert::git_status()
if (any(st$staged)) {
  gert::git_commit("docs: Add limericks and enhance vignette UX")
  message("Committed.")
} else {
  message("No changes to commit.")
}
