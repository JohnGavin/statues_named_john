# R Package Development Workflow

## Description

This skill provides a structured workflow for R package development following best practices, including issue tracking, branching, testing, documentation, and PR management using R packages (gert, gh, usethis) instead of CLI commands.

## Purpose

Use this skill when:
- Developing R packages with proper version control
- Following a GitHub-based development workflow
- Ensuring code quality through testing and documentation
- Preparing packages for submission to repositories (CRAN, R-universe, etc.)

## Core Workflow Steps

### 1. Create GitHub Issue

Start by documenting what you're going to do:

```r
library(gh)

# Create issue on GitHub
issue <- gh::gh("POST /repos/{owner}/{repo}/issues",
                owner = "username",
                repo = "reponame",
                title = "Add new feature X",
                body = "Description of the feature")

issue_number <- issue$number
cat("Created issue #", issue_number, "\n")
```

### 2. Create Development Branch

```r
library(usethis)

# Create and checkout branch
branch_name <- paste0("fix-issue-", issue_number, "-description")
usethis::pr_init(branch_name)
```

Or with gert:
```r
library(gert)
gert::git_branch_create(branch_name)
gert::git_branch_checkout(branch_name)
```

### 3. Make Changes and Commit Locally

```r
# Make your code changes...
# Then commit (DO NOT PUSH YET)

library(gert)

# Stage files
gert::git_add(c("R/new_function.R", "tests/testthat/test-new_function.R"))

# Commit locally
gert::git_commit("Add new function X for issue #123")
```

**Log your commands** in `R/setup/dev_log.R`:
```r
# R/setup/dev_log.R
# Issue #123: Add new feature X
# Date: 2025-11-10

library(gert)

gert::git_add("R/new_function.R")
gert::git_commit("Add new function X")
# ... more commands
```

### 4. Run All Checks Locally

**CRITICAL**: Fix ALL issues before pushing!

```r
library(devtools)

# Update documentation
devtools::document()

# Run tests
devtools::test()

# Run full check (must pass with 0 errors, 0 warnings, 0 notes)
devtools::check()

# Build package website
pkgdown::build_site()
```

**If any issues**:
- Fix them
- Commit the fixes
- Run checks again
- Repeat until all pass

### 5. Push to Remote

Only push when local checks pass:

```r
library(usethis)

# This will push and create PR if needed
usethis::pr_push()
```

Or with gert:
```r
library(gert)
gert::git_push()
```

### 6. Wait for GitHub Actions

Monitor your workflows:

```r
library(gh)

# Check workflow runs
runs <- gh::gh("/repos/{owner}/{repo}/actions/runs",
               owner = "username",
               repo = "reponame",
               branch = "your-branch")

# Check status
for(run in runs$workflow_runs) {
  cat(run$name, ":", run$status, "|", run$conclusion, "\n")
}
```

**All workflows must pass** (✅) before merging:
- R CMD check
- Tests
- pkgdown build
- Any other CI checks

### 7. Merge PR and Close Issue

When all checks pass:

```r
library(usethis)

# Merge PR to main
usethis::pr_merge_main()

# Clean up local branch
usethis::pr_finish()
```

Or manually with gh:
```r
library(gh)

# Merge PR
gh::gh("PUT /repos/{owner}/{repo}/pulls/{number}/merge",
       owner = "username",
       repo = "reponame",
       number = pr_number,
       merge_method = "merge")
```

The issue will close automatically if your PR included "Fixes #123" or "Closes #123".

### 8. Log Everything

Keep a complete log in `R/setup/dev_log.R`:

```r
# R/setup/dev_log.R

# ============================================
# Issue #123: Add feature X
# Date: 2025-11-10
# ============================================

library(usethis)
library(gert)
library(devtools)

# 1. Create branch
usethis::pr_init("fix-issue-123-feature-x")

# 2. Make changes
# ... edited files ...

# 3. Commit
gert::git_add(c("R/feature.R", "tests/testthat/test-feature.R"))
gert::git_commit("Add feature X for issue #123")

# 4. Local checks
devtools::document()
devtools::test()
devtools::check()

# 5. Push
usethis::pr_push()

# 6. After CI passes, merge
usethis::pr_merge_main()
usethis::pr_finish()
```

## Key Principles

### ✅ DO

- Create GitHub issue first
- Work on feature branches
- Commit locally multiple times before pushing
- Run ALL checks locally before pushing
- Fix all errors/warnings/notes
- Wait for all CI checks to pass
- Log all commands for reproducibility
- Use R packages (gert, gh, usethis) not CLI

### ❌ DON'T

- Push without running local checks
- Merge PRs with failing tests
- Skip documentation updates
- Use git/gh CLI commands (use R packages)
- Commit directly to main branch
- Push code with errors/warnings

## File Organization

```
package-root/
├── R/                      # Package R code
│   ├── functions.R         # Your package functions
│   ├── setup/              # Development scripts
│   │   └── dev_log.R       # Command log
│   └── log/
│       └── git_gh.R        # Git/GitHub command log
├── tests/
│   └── testthat/           # Test files
├── man/                    # Documentation (auto-generated)
├── vignettes/              # Long-form documentation
├── _targets.R              # Targets pipeline (optional)
├── DESCRIPTION             # Package metadata
├── NAMESPACE               # Exports (auto-generated)
└── README.md               # Package introduction
```

## Testing Best Practices

### Unit Tests

```r
# tests/testthat/test-myfunction.R
test_that("myfunction works correctly", {
  result <- myfunction(input)
  expect_equal(result, expected_output)
  expect_type(result, "double")
})

test_that("myfunction handles errors", {
  expect_error(myfunction(invalid_input), "Invalid input")
})
```

### Run Tests

```r
# Run all tests
devtools::test()

# Run specific file
devtools::test_file("tests/testthat/test-myfunction.R")

# Run with coverage
covr::package_coverage()
```

## Documentation Standards

### Function Documentation

```r
#' Title of Function
#'
#' More detailed description of what the function does.
#'
#' @param x Description of parameter x
#' @param y Description of parameter y
#'
#' @return Description of return value
#'
#' @examples
#' myfunction(1, 2)
#' myfunction(x = 10, y = 20)
#'
#' @export
myfunction <- function(x, y) {
  # implementation
}
```

### Update Documentation

```r
# Generate .Rd files from roxygen comments
devtools::document()

# Preview documentation
?myfunction
```

## Targets Pipeline Integration

### Pre-calculate Vignette Objects

```r
# _targets.R
library(targets)

tar_plan(
  # Data processing
  tar_target(raw_data, read_data()),
  tar_target(clean_data, process_data(raw_data)),

  # Analysis
  tar_target(results, analyze(clean_data)),

  # Visualizations (as ggplot objects)
  tar_target(plot_results, plot_results_gg(results)),
  tar_target(plot_diagnostics, plot_diagnostics_gg(results))
)
```

### Use in Vignettes

```r
# vignettes/analysis.Rmd
library(targets)

# Load pre-calculated objects
tar_load(plot_results)
tar_load(plot_diagnostics)

# Display in vignette
print(plot_results)
print(plot_diagnostics)
```

## Common Issues

### Tests fail locally but pass in IDE
→ Run `devtools::test()` in clean R session

### Check passes locally but fails on CI
→ Verify Nix environments match (same date in default.R)

### "Object not found" in tests
→ Use `devtools::load_all()` before testing interactively

### Documentation out of sync
→ Run `devtools::document()` after changing roxygen comments

### Vignette fails to build
→ Check all targets objects are available
→ Ensure code chunks don't have execution errors

## Complete Workflow Script Template

See `workflow-template.R` in this skill folder for a complete annotated template you can copy and customize.

## Resources

- **R Packages book**: https://r-pkgs.org/
- **devtools**: https://devtools.r-lib.org/
- **usethis**: https://usethis.r-lib.org/
- **testthat**: https://testthat.r-lib.org/
- **gert**: https://docs.ropensci.org/gert/
- **gh**: https://gh.r-lib.org/
- **targets**: https://docs.ropensci.org/targets/
