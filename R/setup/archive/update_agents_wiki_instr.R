# R/setup/update_agents_wiki_instr.R
library(gert)

message("Staging AGENTS.md...")
gert::git_add("AGENTS.md")

message("Committing...")
gert::git_commit("docs: Add Wiki FAQs instructions to AGENTS.md")

message("Pushing...")
gert::git_push(verbose = TRUE)
