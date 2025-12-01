# R/setup/verify_completion.R
# Checks if the critical CI workflow (R-CMD-check) has passed for the current branch.

check_status <- function() {
  branch <- system("git branch --show-current", intern = TRUE)
  cmd <- sprintf("gh run list --branch %s --workflow R-CMD-check --limit 1 --json conclusion,status", branch)
  result <- jsonlite::fromJSON(system(cmd, intern = TRUE))
  
  if (nrow(result) == 0) {
    message("No runs found.")
    return(FALSE)
  }
  
  status <- result$status[1]
  conclusion <- result$conclusion[1]
  
  message(sprintf("Branch: %s | Status: %s | Conclusion: %s", branch, status, conclusion))
  
  if (status == "completed" && conclusion == "success") {
    message("✅ R-CMD-check passed!")
    return(TRUE)
  } else if (status == "completed" && conclusion == "failure") {
    message("❌ R-CMD-check failed.")
    return(FALSE)
  } else {
    message("⏳ R-CMD-check is still running...")
    return(FALSE)
  }
}

check_status()