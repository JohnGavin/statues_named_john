# R/setup/fix_nix_env_final.R
library(gert)

message("Staging files...")
gert::git_add(c("default.R", "default.nix"))

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% c("default.R", "default.nix"))) {
  gert::git_commit("chore: Pin Nix env to fixed hash to ensure reproducibility")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to commit.")
}