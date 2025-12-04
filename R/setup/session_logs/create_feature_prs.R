
# Create PRs for the 3 features

library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"

# Define PRs
prs <- list(
  list(head = "fix-issue-69-male-plot", title = "Fix: Representation Analysis missing Male category (Issue #69)", body = "Fixes filtering issue where 'Male' was excluded from analysis plots."),
  list(head = "feat-issue-67-qa-validation", title = "Feat: QA Validation Tools (Issue #67)", body = "Adds `generate_qa_sample()` to assist with manual data validation."),
  list(head = "feat-issue-20-wikidata-props", title = "Feat: Add height and dedicated_to props (Issue #20)", body = "Updates Wikidata scraper to fetch height (P2048) and dedicated to (P825).")
)

for (p in prs) {
  tryCatch({
    res <- gh::gh(
      "POST /repos/{owner}/{repo}/pulls",
      owner = owner,
      repo = repo,
      title = p$title,
      body = p$body,
      head = p$head,
      base = "main"
    )
    message(sprintf("Created PR for %s: %s", p$head, res$html_url))
  }, error = function(e) {
    message(sprintf("Failed to create PR for %s: %s", p$head, e$message))
  })
}
