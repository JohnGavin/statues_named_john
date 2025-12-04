
# Create PR manually since usethis::pr_push() didn't trigger it
# This is necessary to trigger CI workflows which run on pull_request events

library(gh)

# Define PR details
owner <- "JohnGavin"
repo <- "statues_named_john"
title <- "Feat: Integrate gender package for unknown subjects (Issue #18)"
body <- "This PR integrates the `gender` R package to refine gender classification for subjects marked as 'Unknown' by the heuristic. 

Changes:
- Added `gender` to dependencies.
- Updated `analyze_statues.R` to use `gender::gender()` for unknown names.
- Reorganized `R/setup/` directory."
head <- "fix-issue-18-gender-classification"
base <- "main"

# Create PR
tryCatch({
  pr <- gh::gh(
    "POST /repos/{owner}/{repo}/pulls",
    owner = owner,
    repo = repo,
    title = title,
    body = body,
    head = head,
    base = base
  )
  
  message(sprintf("PR created successfully: %s", pr$html_url))
}, error = function(e) {
  message("Failed to create PR: ", e$message)
  # Check if PR already exists
  existing <- gh::gh(
    "GET /repos/{owner}/{repo}/pulls",
    owner = owner,
    repo = repo,
    head = paste0(owner, ":", head)
  )
  if (length(existing) > 0) {
    message(sprintf("PR already exists: %s", existing[[1]]$html_url))
  }
})
