
library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"

title <- "Feat: Add 'Animal' and 'Unknown' tabs to Top Names by Gender"
body <- "The 'Top Names by Gender' section in the `memorial-analysis.html` vignette currently only displays tabs for 'Female' and 'Male' subjects.

To provide a more comprehensive view of commemorative patterns, the following enhancements are required:

**Action Required:**
1.  Extend the tabset at `https://johngavin.github.io/statues_named_john/articles/memorial-analysis.html#top-names-by-gender` to include new tabs for:
    *   **Animal**
    *   **Unknown**
2.  Within each new tab, display the most common names found for subjects in that category.
3.  In cases of ties for common names, implement a mechanism to randomly sample names to ensure variety in display.
4.  Update the underlying data processing in `R/analyze_statues.R` and `R/tar_plans/memorial_analysis_plan.R` as necessary to support this display."

tryCatch({
  res <- gh::gh(
    "POST /repos/{owner}/{repo}/issues",
    owner = owner,
    repo = repo,
    title = title,
    body = body
  )
  message(sprintf("Created issue: %s", res$html_url))
}, error = function(e) {
  message(sprintf("Error creating issue: %s", e$message))
})
