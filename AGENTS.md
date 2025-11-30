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

## 4. Documentation Management

When tidying up towards the end of each session, 
consider reducing the number of '*.md' files in ./R/setup/ 
by merging files and merging duplicated topics to produce fewer more detailed md files. 
Summarise the themes, topics and contents by similarity, and 
suggest which parts  might be better migrated to a 
wiki page on that topic or theme on the GH repo or to a FAQs wiki page and raise a GH issue for any outstanding issues/todo/features.
*   **Wiki FAQs**: Create and maintain a "FAQs" page on the GitHub Wiki documenting tasks logged in `./R/setup/`. Each entry should summarize the task and provide a direct link to the corresponding R script in the repository (e.g., link `R/setup/task_name.R` for `task_name`).

## 5. Version Control & GitHub Workflow

*   **R Packages over CLI**: ALWAYS prefer using R packages (`gert`, `gh`, `usethis`) for Git and GitHub operations instead of command-line tools (`git`, `gh`).
    *   Use `gert` for git operations (commit, push, branch, etc.).
    *   Use `gh` for GitHub API interactions (issues, PRs, releases).
    *   Use `usethis` for project setup and workflow automation (PR helpers).
*   **Log Operations**: All Git/GitHub operations performed via these R packages MUST be logged into reproducible R scripts within the `R/setup/` directory (e.g., `R/setup/create_pr_feature_x.R`). This ensures that the workflow is documented and can be audited or reproduced.

## 6. Website Verification

*   **Post-Merge Check**: After merging a PR, monitor the `pkgdown` workflow on the main branch.
*   **Verification Loop**: Check the website URL (e.g., `https://username.github.io/repo/`) every minute (timeout 5 mins) to confirm the update has been deployed successfully.
