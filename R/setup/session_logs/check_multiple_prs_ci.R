
# Check CI Status for multiple PRs

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"

pr_numbers <- c(71, 72, 73, 74)

for (pr_num in pr_numbers) {
  tryCatch({
    pr_info <- gh::gh("GET /repos/{owner}/{repo}/pulls/{pull_number}",
                      owner = owner, repo = repo, pull_number = pr_num)
    
    branch <- pr_info$head$ref
    
    runs <- gh::gh(
      "GET /repos/{owner}/{repo}/actions/runs",
      owner = owner,
      repo = repo,
      branch = branch
    )
    
    if (length(runs$workflow_runs) > 0) {
      # Filter for R-CMD-check
      r_cmd_check_runs <- Filter(function(x) x$name == "R-CMD-check", runs$workflow_runs)
      
      if (length(r_cmd_check_runs) > 0) {
        latest_run <- r_cmd_check_runs[[1]]
        message(sprintf("PR #%d (%s) - R-CMD-check Status: %s | Conclusion: %s | URL: %s",
                        pr_num, branch, latest_run$status, latest_run$conclusion, latest_run$html_url))
      } else {
        message(sprintf("PR #%d (%s) - No R-CMD-check runs found.", pr_num, branch))
      }
    } else {
      message(sprintf("PR #%d (%s) - No workflow runs found for this branch yet.", pr_num, branch))
    }
  }, error = function(e) {
    message(sprintf("Error checking PR #%d: %s", pr_num, e$message))
  })
}
