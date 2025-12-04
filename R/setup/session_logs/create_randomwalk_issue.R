
# Create issue in randomwalk project

library(gh)

owner <- "JohnGavin"
repo <- "randomwalk" # Target randomwalk project

title <- "Chore: Reorganize R/setup/ files into subfolders"
body <- "As per updated guidelines in AGENTS.md (see [statues_named_john project](https://github.com/JohnGavin/statues_named_john/tree/main/R/setup) for an example), the R workflow scripts in `R/setup/` should be organized into logical subfolders based on their topic or function.

This improves clarity and navigation.

**Action Required:**
- Create subfolders (e.g., `archive/`, `ci_scripts/`, `dev_scripts/`, `session_logs/`, `test_data/`, `docs/`, `plans/`) within `R/setup/`.
- Move existing scripts into the appropriate subfolders.
- Update any references to these scripts in CI workflows or other project files.
"

tryCatch({
  res <- gh::gh(
    "POST /repos/{owner}/{repo}/issues",
    owner = owner,
    repo = repo,
    title = title,
    body = body
  )
  message(sprintf("Created issue in %s/%s: %s", owner, repo, res$html_url))
}, error = function(e) {
  message(sprintf("Failed to create issue in %s/%s: %s", owner, repo, e$message))
})
