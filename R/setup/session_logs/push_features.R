
# Push all feature branches

library(gert)
library(usethis)

# Push 69
gert::git_branch_checkout("fix-issue-69-male-plot")
usethis::pr_push()

# Push 67
gert::git_branch_checkout("feat-issue-67-qa-validation")
usethis::pr_push()

# Push 20
gert::git_branch_checkout("feat-issue-20-wikidata-props")
usethis::pr_push()
