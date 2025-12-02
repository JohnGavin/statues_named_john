# R/tar_plans/documentation_plan.R
# Targets plan for vignette rendering and pkgdown site building
#
# This creates a dependency chain:
#   Data targets → Vignette HTML → pkgdown site
#
# Benefits:
# - Vignettes automatically re-render when data changes
# - pkgdown automatically rebuilds when vignettes change
# - All managed through targets DAG
# - No manual commits of HTML needed (CI handles it)

documentation_plan <- list(
  # ── Vignette Rendering ────────────────────────────────────────────────

  # Render memorial-analysis vignette to HTML
  # Depends on: all_memorials, gender_analysis, johns_comparison (from memorial_analysis_plan)
  tar_target(
    vignette_memorial_analysis_html,
    {
      # Ensure output directory exists
      dir.create("inst/doc", recursive = TRUE, showWarnings = FALSE)

      # Render vignette with Quarto
      # This runs OUTSIDE pkgdown, so Nix + Quarto + bslib work fine
      quarto::quarto_render(
        input = "vignettes/memorial-analysis.qmd",
        output_file = "memorial-analysis.html",
        output_dir = "inst/doc",
        quiet = FALSE,
        execute_dir = "project"  # Execute in project root where targets are available
      )

      # Return path to generated HTML
      normalizePath("inst/doc/memorial-analysis.html")
    },
    format = "file",
    # Explicitly depend on data targets the vignette uses
    # targets will re-render vignette when these change
    cue = tar_cue(
      mode = "always",  # Always check dependencies
      depend = TRUE     # Re-run if dependencies change
    )
  ),

  # ── Vignette Metadata ─────────────────────────────────────────────────

  # Track vignette source files
  # If .qmd changes, vignette target will re-run
  tar_target(
    vignette_sources,
    list.files("vignettes", pattern = "\\.qmd$", full.names = TRUE),
    format = "file"
  ),

  # ── pkgdown Site Building ─────────────────────────────────────────────

  # Build pkgdown site
  # Depends on: vignette HTML files
  tar_target(
    pkgdown_site,
    {
      # Ensure vignettes are rendered first (explicit dependency)
      stopifnot(file.exists(vignette_memorial_analysis_html))

      # Clean docs/ directory to avoid permission issues
      if (dir.exists("docs")) {
        message("Removing docs/ directory")
        unlink("docs", recursive = TRUE)
      }

      # Build site
      # pkgdown will use pre-built HTML from inst/doc/
      message("Building pkgdown site with pre-built vignettes")
      pkgdown::build_site(
        pkg = ".",
        preview = FALSE,
        install = FALSE,
        new_process = FALSE  # Run in same process for targets compatibility
      )

      # Return docs/ directory
      "docs"
    },
    format = "file",
    cue = tar_cue(
      mode = "always",
      depend = TRUE
    )
  ),

  # ── Site Verification ─────────────────────────────────────────────────

  # Verify pkgdown site was built successfully
  tar_target(
    pkgdown_verification,
    {
      # Check key files exist
      required_files <- c(
        "docs/index.html",
        "docs/reference/index.html",
        "docs/articles/index.html",
        "docs/articles/memorial-analysis.html"
      )

      missing <- required_files[!file.exists(required_files)]

      if (length(missing) > 0) {
        stop("pkgdown build incomplete. Missing files:\n  ",
             paste(missing, collapse = "\n  "))
      }

      message("✅ pkgdown site built successfully")
      message("📄 Articles: ", length(list.files("docs/articles", pattern = "\\.html$")))
      message("📚 Reference: ", length(list.files("docs/reference", pattern = "\\.html$")))

      TRUE
    }
  )
)
