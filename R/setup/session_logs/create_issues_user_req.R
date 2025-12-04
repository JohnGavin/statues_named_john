
library(gh)

owner <- "JohnGavin"
repo <- "statues_named_john"

# Issue 1: Representation Analysis missing Male
tryCatch({
  gh::gh(
    "POST /repos/{owner}/{repo}/issues",
    owner = owner,
    repo = repo,
    title = "Bug: Representation Analysis plot missing 'Male' category",
    body = "The 'Representation Analysis' section in the `memorial-analysis` vignette (https://johngavin.github.io/statues_named_john/articles/memorial-analysis.html#representation-analysis) reportedly does not include the 'Male' gender.

**Action Required:**
- Verify if the 'Male' category is being filtered out in `R/tar_plans/memorial_analysis_plan.R` or `R/analyze_statues.R`.
- Ensure the plot includes all gender categories (Male, Female, Unknown, Animal, Other).
- Check if the color palette or legend is hiding the category."
  )
  message("Created issue: Bug: Representation Analysis plot missing 'Male' category")
}, error = function(e) message("Error creating issue 1: ", e$message))

# Issue 2: Animal Statue Detection
tryCatch({
  gh::gh(
    "POST /repos/{owner}/{repo}/issues",
    owner = owner,
    repo = repo,
    title = "Feat: Improve Animal Statue Detection with new data sources",
    body = "Enhance the detection of statues honouring animals.

**Current State:**
- Relies on simple regex keywords in `classify_gender_from_subject`.

**Action Required:**
- Investigate new data sources specifically for animal statues (e.g., specialized London memorial datasets).
- Improve classification logic to better identify animal subjects from existing metadata (Wikidata/OSM tags).
- Ensure these are distinct from 'Unknown' or human genders."
  )
  message("Created issue: Feat: Improve Animal Statue Detection with new data sources")
}, error = function(e) message("Error creating issue 2: ", e$message))
