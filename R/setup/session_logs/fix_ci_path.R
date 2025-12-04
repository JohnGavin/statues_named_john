
# Fix CI path
gert::git_add(".github/workflows/R-CMD-check.yml")
gert::git_commit("Fix: Update CI workflow to point to correct verification script path")
usethis::pr_push()
