
# Update limerick formatting
gert::git_add("inst/qmd/memorial-analysis.qmd")
gert::git_commit("Docs: Update limerick in memorial-analysis.qmd")
usethis::pr_push()
