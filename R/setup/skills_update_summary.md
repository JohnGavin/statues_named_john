# Claude Skills Update - Persistent Nix Shell Requirement

## Date: 2025-11-11

## Critical Change Summary

Updated both Claude skills to enforce the use of a **single persistent nix-shell** for all R commands in all projects.

## Files Modified

### 1. `.claude/skills/nix-rix-r-environment/SKILL.md`

**Added Section:** "⚠️ CRITICAL: Use Single Persistent Nix Shell for All R Commands"

Located at the beginning of "Key Principles" section (lines 24-67).

### 2. `.claude/skills/r-package-workflow/SKILL.md`

**Added Section:** "⚠️ CRITICAL: Use Single Persistent Nix Shell for All R Commands"

Located at the beginning of "Key Principles" section (lines 217-261).

## Key Requirements Now Enforced

### PRIMARY OBJECTIVE: REPRODUCIBILITY

1. **Start ONE persistent nix-shell at project start**
   ```bash
   nix-shell --run "bash" &
   # Save shell ID (e.g., 234914)
   ```

2. **Execute ALL R commands in this single shell**
   - All R scripts
   - Package development: `devtools::check()`, `devtools::test()`, `devtools::document()`
   - Website building: `pkgdown::build_site()`
   - Git/GitHub operations: `gert`, `gh`, `usethis` packages
   - Targets pipeline execution
   - Any other R operations

3. **Why This Is Critical**
   - ✅ Consistent package versions across all operations
   - ✅ Shared R session state
   - ✅ Faster execution (no repeated initialization)
   - ✅ True reproducibility - same environment throughout session
   - ❌ New shells break reproducibility
   - ❌ Each new shell may have different state

## Examples Included in Skills

### ❌ WRONG Approach (Do NOT Do This)
```bash
# Creates new environment each time - breaks reproducibility
nix-shell --run "Rscript script1.R"
nix-shell --run "Rscript script2.R"
nix-shell --run "Rscript script3.R"
```

### ✅ CORRECT Approach (Always Do This)
```bash
# Single persistent shell for entire session
nix-shell  # Start once (e.g., shell ID: 234914)

# Then execute all commands in that shell:
Rscript script1.R
Rscript script2.R
Rscript script3.R
```

## Impact

This update ensures that:

1. **All future R projects** will follow this reproducibility standard
2. **Claude will always** start and maintain a persistent nix-shell
3. **No ad-hoc shell launching** will occur during development
4. **True reproducibility** is achieved across all R operations

## Visibility

The requirement is:
- ⚠️ Marked with warning emoji
- **Bolded as PRIMARY OBJECTIVE**
- Listed FIRST in Key Principles sections
- Included in both DO and DON'T lists
- Demonstrated with clear examples

## Enforcement

Every time Claude works on an R project with nix/rix:
1. The skill will be loaded
2. The CRITICAL requirement will be at the top of Key Principles
3. Claude must follow this pattern
4. Any deviation violates the reproducibility objective

## Current Session Implementation

This session already implements this requirement:
- **Persistent shell ID:** 234914
- **Status:** Currently initializing
- **Will be used for:** All subsequent R operations in this project

## Conclusion

These skills updates establish a **mandatory reproducibility standard** for all R development work using nix/rix environments. This ensures consistent, reliable, and truly reproducible R workflows across all projects.
