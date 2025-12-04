
# Add all uncommitted logs and push
gert::git_add(".")
gert::git_commit("Chore: Commit session logs")

# Now push everything
library(gert)
library(usethis)

# 69
gert::git_branch_checkout("fix-issue-69-male-plot")
usethis::pr_push()

# 67
gert::git_branch_checkout("feat-issue-67-qa-validation")
gert::git_add(".") # Ensure logs are staged if moved
if (nrow(gert::git_status()) > 0) gert::git_commit("Chore: Update logs")
usethis::pr_push()

# 20
gert::git_branch_checkout("feat-issue-20-wikidata-props")
gert::git_add(".")
if (nrow(gert::git_status()) > 0) gert::git_commit("Chore: Update logs")
usethis::pr_push()
