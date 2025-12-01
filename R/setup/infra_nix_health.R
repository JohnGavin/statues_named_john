# R/setup/infra_nix_health.R
# 2025-12-01
# Purpose: Implement Nix environment health and recovery improvements (Issue #53).

# Actions:
# 1.  Failed to update default.R date to 2025-12-01 (Not available in rix yet).
#     - Reverted default.R to 2025-11-24.
# 2.  Created R/setup/pin_local_env.R to pin GC root locally.
# 3.  Created R/setup/nix_clean_rebuild.sh for "Nuclear Option" recovery.

# Recommendation:
# - Use R/setup/pin_local_env.R to prevent "command not found" issues during long sessions.
# - Use R/setup/nix_clean_rebuild.sh ONLY if the segfault persists and is suspected to be local corruption.
# - If segfault persists after rebuild, wait for a newer rstats-on-nix date (e.g. 2025-12-02) and try updating default.R then.