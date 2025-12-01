# R/setup/pin_local_env.R
# Purpose: Create a GC root for the local Nix environment.
# This prevents the environment from being garbage collected during long sessions or aggressive GC runs.
# It creates a symlink '.local-shell' in the project root.

# Usage: Rscript R/setup/pin_local_env.R

out_link <- ".local-shell"

message(sprintf("Pinning Nix environment to '%s'...", out_link))

# -A shell selects the 'shell' attribute from default.nix (standard for rix)
# -o .local-shell creates the GC root symlink
cmd <- sprintf("nix-build default.nix -A shell -o %s", out_link)

status <- system(cmd)

if (status == 0) {
  message("✅ Environment successfully pinned.")
  message(sprintf("A symlink '%s' has been created. As long as this link exists, the environment will not be garbage collected.", out_link))
  message("You can delete it with 'rm .local-shell' when you are done with this version of the environment.")
} else {
  stop("❌ Failed to pin environment. Check if Nix is installed and default.nix is valid.")
}
