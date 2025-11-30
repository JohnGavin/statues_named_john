# Agent Guidelines: Internal Workflow & Reproducibility Standards

This document consolidates internal guidelines for agent operation within R development projects, emphasizing reproducibility standards, persistent Nix shell usage, and workflow management.

---

## 1. Reproducible R Session Management: Persistent Nix Shell Requirement

**Effective Date:** 2025-11-11

The primary objective for all R development workflows within Nix/rix environments is **true reproducibility**. This is achieved by enforcing the use of a **single persistent nix-shell** for executing all R commands across all projects.

### 1.1 Starting and Using the Persistent Nix Shell

*   Always verify you are in a nix shell. All necessary commands and R packages should be available.
*   **Execute All Commands Within:** ALL subsequent R commands and related operations for that project must be executed within this single shell instance. This includes:
    *   Running R scripts (`Rscript`).
    *   Interactive R sessions (`R`).
    *   Package development commands (`devtools::check()`, `devtools::test()`, `devtools::document()`).
    *   Website building (`pkgdown::build_site()`).
    *   Git/GitHub operations using R packages (`gert`, `gh`, `usethis`).
    *   `targets` pipeline execution.
    *   Any other R-related operations.

### 1.2 Why This Is Critical

Adhering to this principle ensures:
*   **Consistent Package Versions:** All operations benefit from a single, consistent set of package versions defined by the Nix environment.
*   **Shared R Session State:** Enables continuity of work and shared objects/data within the R session.
*   **Faster Execution:** Avoids repeated, time-consuming initialization of new Nix environments for individual commands.
*   **True Reproducibility:** Guarantees that the environment remains identical throughout the session, which is fundamental for reproducible research and development.
*   **Avoids Pitfalls:** New shell instances break reproducibility, as each may have a different state or slightly different package configurations.

### 1.3 Examples

*   **❌ WRONG Approach (Do NOT Do This)**: Launching new `nix-shell` instances for individual commands breaks reproducibility.
    ```bash
    # Creates new environment each time - breaks reproducibility
    nix-shell --run "Rscript script1.R"
    nix-shell --run "Rscript script2.R"
    nix-shell --run "Rscript script3.R"
    ```
*   **✅ CORRECT Approach (Always Do This)**: Execute all commands within the single persistent shell.
    ```bash
    # Then execute all commands in that shell:
    Rscript script1.R
    Rscript script2.R
    Rscript script3.R
    ```

### 1.4 Impact & Enforcement

This establishes a mandatory reproducibility standard for all R development work using Nix/rix environments. Any deviation violates the core reproducibility objective. This requirement is explicitly marked with warnings, bolded as a PRIMARY OBJECTIVE, and demonstrated with clear examples.

---

## 2. Session Summaries & Workflow Management

This section consolidates notes and summaries from past sessions related to workflow management and PR creation.

### 2.1 Session Summary (2025-11-11) - Completed Tasks

*   **Answered Data Dimensions Question**: Clarified `londonremembers.com` scraping limitations (JavaScript rendering) and demonstration data usage in vignette.
*   **PR Creation Using R Packages**: Documented creation of PR #5 (`check_pr_status.R`, `create_pr.R`, logs).
*   **Workflow Management Scripts Created**: `check_workflows.R` for monitoring GitHub Actions.

### 2.2 Reproducibility Principle

**CRITICAL**: Never launch new `nix-shell` instances for individual commands. Always use the single persistent shell for:
-   Running R scripts
-   Interactive R sessions
-   Package development commands (devtools::check, etc.)
-   Git operations via R packages (gert, gh, usethis)

This ensures: Consistent package versions, shared R session state, faster execution, and true reproducibility.

### 2.3 Claude Skills Updated

Both `.claude/skills/nix-rix-r-environment/SKILL.md` and `.claude/skills/r-package-workflow/SKILL.md` were updated with the CRITICAL persistent nix shell requirement, establishing it as a PRIMARY OBJECTIVE for all R projects.
