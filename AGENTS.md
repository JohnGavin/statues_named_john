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
