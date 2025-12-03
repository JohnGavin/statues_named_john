# Nix Documentation Updates - December 2, 2025

## Changes Made to General Nix Documentation

The following files in `/Users/johngavin/docs_gh/claude_rix/` were updated to document the pkgdown + Nix + Quarto + bslib incompatibility discovered during Issue #49 investigation:

### 1. NIX_TROUBLESHOOTING.md

**Section Added**: "Package-Specific Issues → pkgdown with Quarto Vignettes"

**Location**: After "Shell Too Slow" section, before "Troubleshooting Workflow"

**Content**:
- Problem description and symptoms
- Root cause explanation (Nix immutability vs bslib file copying)
- Why fixes don't work in Nix environment
- Solution: Use r-lib/actions in CI instead of Nix
- Local development workarounds
- References to project-specific documentation

**Table of Contents Updated**: Added entry for new subsection

### 2. NIX_WORKFLOW.md

**Section Added**: "Known Limitations"

**Location**: After "Quick Reference", before "Additional Resources"

**Content**:
- Clear statement that pkgdown with Quarto vignettes cannot work in Nix
- Explanation of fundamental incompatibility
- What still works in Nix (package dev, R CMD check, targets, etc.)
- What requires native R (pkgdown with Quarto)
- Workflow recommendations (Nix for development, r-lib/actions for pkgdown)
- Cross-reference to NIX_TROUBLESHOOTING.md

**Table of Contents Updated**: Added "Known Limitations" as item #10

## Rationale

This incompatibility is **not project-specific** - it affects any R package using:
- Nix for reproducible environments
- pkgdown for documentation websites
- Quarto vignettes (.qmd files)
- Bootstrap 5 / bslib styling

By documenting in the general Nix guides, future projects can:
1. Avoid wasting time trying to fix an unfixable issue
2. Understand the design trade-offs
3. Know the correct solution from the start

## Key Lessons Learned

### What We Discovered

1. **Nix immutability is not negotiable**: `/nix/store` is read-only by design
2. **bslib behavior is not negotiable**: It copies files from package location during runtime
3. **Quarto + Bootstrap 5 requirement is not negotiable**: `.qmd` vignettes need Bootstrap 5

These three immutable constraints create a fundamental incompatibility.

### What We Tried (All Failed)

- ❌ Disabling bslib in `_pkgdown.yml`
- ❌ Using Bootstrap 3 template
- ❌ Installing bslib to writable location (Nix blocks install.packages())
- ❌ Pre-rendering vignettes (requires package installation)
- ❌ Rendering vignettes directly with Quarto (package not in subprocess)

### What Works

- ✅ Use **native R (r-lib/actions)** in CI for pkgdown
- ✅ Use **Nix** for everything else (dev, testing, R CMD check)
- ✅ Accept that full pkgdown builds are CI-only

## Impact on Development Workflow

### Old (Incorrect) Assumption
"Nix provides complete reproducibility for all R package operations"

### New (Correct) Understanding
"Nix provides reproducibility for package development and testing. For tools requiring runtime modifications to package files (like bslib), use native R in CI."

### Practical Workflow

```bash
# Local (Nix shell):
targets::tar_make()        # ✅ Data pipelines
devtools::load_all()       # ✅ Development
devtools::test()           # ✅ Testing
devtools::check()          # ✅ R CMD check

# CI (Mixed approach):
# .github/workflows/r-cmd-check.yml → Nix for reproducibility
# .github/workflows/pkgdown.yml     → r-lib/actions for compatibility
```

## Files Modified in This Project

Related documentation in this project:
- `R/setup/pkgdown_nix_solution.R` - Technical analysis
- `R/setup/session_log_20251202_pkgdown_fix.R` - Implementation log
- `.github/workflows/pkgdown.yml` - Uses r-lib/actions
- `R/setup/ci_verification.R` - Made targets optional

## Action Required

**Manual commit needed** for general Nix documentation:

```bash
cd /Users/johngavin/docs_gh/claude_rix/

# Review changes
git diff NIX_TROUBLESHOOTING.md
git diff NIX_WORKFLOW.md

# Commit if satisfied
git add NIX_TROUBLESHOOTING.md NIX_WORKFLOW.md
git commit -m "DOCS: Add pkgdown + Quarto + bslib incompatibility with Nix

Document fundamental incompatibility between:
- Nix immutable store (/nix/store read-only)
- bslib runtime file copying behavior
- Quarto vignettes requiring Bootstrap 5/bslib

Solution: Use r-lib/actions for pkgdown in CI, not Nix

Sections added:
- NIX_TROUBLESHOOTING.md: Package-Specific Issues → pkgdown
- NIX_WORKFLOW.md: Known Limitations

Related: statues_named_john#49, #55, #61"
```

## Future Considerations

### For New Projects

1. **Plan ahead**: If using Quarto vignettes, plan for r-lib/actions pkgdown workflow
2. **Don't assume**: Test pkgdown locally early to catch issues
3. **Document clearly**: Explain why different workflows for different tasks

### Possible Future Solutions

1. **bslib patch**: If bslib adds option to skip file copying (unlikely - breaks functionality)
2. **Nix wrapper**: Custom Nix derivation that pre-copies bslib assets (complex, fragile)
3. **Alternative styling**: Use Bootstrap 5 without bslib (requires Quarto changes)

None of these are currently viable. Native R for pkgdown is the pragmatic solution.

---

**Last Updated**: 2025-12-02
**Relates To**: statues_named_john Issues #49, #55, #58, #60, #61
**Documented In**: NIX_TROUBLESHOOTING.md, NIX_WORKFLOW.md
