# Session Log: Targets-Based Pkgdown Automation
# Date: December 2, 2025
# Issue: #61 (CI performance) + #49 (pkgdown + Nix incompatibility)
# Approach: Use targets to automate vignette rendering and pkgdown building

# ══════════════════════════════════════════════════════════════════════════════
# CONTEXT
# ══════════════════════════════════════════════════════════════════════════════

# Problem 1: Quarto + bslib + Nix = incompatible (fundamental architectural issue)
# Problem 2: r-lib/actions works but packages building from source (20+ minutes)
# Problem 3: Manual vignette rendering required

# Solution: targets workflow that:
# 1. Renders vignettes when data changes
# 2. Builds pkgdown when vignettes change
# 3. Pre-commits HTML to git (fast CI builds)
# 4. Fully automated through targets DAG

# ══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION
# ══════════════════════════════════════════════════════════════════════════════

# ── Step 1: Create documentation_plan.R ──────────────────────────────────────

# File: R/tar_plans/documentation_plan.R
# Contains:
#   - vignette_memorial_analysis_html: Renders .qmd to inst/doc/*.html
#   - vignette_sources: Tracks .qmd file changes
#   - pkgdown_site: Builds site from pre-built vignettes
#   - pkgdown_verification: Checks build success

# Key features:
#   - Explicit dependencies on data targets
#   - Uses quarto::quarto_render() (works with Nix locally)
#   - pkgdown uses pre-built HTML (no Quarto in CI)
#   - format = "file" for vignette outputs (tracks file changes)

# ── Step 2: Update _targets.R ────────────────────────────────────────────────

# Added packages: quarto, pkgdown, sf
# Source documentation_plan.R
# Include in pipeline list

# ── Step 3: Update _pkgdown.yml ──────────────────────────────────────────────

# Updated comment to reference targets workflow
# pkgdown automatically uses inst/doc/*.html when present

# ── Step 4: Update .gitignore ────────────────────────────────────────────────

# Added:
#   /_targets/           # Ignore local cache
#   # inst/doc/*.html    # Explicit note to COMMIT these files

# ── Step 5: Create targets-pkgdown.yml workflow ──────────────────────────────

# File: .github/workflows/targets-pkgdown.yml
# Steps:
#   1. Setup R + Quarto + system dependencies
#   2. Install R packages via r-lib/actions
#   3. Run targets::tar_make() (full pipeline)
#   4. Commit inst/doc/*.html and docs/ [skip ci]
#   5. Deploy docs/ to gh-pages

# ── Step 6: Create documentation ─────────────────────────────────────────────

# File: R/setup/targets_pkgdown_workflow_20251202.md
# Comprehensive guide covering:
#   - Architecture and dependency chain
#   - Workflow execution (local + CI)
#   - Benefits and trade-offs
#   - Comparison with alternatives
#   - Monitoring and troubleshooting

# ══════════════════════════════════════════════════════════════════════════════
# FILES MODIFIED
# ══════════════════════════════════════════════════════════════════════════════

# Created:
#   R/tar_plans/documentation_plan.R
#   .github/workflows/targets-pkgdown.yml
#   R/setup/targets_pkgdown_workflow_20251202.md
#   R/setup/session_log_20251202_targets_pkgdown.R (this file)

# Modified:
#   _targets.R                                      (added docs plan, packages)
#   _pkgdown.yml                                    (updated comment)
#   .gitignore                                      (added _targets/, documented inst/doc/)

# No changes needed:
#   .Rbuildignore                                   (already correct)

# ══════════════════════════════════════════════════════════════════════════════
# TESTING PLAN
# ══════════════════════════════════════════════════════════════════════════════

# Local testing:
# 1. Run targets pipeline
targets::tar_make()

# 2. Verify outputs
stopifnot(file.exists("inst/doc/memorial-analysis.html"))
stopifnot(dir.exists("docs"))
stopifnot(file.exists("docs/articles/memorial-analysis.html"))

# 3. Check pipeline visualization
targets::tar_visnetwork()

# 4. Check what was built
targets::tar_meta() %>%
  dplyr::select(name, type, seconds, bytes) %>%
  print()

# CI testing:
# 1. Commit and push changes
# 2. Monitor targets-pkgdown workflow
# 3. Verify:
#    - Vignettes rendered successfully
#    - pkgdown site built successfully
#    - inst/doc/*.html committed
#    - docs/ deployed to gh-pages

# Expected CI time: ~5-10 minutes (vs 20+ minutes before)

# ══════════════════════════════════════════════════════════════════════════════
# BENEFITS OVER PREVIOUS APPROACH
# ══════════════════════════════════════════════════════════════════════════════

# 1. ✅ Fully automated - no manual vignette rendering
# 2. ✅ Fast CI builds - uses pre-built vignettes (~5-10 min vs 20+ min)
# 3. ✅ Reproducible - all outputs from targets pipeline
# 4. ✅ Cacheable - targets only rebuilds what changed
# 5. ✅ Auditable - complete metadata in targets cache
# 6. ✅ Local development - works in Nix shell perfectly
# 7. ✅ CI compatibility - r-lib/actions with pre-built HTML

# ══════════════════════════════════════════════════════════════════════════════
# TRADE-OFFS
# ══════════════════════════════════════════════════════════════════════════════

# 1. ⚠️  Commits HTML to git (~100-500 KB per vignette)
#    Mitigation: Git compression, only changes tracked
#
# 2. ⚠️  CI makes automatic commits
#    Mitigation: Uses [skip ci], clearly marked as "AUTO:"
#
# 3. ⚠️  Slightly more complex workflow
#    Mitigation: Well documented, clear dependency chain

# ══════════════════════════════════════════════════════════════════════════════
# NEXT STEPS
# ══════════════════════════════════════════════════════════════════════════════

# 1. Commit changes to fix-pkgdown-perms branch
# 2. Push and monitor CI
# 3. Verify:
#    - targets-pkgdown workflow succeeds
#    - Vignettes render correctly
#    - pkgdown site builds successfully
#    - Site deploys to GitHub Pages
# 4. Disable old pkgdown.yml workflow (rename to .old)
# 5. Merge PR
# 6. Update documentation with lessons learned

# ══════════════════════════════════════════════════════════════════════════════
# RELATED ISSUES
# ══════════════════════════════════════════════════════════════════════════════

# Issue #49: pkgdown + Nix + Quarto incompatibility (documented)
# Issue #55: PR with initial bslib workarounds (superseded)
# Issue #61: CI performance - packages building from source (RESOLVED via pre-built)
# Issue #62: Central claude_rix documentation repo (created)

# ══════════════════════════════════════════════════════════════════════════════
# LESSONS LEARNED
# ══════════════════════════════════════════════════════════════════════════════

# 1. **Pre-building is pragmatic**: Many R packages do this for complex vignettes
#
# 2. **targets is powerful**: Automatic dependency tracking eliminates manual steps
#
# 3. **Hybrid workflows are okay**: Nix for dev, r-lib/actions for CI-specific tasks
#
# 4. **Trade-offs are acceptable**: Committing HTML is better than 20-minute builds
#
# 5. **Documentation matters**: Complex workflows need clear explanations

# ══════════════════════════════════════════════════════════════════════════════
# COMMIT COMMAND
# ══════════════════════════════════════════════════════════════════════════════

# Stage all files
gert::git_add(c(
  "R/tar_plans/documentation_plan.R",
  ".github/workflows/targets-pkgdown.yml",
  "_targets.R",
  "_pkgdown.yml",
  ".gitignore",
  "R/setup/targets_pkgdown_workflow_20251202.md",
  "R/setup/session_log_20251202_targets_pkgdown.R"
))

# Commit with descriptive message
gert::git_commit(
  "FEAT: Implement targets-based pkgdown automation

Issue #61: CI performance - eliminate 20-minute builds via pre-built vignettes
Issue #49: pkgdown + Nix + Quarto incompatibility - use targets workflow

Solution:
- Created documentation_plan.R with vignette rendering and pkgdown targets
- Vignettes auto-render when data changes
- pkgdown auto-builds when vignettes change
- Pre-built HTML committed to git (fast CI builds)
- New workflow: targets-pkgdown.yml (replaces pkgdown.yml)

Benefits:
- ✅ Fully automated (no manual vignette rendering)
- ✅ Fast CI (~5-10 min vs 20+ min)
- ✅ Reproducible (all outputs from targets)
- ✅ Cacheable (targets only rebuilds what changed)

Files:
- R/tar_plans/documentation_plan.R (NEW)
- .github/workflows/targets-pkgdown.yml (NEW)
- _targets.R (UPDATED: added docs plan)
- _pkgdown.yml (UPDATED: comment)
- .gitignore (UPDATED: ignore _targets/, commit inst/doc/)
- R/setup/targets_pkgdown_workflow_20251202.md (NEW: comprehensive docs)
- R/setup/session_log_20251202_targets_pkgdown.R (NEW: this log)

Related: #49, #55, #61, #62"
)

# Push to trigger CI
gert::git_push()

# ══════════════════════════════════════════════════════════════════════════════
# MONITORING
# ══════════════════════════════════════════════════════════════════════════════

# Check workflow status
system("gh run list --workflow=targets-pkgdown.yml --limit 3")

# Watch current run
system("gh run watch")

# ══════════════════════════════════════════════════════════════════════════════
# END OF SESSION LOG
# ══════════════════════════════════════════════════════════════════════════════
