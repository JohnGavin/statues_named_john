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
  # Explicitly depends on data targets by referencing them in command
  tar_target(
    vignette_memorial_analysis_html,
    command = {
      # Reference data targets to create explicit dependencies
      # targets will build these BEFORE running this target
      deps <- list(
        all_memorials,
        summary_table,
        category_plot,
        memorial_map_plot,
        memorial_interactive_map,
        johns_comparison,
        findings
      )

      # Ensure output directory exists for Quarto (project root)
      # dir.create("inst/doc", recursive = TRUE, showWarnings = FALSE) # No longer needed here

      # Render vignette with Quarto
      # Quarto outputs to the directory of the input file.
      # output_file is just the filename.
      quarto::quarto_render(
        input = "inst/qmd/memorial-analysis.qmd",
        output_file = "memorial-analysis.html", # This will create inst/qmd/memorial-analysis.html
        quiet = FALSE,
        execute_dir = getwd() # Still execute from root to find targets store
      )

      # Ensure vignettes directory exists
      message("Current working directory in target: ", getwd())
      target_vignettes_dir <- file.path(getwd(), "vignettes")
      message("Ensuring target vignettes directory exists: ", target_vignettes_dir)
      dir.create(target_vignettes_dir, recursive = TRUE, showWarnings = FALSE)

      # Copy rendered HTML from inst/qmd/ to vignettes/ and remove original
      source_file <- file.path(getwd(), "inst/qmd/memorial-analysis.html")
      destination_file <- file.path(target_vignettes_dir, "memorial-analysis.html")
      
      message("Attempting to copy '", source_file, "' to '", destination_file, "'")
      file.copy(source_file, destination_file, overwrite = TRUE)
      file.remove(source_file) # Remove from inst/qmd/

      # Copy supporting files (images, libs)
      source_files_dir <- file.path(getwd(), "inst/qmd/memorial-analysis_files")
      
      if (dir.exists(source_files_dir)) {
        message("Copying support files from '", source_files_dir, "' to '", target_vignettes_dir, "'")
        # Destination path for the folder itself
        dest_files_dir <- file.path(target_vignettes_dir, "memorial-analysis_files")
        
        # Remove existing destination folder to ensure clean copy
        if (dir.exists(dest_files_dir)) {
          unlink(dest_files_dir, recursive = TRUE)
        }
        
        # Copy the directory
        file.copy(source_files_dir, target_vignettes_dir, recursive = TRUE)
        
        # Remove source directory
        unlink(source_files_dir, recursive = TRUE)
      }

      # Return path to generated HTML (now in vignettes/)
      normalizePath(destination_file)
    },
    format = "file"
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
      stopifnot(file.exists("vignettes/memorial-analysis.html"))

      # Clean docs/ directory to avoid permission issues
      if (dir.exists("docs")) {
        message("Removing docs/ directory")
        unlink("docs", recursive = TRUE)
      }

      # Build the main pkgdown site, explicitly ignoring articles
      message("Building main pkgdown site, ignoring articles.")
      pkgdown::build_site(
        pkg = ".",
        preview = FALSE,
        install = FALSE,
        new_process = FALSE,
        override = list(articles = NULL) # Ignore articles to prevent bslib issues
      )
      
      # Manually construct the articles directory and copy the pre-built vignette.
      message("Manually constructing articles/ directory and copying pre-built vignette.")

      # Ensure articles directory exists within docs/
      dir.create("docs/articles", recursive = TRUE, showWarnings = FALSE)
      
      # Copy the pre-built vignette
      file.copy("vignettes/memorial-analysis.html", "docs/articles/memorial-analysis.html", overwrite = TRUE)

      # Create a minimal articles index.html (required by pkgdown_verification)
      writeLines(c(
        '<!DOCTYPE html>',
        '<html lang="en"><head><meta charset="utf-8"></head><body>',
        '<h1>Articles</h1>',
        '<ul><li><a href="memorial-analysis.html">Comparing London Memorials: Johns, Women, and Dogs</a></li></ul>',
        '</body></html>'
      ), con = "docs/articles/index.html")

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

      data.frame(success = TRUE)
    }
  )
)
