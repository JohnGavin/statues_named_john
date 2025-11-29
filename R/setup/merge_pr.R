#!/usr/bin/env Rscript
# Merge PR #5 using R gh package
# Logged for reproducibility

library(gh)

message("=== Merging PR #5 ===")
message(sprintf("Date: %s", Sys.time()))

# Get PR details first
message("\n--- PR #5 Details ---")
pr <- gh::gh("/repos/JohnGavin/statues_named_john/pulls/5")

message(sprintf("Title: %s", pr$title))
message(sprintf("State: %s", pr$state))
message(sprintf("Mergeable: %s", ifelse(is.null(pr$mergeable), "checking...", pr$mergeable)))
message(sprintf("URL: %s", pr$html_url))

# Merge the PR
message("\n--- Merging PR ---")
merge_result <- gh::gh(
  "PUT /repos/JohnGavin/statues_named_john/pulls/5/merge",
  merge_method = "merge",
  commit_title = pr$title,
  commit_message = sprintf("%s\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)", pr$body)
)

message(sprintf("✓ PR #5 merged successfully"))
message(sprintf("  SHA: %s", merge_result$sha))
message(sprintf("  Merged: %s", merge_result$merged))
message(sprintf("  Message: %s", merge_result$message))

sessionInfo()
