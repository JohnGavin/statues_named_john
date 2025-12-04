# R/setup/render_and_push_readme.R
library(gert)

message("Rendering README...")
system("quarto render inst/qmd/README.qmd --to gfm --output README.md")

message("Staging files...")
gert::git_add("inst/qmd/README.qmd")
gert::git_add("README.md")

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% c("inst/qmd/README.qmd", "README.md"))) {
  gert::git_commit("docs: Update README with developer documentation links")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to README files.")
}
