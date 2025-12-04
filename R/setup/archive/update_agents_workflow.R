# R/setup/update_agents_workflow.R
# Log of git operations for updating AGENTS.md

# Check if gert is available (it should be)
if (!requireNamespace("gert", quietly = TRUE)) {
  stop("gert package is required for this script")
}

message("Staging AGENTS.md...")
gert::git_add("AGENTS.md")

message("Committing changes...")
gert::git_commit(message = "docs: Update AGENTS.md with git/gh R package preference and logging rules")

message("Done.")
