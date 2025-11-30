# R/setup/update_agents_deps_check.R
library(gert)

message("Staging AGENTS.md...")
gert::git_add("AGENTS.md")

message("Committing...")
gert::git_commit("docs: Add package dependency verification instructions to AGENTS.md")

message("Pushing...")
gert::git_push(verbose = TRUE)
