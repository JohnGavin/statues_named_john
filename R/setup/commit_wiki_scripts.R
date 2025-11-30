# R/setup/commit_wiki_scripts.R
library(gert)

files <- c("R/setup/generate_wiki_faqs.R", "R/setup/update_wiki_faqs.R", "R/setup/WIKI_FAQS_DRAFT.md")
gert::git_add(files)
gert::git_commit("docs: Add scripts for managing Wiki FAQs")
gert::git_push(verbose = TRUE)
