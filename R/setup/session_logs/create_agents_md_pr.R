
# Create PR for docs-update-r-setup-organization

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"
head_branch <- "docs-update-r-setup-organization"
title <- "Docs: Update AGENTS.md with R/setup/ organization guidelines"
body <- "Adds a new section to AGENTS.md detailing the recommended organization of R workflow scripts within the `R/setup/` directory into topic-based subfolders. This aligns with the recent refactoring of this project's `R/setup/` directory."

tryCatch({
  res <- gh::gh(
    "POST /repos/{owner}/{repo}/pulls",
    owner = owner,
    repo = repo,
    title = title,
    body = body,
    head = head_branch,
    base = "main"
  )
  message(sprintf("Created PR for %s: %s", head_branch, res$html_url))
}, error = function(e) {
  message(sprintf("Failed to create PR for %s: %s", head_branch, e$message))
})
