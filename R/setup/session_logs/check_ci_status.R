
# Check workflow run status for the new PR

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"
branch <- "fix-issue-18-gender-classification"

# Get recent runs for this branch
runs <- gh::gh(
  "GET /repos/{owner}/{repo}/actions/runs",
  owner = owner,
  repo = repo,
  branch = branch
)

if (length(runs$workflow_runs) > 0) {
  latest_run <- runs$workflow_runs[[1]]
  message(sprintf("Latest run: %s", latest_run$name))
  message(sprintf("Status: %s", latest_run$status))
  message(sprintf("Conclusion: %s", latest_run$conclusion))
  message(sprintf("URL: %s", latest_run$html_url))
} else {
  message("No workflow runs found for this branch yet.")
}
