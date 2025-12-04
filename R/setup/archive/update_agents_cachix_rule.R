# R/setup/update_agents_cachix_rule.R
library(gert)

message("Staging AGENTS.md...")
gert::git_add("AGENTS.md")

message("Committing...")
st <- gert::git_status()
if (any(st$file == "AGENTS.md")) {
  gert::git_commit("docs: Enforce Cachix priority rule in AGENTS.md")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to AGENTS.md.")
}
