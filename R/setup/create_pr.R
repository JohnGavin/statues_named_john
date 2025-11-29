#!/usr/bin/env Rscript
# Create PR using R gh package
# Logged for reproducibility

library(gh)
library(gert)

message("=== Creating Pull Request ===")
message(sprintf("Date: %s", Sys.time()))

# Check current branch
repo_info <- gert::git_info()
message(sprintf("Current branch: %s", repo_info$shorthand))
message(sprintf("Commit: %s", repo_info$commit))

# Create PR
message("\n--- Creating PR ---")

pr_body <- "## Summary

This PR enhances the memorial analysis vignette with:

1. **Comprehensive Data Overview**: Added section describing all data categories available from London Remembers
   - Memorial types (statues, plaques, monuments, etc.)
   - Subject metadata (names, categories, dates, locations)
   - Database scale (~9,000+ subjects documented)

2. **Statues for Equality Comparison**: Added critical analysis section comparing their claims to London Remembers methodology
   - Documents their claim: \"3% of UK statues are women (non-royal/mythical), London at 6%\"
   - Identifies methodological concerns (no sources, unclear definitions, missing methodology)
   - Provides framework for rigorous comparison once JS scraping is implemented
   - Demonstrates how to conduct transparent, reproducible analysis

3. **Technical Documentation**: Updated all sections to clearly document JavaScript rendering limitation and demonstrate expected analysis structure

All changes maintain proper attribution to London Remembers as the data source.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

pr <- gh::gh(
  "POST /repos/JohnGavin/statues_named_john/pulls",
  title = "Add data overview and Statues for Equality comparison to vignette",
  head = "update-vignette-comparison",
  base = "main",
  body = pr_body
)

message(sprintf("✓ PR #%d created successfully", pr$number))
message(sprintf("  Title: %s", pr$title))
message(sprintf("  URL: %s", pr$html_url))
message(sprintf("  State: %s", pr$state))

cat("\nPR URL:\n")
cat(pr$html_url, "\n")

sessionInfo()
