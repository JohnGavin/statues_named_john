# R/setup/update_wiki_faqs.R
# Update GitHub Wiki FAQs page

library(gert)

wiki_repo <- "wiki_temp"

if (!dir.exists(wiki_repo)) {
  stop("Wiki repo not found at 'wiki_temp'")
}

message("Updating FAQs.md in Wiki...")
file.copy("R/setup/WIKI_FAQS_DRAFT.md", file.path(wiki_repo, "FAQs.md"), overwrite = TRUE)

message("Staging...")
gert::git_add("FAQs.md", repo = wiki_repo)

message("Committing...")
# Check if there are changes first to avoid error
st <- gert::git_status(repo = wiki_repo)
if (nrow(st) > 0) {
  gert::git_commit("Update FAQs from R/setup tasks", repo = wiki_repo)
  
  message("Pushing...")
  gert::git_push(repo = wiki_repo, verbose = TRUE)
  message("Wiki updated successfully.")
} else {
  message("No changes to commit.")
}
