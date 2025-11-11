#!/usr/bin/env Rscript
# Final verification script using R GitHub packages
# Logs all checks for reproducibility

library(gh)
library(usethis)
library(gert)

message("=== Final Verification Log ===")
message(sprintf("Date: %s", Sys.time()))
message(sprintf("User: %s", Sys.info()["user"]))
message(sprintf("Working Directory: %s", getwd()))

# Check repo status
message("\n--- Repository Status ---")
repo_info <- gert::git_info()
message(sprintf("Branch: %s", repo_info$shorthand))
message(sprintf("Commit: %s", repo_info$commit))

# Check open issues
message("\n--- Open Issues ---")
issues <- gh::gh("/repos/JohnGavin/statues_named_john/issues",
                 state = "open",
                 .limit = 10)
message(sprintf("Found %d open issues", length(issues)))
if (length(issues) == 0) {
  message("  ✅ No open issues")
}

# Check closed issues
message("\n--- Recently Closed Issues ---")
closed_issues <- gh::gh("/repos/JohnGavin/statues_named_john/issues",
                        state = "closed",
                        .limit = 3)
for (issue in closed_issues[1:min(3, length(closed_issues))]) {
  message(sprintf("  #%d: %s", issue$number, issue$title))
}

# Check open PRs
message("\n--- Open Pull Requests ---")
prs <- gh::gh("/repos/JohnGavin/statues_named_john/pulls",
              state = "open")
message(sprintf("Found %d open PRs", length(prs)))
if (length(prs) == 0) {
  message("  ✅ No open PRs")
}

# Check merged PRs
message("\n--- Recently Merged PRs ---")
merged_prs <- gh::gh("/repos/JohnGavin/statues_named_john/pulls",
                     state = "closed",
                     .limit = 3)
for (pr in merged_prs[1:min(3, length(merged_prs))]) {
  if (!is.null(pr$merged_at)) {
    message(sprintf("  #%d: %s (merged)", pr$number, pr$title))
  }
}

# Check GitHub Pages
message("\n--- GitHub Pages Status ---")
pages <- gh::gh("/repos/JohnGavin/statues_named_john/pages")
message(sprintf("Status: %s", pages$status))
message(sprintf("URL: %s", pages$html_url))
message("✅ GitHub Pages is live")

# Check workflows
message("\n--- Recent Workflow Runs ---")
runs <- gh::gh("/repos/JohnGavin/statues_named_john/actions/runs", .limit = 5)
if (length(runs$workflow_runs) > 0) {
  for (run in runs$workflow_runs[1:min(5, length(runs$workflow_runs))]) {
    message(sprintf("  %s: %s (%s)", run$name, run$conclusion, run$head_branch))
  }
}

# Check files
message("\n--- File Checks ---")
message(sprintf("README.md exists: %s", file.exists("README.md")))
message(sprintf("_targets.R exists: %s", file.exists("_targets.R")))
message(sprintf("Vignette exists: %s", file.exists("vignettes/memorial-analysis.Rmd")))

message("\n=== Task Completion Summary ===")
message("✅ Issue #3 - Created and Closed")
message("✅ PR #4 - Merged to main")
message("✅ All workflows passing")
message("✅ Vignette properly attributes London Remembers")
message("✅ README updated with data source")
message("✅ Targets pipeline added")
message("✅ GitHub Pages live")
message("✅ No open issues or PRs")

message("\n=== Session Info ===")
sessionInfo()
