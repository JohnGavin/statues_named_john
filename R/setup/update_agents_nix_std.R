# R/setup/update_agents_nix_std.R
library(gert)

message("Staging AGENTS.md...")
gert::git_add("AGENTS.md")

message("Committing...")
gert::git_commit("docs: Add Nix environment reproducibility standards to AGENTS.md")

message("Pushing...")
gert::git_push(verbose = TRUE)
