# Plan: Rename Package to `statuesnamedjohn`

**Issue:** #56
**Objective:** Rename the R package from `londonremembers` to `statuesnamedjohn` to reflect the multi-source nature of the project and decouple it from the specific "London Remembers" website.

## Impact Analysis

This is a global search-and-replace operation that affects:
- Package metadata (`DESCRIPTION`, `NAMESPACE`)
- Source code (`R/*.R`)
- Tests (`tests/testthat/*.R`)
- Documentation (`man/`, `vignettes/`, `inst/qmd/`, `README.md`)
- Configuration (`_pkgdown.yml`, `_targets.R`)
- Infrastructure (`default.nix`, `package.nix`, `.github/workflows/`)

## Step-by-Step Implementation Plan

### 1. Metadata & Config
- [ ] **DESCRIPTION**: Update `Package` field.
- [ ] **_pkgdown.yml**: Update `url` and `title`.
- [ ] **_targets.R**: Update `tar_option_set(packages = ...)` to load `statuesnamedjohn`.

### 2. Infrastructure (Nix & CI)
- [ ] **package.nix**: Update `name` attribute.
- [ ] **default.R**: Update comments or `rix` calls if they reference the package name (though usually they reference deps).
- [ ] **.github/workflows/**: Update `grep` patterns in `R-CMD-check.yml` used for Cachix filtering.

### 3. Codebase Refactor
- [ ] **R/**: Global search and replace `londonremembers` -> `statuesnamedjohn`.
- [ ] **tests/**: Global search and replace.
- [ ] **vignettes/ & inst/qmd/**: Global search and replace.

### 4. Documentation
- [ ] **README.md**: Update installation instructions (`devtools::install_github(...)`) and badges.
- [ ] **Developer Docs**: Update `DEVELOPER_WORKFLOW.md`, `AGENTS.md`.

### 5. Validation
- [ ] Run `devtools::document()` to regenerate `NAMESPACE` and `man/`.
- [ ] Run `devtools::test()` to ensure internal references work.
- [ ] Run `targets::tar_make()` to verify pipeline works with new package name.
- [ ] Run `R CMD check` (locally or CI) to confirm package structure.

## Risks & Mitigation
- **Cache Invalidation**: Renaming the package will invalidate previous Cachix builds of the package itself. *Mitigation: The first CI run will be slower as it rebuilds.*
- **Targets Store**: `targets` metadata might be tied to function names/packages. *Mitigation: `tar_make()` might need a full re-run.*

## Execution Command (Agent)
Use `sed` or `stringr` scripts to perform the replacement systematically to avoid typos.
