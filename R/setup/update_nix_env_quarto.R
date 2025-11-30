# R/setup/update_nix_env_quarto.R
library(gert)

message("Staging default.R and default.nix...")
gert::git_add("default.R")
gert::git_add("default.nix")

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% c("default.R", "default.nix"))) {
  gert::git_commit("chore: Add quarto package to Nix environment for pkgdown")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to Nix environment files.")
}
