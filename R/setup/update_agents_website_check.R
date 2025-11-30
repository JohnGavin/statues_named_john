# R/setup/update_agents_website_check.R
library(gert)

message("Staging AGENTS.md...")
gert::git_add("AGENTS.md")

message("Committing...")
gert::git_commit("docs: Add website verification instructions to AGENTS.md")

message("Pushing...")
gert::git_push(verbose = TRUE)
