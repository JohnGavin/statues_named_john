# Agent Operational Notes: Reproducible R Session Management

## 1. Critical Change Summary: Persistent Nix Shell Requirement (2025-11-11)

Effective **2025-11-11**, Claude's operational skills have been updated to enforce the use of a **single persistent nix-shell** for executing all R commands across all projects. This change was documented in `.claude/skills/nix-rix-r-environment/SKILL.md` and `.claude/skills/r-package-workflow/SKILL.md`.

## 2. Key Requirements Enforced: Primary Objective - Reproducibility

The overarching goal of this mandate is to achieve true reproducibility for all R development workflows within Nix/rix environments.

### 2.1 Starting and Using the Persistent Nix Shell
* Check if you are already in a nix shell. If yes, assume all needed commands and R packages are available else stop and ask for help. 

* NB: you should never have to issue a nix-shell command as all the commands you need (e.g. R --quiet --no-save, Rscript, quarto) are avilable already on the command line. You can test for this at startup and stop and ask for help if there are any failuers.

*   **Execute All Commands Within:** ALL subsequent R commands and related operations for that project must be executed within this single shell instance. This includes:
    *   Running R scripts (`Rscript`).
    *   Interactive R sessions (`R`).
    *   Package development commands (`devtools::check()`, `devtools::test()`, `devtools::document()`).
    *   Website building (`pkgdown::build_site()`).
    *   Git/GitHub operations using R packages (`gert`, `gh`, `usethis`).
    *   `targets` pipeline execution.
    *   Any other R-related operations.

### 2.2 Why This Is Critical

Adhering to this principle ensures:
*   **Consistent Package Versions:** All operations benefit from a single, consistent set of package versions defined by the Nix environment.
*   **Shared R Session State:** Enables continuity of work and shared objects/data within the R session.
*   **Faster Execution:** Avoids repeated, time-consuming initialization of new Nix environments for individual commands.
*   **True Reproducibility:** Guarantees that the environment remains identical throughout the session, which is fundamental for reproducible research and development.
*   **Avoids Pitfalls:** New shell instances break reproducibility, as each may have a different state or slightly different package configurations.

### 2.3 Examples

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

## 3. Impact & Enforcement

This update establishes a mandatory reproducibility standard for all R development work using Nix/rix environments. Claude is programmed to adhere to this pattern for all R projects. Any deviation from this protocol would violate the core reproducibility objective.

This requirement is explicitly:
*   Marked with a warning emoji (⚠️).
*   Bolded as a **PRIMARY OBJECTIVE**.
*   Listed FIRST in the "Key Principles" sections of relevant skill documents.
*   Demonstrated with clear examples of correct and incorrect usage.
