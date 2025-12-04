# R/setup/fix_ci_visnetwork.R
# Log for fixing CI failure and adding visNetwork

# 1. Add visNetwork to Suggests
desc::desc_set_dep("visNetwork", "Suggests")

# 2. Regenerate Nix files (to include visNetwork in default.nix/package.nix)
source("R/setup/generate_nix_files.R")
generate_all_nix_files()

# 3. Verify Nix files
generate_all_nix_files(verify = TRUE)

# 4. Git operations (will be done via gert/usethis in the agent workflow)
