## Duplication Summary for Top-Level .md Files

The content of the following top-level .md files has been largely superseded or incorporated into the new consolidated documentation within `R/setup/`.

### 1. `PLAN_how.md`
*   **Duplication:** Its high-level implementation strategy and function updates are now fully detailed and superseded by `R/setup/PROJECT_PLAN.md` and `R/setup/PROJECT_IMPLEMENTATION.md`. The specific details regarding `httr::GET` with raw SPARQL (to avoid `WikidataQueryServiceR` dependency) are outdated, as specialized packages are confirmed available.
*   **Recommendation:** This file now contains redundant information and can be deleted if `R/setup/PROJECT_PLAN.md` is considered the single source of truth for planning.

### 2. `PLAN_what.md`
*   **Duplication:** Its objective, proposed data sources, high-level plan, and required R packages are now fully incorporated into `R/setup/PROJECT_PLAN.md`.
*   **Recommendation:** This file now contains redundant information and can be deleted if `R/setup/PROJECT_PLAN.md` is considered the single source of truth for planning.

### 3. `prompt_statues.md`
*   **Duplication:** The core project requirements, vignette details, analysis comparisons (Johns vs Women vs Dogs), data points, and primary/secondary source considerations are now comprehensively captured in `R/setup/PROJECT_PLAN.md`.
*   **Recommendation:** This file now contains redundant information and can be deleted if `R/setup/PROJECT_PLAN.md` is considered the single source of truth for project requirements.

### 4. `prompt.md`
*   **Duplication:** This appears to be an older, less detailed version of `prompt_statues.md`. Its content regarding project goals and vignette comparisons is fully superseded by `R/setup/PROJECT_PLAN.md`.
*   **Recommendation:** This file now contains redundant information and can be deleted.

### 5. `README.md` (Top-Level)
*   **Duplication:** The description of the package, original data source (originally `londonremembers.com` scraping), installation instructions, features, usage examples, and vignette link are now largely covered by the context in `R/setup/PROJECT_PLAN.md` (for strategy). The main `README.md` requires an update to reflect the multi-source API strategy and current installation/usage.
*   **Recommendation:** Update this file to align with the new project direction, possibly generating it from a `.qmd` file as per `AGENTS.md` guidelines. The `AGENTS.md` guidelines state: "README.md should be derived from ./inst/qmd/README.qmd". This implies the current `README.md` should eventually be replaced by a generated one.

### 6. `SESSION_PACKAGE_REVIEW_2025-11-29.md`
*   **Duplication:** This file contains a package review for JavaScript scraping (`chromote`, `hayalbas`, `RSelenium`) and vignette UX (`bslib`, `downlit`). While the core data acquisition strategy has shifted, the discussion of these packages and vignette UX remains relevant for specific tasks.
*   **Recommendation:** The specific details about `chromote` (for potential future JS scraping) and vignette UX packages could be summarized in a new "Development Notes" or "Feature Backlog" document, or migrated to a GitHub Wiki page under a "Technical Decisions" or "Package Evaluation" section. It is not directly duplicated in the new `R/setup` files, but its context regarding JS scraping is no longer a primary strategy.

## GitHub Wiki Migration Suggestions

Based on the consolidated documentation, here are suggestions for content that could be migrated or summarized on GitHub Wiki pages to keep the repository's primary documentation focused and concise:

### 1. **Project FAQs / Troubleshooting**
*   **Content:** The "Troubleshooting" section from the newly created `R/setup/QUICK_START_GUIDE.md` (API failures, package checks).
*   **Why:** Provides quick answers and solutions for users or new contributors without cluttering core documentation.

### 2. **Technical Decisions / Historical Context**
*   **Content:** The `R/setup/TECHNICAL_JOURNAL.md` (Nix package availability blocker and its resolution). Summaries or key learnings from this.
*   **Why:** Captures the rationale behind major technical choices and challenges, which is valuable for future maintenance or similar projects, but might be too detailed for a quick overview.

### 3. **Agent Operational Guidelines**
*   **Content:** `R/setup/AGENT_OPERATIONAL_NOTES.md` (mandatory reproducibility standards and persistent Nix shell requirements for Claude's operation).
*   **Why:** This is crucial for agent consistency but is not directly about the R package's functionality for an end-user. It's better suited for internal documentation or a dedicated agent-guidelines wiki page.

### 4. **Future Work / Research Backlog**
*   **Content:** The "Next Steps After Implementation" from `R/setup/PROJECT_IMPLEMENTATION.md`, and "Next Steps & Future Enhancements" from `R/setup/PROJECT_STATUS_HISTORY.md`. This could also include a summary from `SESSION_PACKAGE_REVIEW_2025-11-29.md` about `chromote` if JS scraping is deemed a future feature to investigate.
*   **Why:** Provides a roadmap for the project, tracking potential expansions and further research, keeping the main documentation focused on the current release.

### 5. **Data Source Evaluation Details**
*   **Content:** More in-depth comparisons or evaluation criteria for various data sources (from the original `R/setup/data_sources_research.md` and `R/setup/art_uk_research.md`) beyond what's in `R/setup/PROJECT_PLAN.md`.
*   **Why:** Useful background for understanding data acquisition choices without overburdening the core project plan.
