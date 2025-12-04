# R/setup/feat_vignette_glher.R
# 2025-12-01
# Purpose: Add GLHER data source to the memorial analysis pipeline.

# Changes:
# 1. Modified R/tar_plans/memorial_analysis_plan.R: Added `get_statues_glher` and `standardize_statue_data(..., "glher")` targets.
# 2. Updated `combine_statue_sources` call to include `glher = glher_std`.

# Commands:
# git checkout -b feat-vignette-glher
# (Edited R/tar_plans/memorial_analysis_plan.R)
# git add R/tar_plans/memorial_analysis_plan.R R/setup/feat_vignette_glher.R
# git commit -m "FEAT: Add GLHER data source to targets pipeline"
# git push origin feat-vignette-glher
# gh pr create --title "FEAT: Include GLHER in Analysis" --body "Adds Greater London Historic Environment Record data to the analysis pipeline."
