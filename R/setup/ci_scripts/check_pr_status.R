#!/usr/bin/env Rscript
# Check PR status using R gh package
# Logged for reproducibility

library(gh)
library(usethis)
library(gert)

message("=== PR Status Check ===")
message(sprintf("Date: %s", Sys.time()))
message(sprintf("Working Directory: %s", getwd()))

# Check branch status
message("\n--- Current Branch ---")
repo_info <- gert::git_info()
message(sprintf("Branch: %s", repo_info$shorthand))
message(sprintf("Commit: %s", repo_info$commit))

# Check if PR exists for update-vignette-comparison branch
message("\n--- Checking for PR ---")
prs <- gh::gh("/repos/JohnGavin/statues_named_john/pulls",
              state = "open",
              head = "JohnGavin:update-vignette-comparison")

if (length(prs) > 0) {
  message(sprintf("✓ Found PR #%d", prs[[1]]$number))
  message(sprintf("  Title: %s", prs[[1]]$title))
  message(sprintf("  URL: %s", prs[[1]]$html_url))
  message(sprintf("  State: %s", prs[[1]]$state))
} else {
  message("✗ No open PR found for branch update-vignette-comparison")
  message("  Need to create PR")
}

# List all open PRs
message("\n--- All Open PRs ---")
all_prs <- gh::gh("/repos/JohnGavin/statues_named_john/pulls",
                  state = "open")
message(sprintf("Total open PRs: %d", length(all_prs)))

sessionInfo()
