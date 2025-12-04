
# Merge PR #74

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"
pr_num <- 74

tryCatch({
  # Merge
  gh::gh(
    "PUT /repos/{owner}/{repo}/pulls/{pull_number}/merge",
    owner = owner,
    repo = repo,
    pull_number = pr_num,
    merge_method = "merge" # Use merge commit
  )
  message(sprintf("PR #%d merged successfully.", pr_num))
  
  # Get branch name from PR info to delete it
  pr_info <- gh::gh("GET /repos/{owner}/{repo}/pulls/{pull_number}",
                    owner = owner, repo = repo, pull_number = pr_num)
  branch_to_delete <- pr_info$head$ref

  # Delete branch
  gh::gh(
    "DELETE /repos/{owner}/{repo}/git/refs/heads/{ref}",
    owner = owner,
    repo = repo,
    ref = branch_to_delete
  )
  message(sprintf("Branch '%s' deleted.", branch_to_delete))
  
}, error = function(e) {
  message(sprintf("Error merging/deleting PR #%d: %s", pr_num, e$message))
})
