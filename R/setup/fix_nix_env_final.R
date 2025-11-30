# R/setup/fix_nix_env_final.R
library(gert)

message("Updating DESCRIPTION RoxygenNote...")
desc <- readLines("DESCRIPTION")
desc <- gsub("RoxygenNote: 7.3.3", "RoxygenNote: 7.3.2", desc)
writeLines(desc, "DESCRIPTION")

message("Staging files...")
gert::git_add(c("default.R", "default.nix", "DESCRIPTION"))

message("Committing...")
st <- gert::git_status()
if (any(st$file %in% c("default.R", "default.nix", "DESCRIPTION"))) {
  gert::git_commit("chore: Update Nix env to latest-upstream and downgrade RoxygenNote to match")
  message("Pushing...")
  gert::git_push(verbose = TRUE)
} else {
  message("No changes to commit.")
}
