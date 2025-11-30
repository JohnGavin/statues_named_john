# AGENTS.md - Agent Guidelines for this Project

## 1. Vignette Standards

### File Format
*   **ALWAYS** use Quarto (`.qmd`) files for vignettes in preference to RMarkdown (`.Rmd`).
*   Ensure the YAML header output format is appropriate (e.g., `rmarkdown::html_vignette` or `quarto::html_document` depending on package setup).

### Content & Reproducibility
*   **Minimize R Code in Vignettes**: Vignettes should contain minimal R code.
*   **Use `targets`**: All data processing, analysis, and visualization generation must be done within the `targets` pipeline.
*   **Loading Results**: Vignettes should primarily consist of text and calls to `targets::tar_read()` or `targets::tar_load()` to display pre-computed objects (tables, plots, values).
*   **Rationale**: This ensures reproducibility and keeps the documentation clean and focused on the narrative.

## 2. Project Structure

### Targets Pipelines
*   **Location**: Store all `targets` pipeline plans in `R/tar_plans/`.
*   **Organization**: Each distinct analysis or vignette should have its own plan file (e.g., `R/tar_plans/plan_memorial_analysis.R`).
*   **Main `_targets.R`**: The root `_targets.R` file should source these plan files and combine them.

## 3. CI/CD & Caching

*   **Cachix**: The project uses a specific Cachix cache (`johngavin`) for storing package build artifacts.
*   **Workflows**: Ensure GitHub Actions workflows (like `R-CMD-check.yml`) are configured to push to `johngavin` and pull from `rstats-on-nix`.
*   **Cache Priority**: To ensure the fastest binary cache search, `rstats-on-nix` MUST be prioritized over the project-specific cache (`johngavin`).
    *   **Configuration Rule**: Set `name: rstats-on-nix` and `extraPullNames: johngavin` (or other project cache) in `cachix-action`. This ensures `rstats-on-nix` is checked first.
    *   **Example YAML**:
        ```yaml
        - name: Setup Cachix
          uses: cachix/cachix-action@v15
          with:
            name: rstats-on-nix          # Primary cache (checked first)
            extraPullNames: johngavin    # Secondary cache (checked next)
            authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
        ```

## 4. Documentation Management

When tidying up towards the end of each session, 
consider reducing the number of '*.md' files in ./R/setup/ 
by merging files and merging duplicated topics to produce fewer more detailed md files. 
Summarise the themes, topics and contents by similarity, and 
suggest which parts  might be better migrated to a 
wiki page on that topic or theme on the GH repo or to a FAQs wiki page and raise a GH issue for any outstanding issues/todo/features.
*   **Wiki FAQs**: Create and maintain a "FAQs" page on the GitHub Wiki documenting tasks logged in `./R/setup/`. Each entry should summarize the task and provide a direct link to the corresponding R script in the repository (e.g., link `R/setup/task_name.R` for `task_name`).
*   **README Maintenance**: The top-level `README.md` should be generated from `inst/qmd/README.qmd`. Any content updates should be made in the `.qmd` file and then rendered to `README.md` using Quarto (e.g., `quarto render inst/qmd/README.qmd --to gfm --output README.md`).

## 5. Version Control & GitHub Workflow

*   **R Packages over CLI**: ALWAYS prefer using R packages (`gert`, `gh`, `usethis`) for Git and GitHub operations instead of command-line tools (`git`, `gh`).
    *   Use `gert` for git operations (commit, push, branch, etc.).
    *   Use `gh` for GitHub API interactions (issues, PRs, releases).
    *   Use `usethis` for project setup and workflow automation (PR helpers).
*   **Log Operations**: All Git/GitHub operations performed via these R packages MUST be logged into reproducible R scripts within the `R/setup/` directory (e.g., `R/setup/create_pr_feature_x.R`). This ensures that the workflow is documented and can be audited or reproduced.

## 6. Website Verification

*   **Post-Merge Check**: After merging a PR, monitor the `pkgdown` workflow on the main branch.
*   **Verification Loop**: Check the website URL (e.g., `https://username.github.io/repo/`) every minute (timeout 5 mins) to confirm the update has been deployed successfully.

## 7. Package Dependency Verification

*   **Upon DESCRIPTION Update**: Whenever the `DESCRIPTION` file is updated (e.g., adding new `Imports` or `Suggests`), you MUST immediately verify that all listed packages are available in the current Nix shell environment.
*   **Verification Command**: Run the following command to attempt loading all dependencies:
    ```bash
    Rscript -e 'd <- read.dcf("DESCRIPTION"); pkgs <- unique(trimws(unlist(strsplit(c(if("Imports" %in% colnames(d)) d[,"Imports"] else NULL, if("Suggests" %in% colnames(d)) d[,"Suggests"] else NULL, if("Depends" %in% colnames(d)) d[,"Depends"] else NULL), ",")))); pkgs <- gsub("\\s*\\(.*\\)", "", pkgs); pkgs <- pkgs[pkgs != "R"]; missing <- pkgs[!sapply(pkgs, function(p) requireNamespace(p, quietly = TRUE))]; if(length(missing) > 0) { cat("Missing packages:", paste(missing, collapse = ", "), "\n"); quit(status = 1) } else { cat("All dependencies available.\n") }'
    ```
*   **Action on Failure**: If the verification fails (packages missing), do NOT proceed with implementation. Instead, **ask the user for advice** on how to update the Nix environment (e.g., updating `default.R` and regenerating `default.nix`).
