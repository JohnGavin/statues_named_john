# R/setup/fix_tests_cleaning_subjects.R
# Date: 2025-11-29
# Objective: Fix failing tests in test-cleaning.R and warnings in test-subjects.R.

# 1. Create branch
# usethis::pr_init("fix-tests-cleaning-subjects")

# 2. Fix R/cleaning.R (classify_subject)
#    - Refined to use "\bdogs?\b" regex for robustness
#    - Standardized category to "Dogs" (plural)
#    - Updated test-cleaning.R and test-cleaning-integration.R matches

# 3. Fix R/subjects.R (get_subjects_by_category)
#    - Updated selector to ".subject.card" and "h2 a"

# 4. Merged previous scraping fix
# gert::git_merge("fix-issue-16-scraping-selectors")

# 5. Verification
# devtools::test() -> 0 FAIL, 43 PASS
