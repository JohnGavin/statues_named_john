# R/setup/update_readme_workflow.R
library(gert)

message("Staging files...")
gert::git_add("AGENTS.md")
gert::git_add("README.md")
gert::git_add("inst/qmd/README.qmd")

message("Committing...")
gert::git_commit("docs: Convert README to Quarto (inst/qmd/README.qmd) and update AGENTS.md")

message("Pushing...")
gert::git_push(verbose = TRUE)
