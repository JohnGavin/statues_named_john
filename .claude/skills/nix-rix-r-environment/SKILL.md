# Nix/Rix R Environment Setup

## Description

This skill helps set up and work within a reproducible R development environment using Nix and the rix R package. It ensures all R code executes within a properly configured Nix shell environment for maximum reproducibility.

## Purpose

Use this skill when:
- Starting a new R project that requires reproducible environments
- Working with R packages that need specific versions or dependencies
- Executing R code that must run in a controlled, reproducible environment
- Setting up GitHub Actions workflows that use Nix for CI/CD

## How It Works

1. **Environment Verification**: Confirms you're running in a Nix environment or helps you set one up
2. **Rix Package Setup**: Uses the rix R package to generate default.nix configuration files
3. **Bash Execution**: Ensures all commands run within the Nix shell for consistency
4. **R Package Tools**: Leverages gh, gert, and usethis R packages instead of CLI commands

## Key Principles

### Never Edit default.nix Manually
- Always edit the corresponding `default.R` file
- Use `source("default.R")` to regenerate `default.nix`
- This maintains reproducibility and documentation

### Execute All Code in Nix Shell
- Start Nix shell: `nix-shell /path/to/default.nix`
- Run R commands within this shell
- Use `NIXPKGS_ALLOW_BROKEN=1` if needed for packages marked as broken

### Use R Packages for Git/GitHub Operations
- **gert**: For git operations (add, commit, push, pull, status)
- **gh**: For GitHub API calls (issues, PRs, workflows)
- **usethis**: For PR workflow (pr_init, pr_push, pr_merge_main, pr_finish)
- Log all commands in `R/setup/` or `R/log/` for reproducibility

## Common Patterns

### Setting Up a New Project

```r
# 1. Create default.R file defining your environment
library(rix)

r_pkgs <- c("dplyr", "ggplot2", "devtools", "usethis", "gert", "gh")
system_pkgs <- c("git", "quarto", "pandoc")

rix(
  date = "2025-11-01",
  r_pkgs = r_pkgs,
  system_pkgs = system_pkgs,
  project_path = ".",
  overwrite = TRUE,
  ide = "none"
)

# 2. This generates default.nix
# 3. Enter the environment: nix-shell default.nix
# 4. Verify R is available: R --version
```

### Running R Commands in Nix Shell

```bash
# One-off command
NIXPKGS_ALLOW_BROKEN=1 nix-shell default.nix --run "Rscript my_script.R"

# Interactive session
NIXPKGS_ALLOW_BROKEN=1 nix-shell default.nix
# Now R is available with all packages
```

### Git Operations Using R Packages

```r
library(gert)

# Check status
gert::git_status()

# Stage files
gert::git_add(c("file1.R", "file2.R"))

# Commit
gert::git_commit("Fix issue #123")

# Push
gert::git_push()

# Check branch
gert::git_branch()
```

### GitHub Operations Using R Packages

```r
library(gh)

# List open issues
issues <- gh::gh("/repos/{owner}/{repo}/issues",
                 owner = "username",
                 repo = "reponame",
                 state = "open")

# Create PR
pr <- gh::gh("POST /repos/{owner}/{repo}/pulls",
             owner = "username",
             repo = "reponame",
             title = "Fix issue",
             body = "Description",
             head = "feature-branch",
             base = "main")

# Check workflow status
runs <- gh::gh("/repos/{owner}/{repo}/actions/runs",
               owner = "username",
               repo = "reponame",
               branch = "feature-branch")
```

### PR Workflow with usethis

```r
library(usethis)

# Start PR
usethis::pr_init("fix-issue-123")

# Make changes, commit locally with gert
# ...

# Push and create PR
usethis::pr_push()

# After GitHub Actions pass, merge
usethis::pr_merge_main()
usethis::pr_finish()
```

## File Structure

```
project/
├── default.R           # Edit this to define environment
├── default.nix         # Generated - DO NOT EDIT
├── R/
│   ├── your_code.R
│   ├── setup/
│   │   └── dev_log.R   # Log development commands
│   └── log/
│       └── git_gh.R    # Log git/GitHub commands
├── _targets.R          # Targets pipeline
└── .github/
    └── workflows/
        └── *.yaml      # Use Nix in CI
```

## GitHub Actions with Nix

Use rix to generate GitHub Actions workflows:

```r
library(rix)

# This will create .github/workflows/ files
rix_init(
  project_path = ".",
  rprofile_action = "create_missing",
  readme_action = "create_missing"
)
```

Example workflow snippet:
```yaml
- name: Install Nix
  uses: DeterminateSystems/nix-installer-action@main

- name: Setup Nix cache
  uses: DeterminateSystems/magic-nix-cache-action@main

- name: Run tests
  run: nix-shell default.nix --run "Rscript -e 'devtools::test()'"
```

## Troubleshooting

### Package marked as broken
```bash
export NIXPKGS_ALLOW_BROKEN=1
nix-shell default.nix
```

### Update R or package versions
1. Edit `default.R` (change date or package list)
2. Run `source("default.R")` to regenerate `default.nix`
3. Enter new shell: `nix-shell default.nix`

### Verify environment
```bash
nix-shell default.nix --run "R --version"
nix-shell default.nix --run "Rscript -e 'packageVersion(\"ggplot2\")'"
```

## Best Practices

1. **Always log commands**: Store reproducible R scripts in `R/setup/` or `R/log/`
2. **Version control**: Commit both `default.R` and `default.nix`
3. **Consistent environments**: Use same Nix date across local and CI
4. **Document dependencies**: Comment why specific packages are needed
5. **Test locally first**: Run all checks before pushing to GitHub

## Resources

- Rix package: https://github.com/ropensci/rix
- Rix documentation: https://docs.ropensci.org/rix/
- Example workflows: https://github.com/ropensci/rix/tree/main/.github/workflows
- Nix packages: https://search.nixos.org/packages

## Related Skills

- r-package-development
- targets-pipeline
- github-workflow-setup
