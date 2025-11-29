#!/usr/bin/env Rscript
# Check GitHub Actions workflow status using R gh package
# Logged for reproducibility

library(gh)

message("=== GitHub Actions Workflow Status ===")
message(sprintf("Date: %s", Sys.time()))

# Get recent workflow runs
message("\n--- Recent Workflow Runs ---")
runs <- gh::gh("/repos/JohnGavin/statues_named_john/actions/runs",
               .limit = 10)

if (length(runs$workflow_runs) > 0) {
  message(sprintf("Total workflow runs found: %d", runs$total_count))
  message("\nRecent runs:")

  for (i in seq_along(runs$workflow_runs)[1:min(10, length(runs$workflow_runs))]) {
    run <- runs$workflow_runs[[i]]
    message(sprintf("\n  Run #%s:", as.character(run$id)))
    message(sprintf("    Name: %s", run$name))
    message(sprintf("    Branch: %s", run$head_branch))
    message(sprintf("    Status: %s", run$status))
    message(sprintf("    Conclusion: %s", ifelse(is.null(run$conclusion), "N/A", run$conclusion)))
    message(sprintf("    Created: %s", run$created_at))
    message(sprintf("    URL: %s", run$html_url))
  }
} else {
  message("No workflow runs found")
}

# Check workflow run for PR #5
message("\n--- Checking Workflows for PR #5 ---")
pr_runs <- gh::gh("/repos/JohnGavin/statues_named_john/actions/runs",
                  event = "pull_request",
                  .limit = 5)

if (length(pr_runs$workflow_runs) > 0) {
  pr5_runs <- Filter(function(r) {
    grepl("update-vignette-comparison", r$head_branch, fixed = TRUE)
  }, pr_runs$workflow_runs)

  if (length(pr5_runs) > 0) {
    message(sprintf("Found %d workflow runs for update-vignette-comparison branch", length(pr5_runs)))
    for (run in pr5_runs) {
      message(sprintf("  %s: %s (status: %s, conclusion: %s)",
                     run$name,
                     run$head_branch,
                     run$status,
                     ifelse(is.null(run$conclusion), "N/A", run$conclusion)))
    }
  } else {
    message("No workflow runs found for update-vignette-comparison branch yet")
    message("Workflows may still be queuing...")
  }
} else {
  message("No PR workflow runs found yet")
}

sessionInfo()
