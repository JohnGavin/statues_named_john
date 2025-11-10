# Quick Reference: Nix/Rix R Environment

## Essential Commands

### Setup
```bash
# 1. Create default.R (use setup-template.R)
# 2. Generate default.nix
Rscript -e "source('default.R')"

# 3. Enter nix shell
nix-shell default.nix

# 4. Or run single command
nix-shell default.nix --run "R --version"
```

### With Broken Packages
```bash
export NIXPKGS_ALLOW_BROKEN=1
nix-shell default.nix
```

## R Package Commands (NOT CLI)

### Git Operations (gert)
```r
library(gert)

# Status
gert::git_status()

# Add & Commit
gert::git_add("file.R")
gert::git_commit("message")

# Push & Pull
gert::git_push()
gert::git_pull()

# Branches
gert::git_branch()
gert::git_branch_create("new-branch")
gert::git_branch_checkout("main")
```

### GitHub Operations (gh)
```r
library(gh)

# Issues
gh::gh("/repos/{owner}/{repo}/issues",
       owner = "user", repo = "repo", state = "open")

# Create PR
gh::gh("POST /repos/{owner}/{repo}/pulls",
       owner = "user", repo = "repo",
       title = "Title", body = "Body",
       head = "branch", base = "main")

# Workflows
gh::gh("/repos/{owner}/{repo}/actions/runs",
       owner = "user", repo = "repo", branch = "main")
```

### PR Workflow (usethis)
```r
library(usethis)

# Start
usethis::pr_init("feature-name")

# Push
usethis::pr_push()

# Merge & Finish
usethis::pr_merge_main()
usethis::pr_finish()
```

## File Structure Rules

```
✅ DO:
- Edit default.R
- Run source("default.R") to regenerate default.nix
- Commit both files

❌ DON'T:
- Edit default.nix manually
- Use git/gh CLI commands (use R packages instead)
- Forget to log commands in R/setup/
```

## Common Issues

### "Package not found"
→ Add to `r_pkgs` in default.R, regenerate

### "nix-shell not found"
→ Install Nix: https://nixos.org/download

### "Package marked as broken"
→ Use `NIXPKGS_ALLOW_BROKEN=1`

### Tests fail on GitHub Actions
→ Check workflows use same Nix date as local

## Logging Pattern

```r
# R/setup/my_task.R
library(gert)
library(logger)

log_file <- "R/setup/my_task.log"
logger::log_appender(logger::appender_file(log_file))

logger::log_info("Starting task")
# ... do work ...
logger::log_info("Task complete")
```

## Full Workflow Example

```r
# 1. Start feature
library(usethis)
usethis::pr_init("fix-issue-123")

# 2. Make changes, document, test
devtools::document()
devtools::test()
devtools::check()

# 3. Commit (using gert, not CLI)
library(gert)
gert::git_add(c("R/myfile.R", "tests/test-myfile.R"))
gert::git_commit("Fix issue #123")

# 4. Push and create PR
usethis::pr_push()

# 5. Wait for CI, then merge
usethis::pr_merge_main()
usethis::pr_finish()
```

## Resources

- **Rix docs**: https://docs.ropensci.org/rix/
- **gert docs**: https://docs.ropensci.org/gert/
- **gh docs**: https://gh.r-lib.org/
- **usethis docs**: https://usethis.r-lib.org/
