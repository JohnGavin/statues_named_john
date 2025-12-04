
# Finish pushing
gert::git_add(".")
gert::git_commit("Docs: Update session logs")
usethis::pr_push()
