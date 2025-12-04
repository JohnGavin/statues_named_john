
# Merge PR #68

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"
pr_number <- 68

tryCatch({
  # Merge
  gh::gh(
    "PUT /repos/{owner}/{repo}/pulls/{pull_number}/merge",
    owner = owner,
    repo = repo,
    pull_number = pr_number,
    merge_method = "merge",
    commit_title = "Merge PR #68: Refine Gender Classification & Fixes",
    commit_message = "Integrated gender package, fixed CI paths, updated limerick."
  )
  message("PR #68 merged successfully.")
  
  # Delete branch
  gh::gh(
    "DELETE /repos/{owner}/{repo}/git/refs/heads/{ref}",
    owner = owner,
    repo = repo,
    ref = "fix-issue-18-gender-classification"
  )
  message("Branch 'fix-issue-18-gender-classification' deleted.")
  
}, error = function(e) {
  message("Error merging/deleting: ", e$message)
})
