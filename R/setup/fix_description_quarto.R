# R/setup/fix_description_quarto.R
library(gert)

message("Staging DESCRIPTION...")
gert::git_add("DESCRIPTION")

message("Committing...")
st <- gert::git_status()
if (any(st$file == "DESCRIPTION")) {
  gert::git_commit("fix: Add quarto to DESCRIPTION Suggests")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to commit.")
}
