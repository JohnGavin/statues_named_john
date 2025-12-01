# R/setup/infra_nix_health.R
# 2025-12-01
# Purpose: Implement Nix environment health and recovery improvements (Issue #53).

# Actions:
# 1.  Reverted default.R to 2025-11-24.
# 2.  Created R/setup/pin_local_env.R to pin GC root locally.
# 3.  Created R/setup/nix_clean_rebuild.sh for "Nuclear Option" recovery.

# Outcome of Clean Rebuild Attempt:
# - Executed R/setup/nix_clean_rebuild.sh
# - Local verification (Rscript R/setup/ci_verification.R) still resulted in Segmentation Fault (Exit Code 139).
# - This indicates the issue is not local store corruption but likely a persistent binary incompatibility in the 2025-11-24 snapshot.

# Recommendation:
# - Use R/setup/pin_local_env.R to prevent "command not found" issues during long sessions.
# - Use R/setup/nix_clean_rebuild.sh ONLY if the segfault persists and is suspected to be local corruption (already tried once).
# - If segfault persists (which it does), waiting for a newer rstats-on-nix date (e.g. 2025-12-02) and trying to update default.R then, or trying the `r-daily` branch directly in default.nix.
