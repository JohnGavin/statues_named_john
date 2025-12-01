**Update:** Pull Request #26 (`https://github.com/JohnGavin/statues_named_john/pull/26`) created to merge implementation into main. CI/CD workflows triggered.

**2025-11-30: Critical Blocker & Stability Improvements**
*   **Issue:** Persistent segmentation fault on macOS AArch64 (Apple Silicon) when loading `roxygen2` in the Nix environment (error in `dyn.load`).
*   **Diagnosis:** Local Nix environment instability or platform-specific build/linking incompatibility for `roxygen2` dependencies in `nixpkgs`.
*   **Actions Taken:**
    *   Consolidated documentation: Merged agent guidelines into `AGENTS.md`, cleaned up obsolete files (`PLAN_*.md`, `prompt.md`), and organized wiki content into `WIKI_CONTENT/`.
    *   Workflow Hardening: Updated `R-CMD-check.yml` and `test-coverage.yml` to implement explicit GC root pinning (`nix-build -A shell -o ...`) to prevent premature garbage collection during CI runs.
    *   Dependency Fixes: Updated `DESCRIPTION` and `default.R` to include `pkgload` and `rcmdcheck` as explicit dependencies, removing reliance on `devtools`.
    *   Standardization: Synchronized `default.nix` and `package.nix` to use the same `rstats-on-nix` snapshot (`2025-11-24`) and R version (`4.5.2`).
*   **Current Status:** Local verification is blocked by the segfault. We are relying on GitHub Actions CI (Linux) to verify the package logic. Codebase is clean and consistent.
*   **Next Steps:** Monitor CI results. If CI passes, proceed with package development. If CI fails, investigate upstream Nix/R issues.

**2025-12-01: CI Repair & GLHER Feature**
*   **Issues Diagnosed:**
    1.  **Permission Denied:** `R-CMD-check` failed to create system GC root (`/nix/var/nix/gcroots/per-user/runner`).
    2.  **Missing Packages:** `pkgdown` and `test-coverage` failed to find R packages (`quarto`, `sf`, etc.) because `shell.nix` (using unstable channel) was conflicting with `default.nix`.
    3.  **Devtools Missing:** `targets::tar_make()` failed in CI because it used `devtools::load_all()` which is not in the environment.
*   **Actions Taken:**
    *   **Fixed Workflows:** Updated `R-CMD-check.yml` and `test-coverage.yml` to use local symlinks for GC roots. Removed problematic `R_LIBS_SITE` overrides.
    *   **Environment Fix:** Deleted `shell.nix` to ensure `nix-shell` uses `default.nix` (pinned environment).
    *   **Code Fix:** Updated `_targets.R` to use `pkgload::load_all()` instead of `devtools`.
    *   **Feature Implementation:** Added Greater London Historic Environment Record (GLHER) to the analysis pipeline in `R/tar_plans/memorial_analysis_plan.R`.
*   **PRs Created:**
    *   PR #46 (`fix-ci-workflows`): Fixes CI permissions and environment. (Merged into `feat-vignette-glher`)
    *   PR #47 (`feat-vignette-glher`): Adds GLHER data source.
*   **Current Status:** 
    *   `test-coverage` ✅ PASSED.
    *   `R-CMD-check` ✅ PASSED.
    *   `pkgdown` ❌ FAILED (Permission denied).
*   **Resolution:** `feat-vignette-glher` merged into `main`.

**2025-12-01: Infrastructure Upgrade (Issue #51)**
*   **Goal:** Resolve `pkgdown` permission errors and improve CI caching/speed by adopting patterns from `JohnGavin/randomwalk`.
*   **Changes (PR #52):**
    *   Upgraded `install-nix-action` to v31 and `checkout` to v4.
    *   Implemented selective Cachix pushing (`skipPush: true` + explicit push) to reduce cache bloat.
    *   Refined `pkgdown` workflow to install the package to a user-writable library (`$HOME/R_libs`) before building the site, and explicitly set `R_LIBS` within the `Rscript` call to ensure `pkgdown` finds the installed package.
*   **Status:** PR #52 merged.
    *   `R-CMD-check` ✅ PASSED.
    *   `test-coverage` ✅ PASSED.
    *   `pkgdown` ❌ FAILED (but with different reasons). This implies the fixes have not fully resolved `pkgdown` issues.

**2025-12-01: Nix Health & Recovery Scripts (Issue #53)**
*   **Goal:** Add scripts to manage local Nix environment health and recovery, and attempt to fix the macOS segfault.
*   **Changes (PR #54):**
    *   Added `R/setup/pin_local_env.R` for local GC root pinning.
    *   Added `R/setup/nix_clean_rebuild.sh` for a "Nuclear Option" clean rebuild.
    *   Attempted to update `default.R` to `2025-12-01`, but the snapshot was not available in `rix`. Reverted `default.R`.
*   **Outcome of Clean Rebuild:** Executed `R/setup/nix_clean_rebuild.sh`. The local verification (`Rscript R/setup/ci_verification.R`) still resulted in a Segmentation Fault (Exit Code 139).
*   **Conclusion:** The segfault is likely due to a persistent binary incompatibility in the `2025-11-24` snapshot for macOS AArch64, not local store corruption.
*   **Next Steps:** If the segfault persists, waiting for a newer `rstats-on-nix` date (e.g., `2025-12-02`) and trying to update `default.R` then, or trying the `r-daily` branch directly in `default.nix`.