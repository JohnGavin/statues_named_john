
# Check specific workflow status

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"
branch <- "fix-issue-18-gender-classification"
workflow_name <- "R-CMD-check"

runs <- gh::gh(
  "GET /repos/{owner}/{repo}/actions/runs",
  owner = owner,
  repo = repo,
  branch = branch
)

# Filter for the specific workflow
matching_runs <- Filter(function(x) x$name == workflow_name, runs$workflow_runs)

if (length(matching_runs) > 0) {
  latest_run <- matching_runs[[1]]
  message(sprintf("Latest run for %s: %s", workflow_name, latest_run$status))
  message(sprintf("Conclusion: %s", latest_run$conclusion))
  message(sprintf("URL: %s", latest_run$html_url))
} else {
  message(sprintf("No runs found for workflow: %s", workflow_name))
}
