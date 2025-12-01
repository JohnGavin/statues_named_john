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
*   **Actions Taken:**
    *   **Fixed Workflows:** Updated `R-CMD-check.yml` and `test-coverage.yml` to use local symlinks for GC roots. Removed problematic `R_LIBS_SITE` overrides.
    *   **Environment Fix:** Deleted `shell.nix` to ensure `nix-shell` uses `default.nix` (pinned environment).
    *   **Feature Implementation:** Added Greater London Historic Environment Record (GLHER) to the analysis pipeline in `R/tar_plans/memorial_analysis_plan.R`.
    *   **Debugging:** Enabled verbose error reporting in `R/setup/ci_verification.R`.
*   **PRs Created:**
    *   PR #46 (`fix-ci-workflows`): Fixes CI permissions and environment.
    *   PR #47 (`feat-vignette-glher`): Adds GLHER data source (includes CI fixes).
*   **Next Steps:** Monitor PR #47. If `targets::tar_make()` fails, check verbose logs for network/logic errors. If `pkgdown` fails on file permissions (read-only Nix store files), investigate `bslib` copying issue.
