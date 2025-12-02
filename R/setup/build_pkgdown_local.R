#!/usr/bin/env Rscript
# Build pkgdown site locally (Nix environment workaround)
# Issue: pkgdown/bslib copies read-only files from /nix/store
# Solution: Delete docs/ before every build to avoid permission errors

cat("\n=== Building pkgdown site (with Nix workaround) ===\n\n")

# Step 1: Remove docs/ directory if it exists (to clear read-only files)
if (dir.exists("docs")) {
  cat("Removing existing docs/ directory (contains read-only Nix store files)...\n")
  unlink("docs", recursive = TRUE, force = TRUE)
  cat("✓ docs/ removed\n\n")
} else {
  cat("ℹ docs/ doesn't exist (clean slate)\n\n")
}

# Step 2: Build pkgdown site
cat("Building pkgdown site...\n")
result <- tryCatch({
  pkgdown::build_site()
  TRUE
}, error = function(e) {
  cat("\n❌ Build failed:\n")
  cat(conditionMessage(e), "\n")
  FALSE
})

# Step 3: Check for read-only files that will cause next build to fail
if (dir.exists("docs")) {
  readonly_files <- list.files("docs",
                               pattern = "\\.(js|css|map)$",
                               recursive = TRUE,
                               full.names = TRUE)

  if (length(readonly_files) > 0) {
    # Check first file's permissions
    first_file_info <- file.info(readonly_files[1])
    is_readonly <- !(first_file_info$mode & 0200)  # Check write bit

    if (is_readonly) {
      cat("\n⚠️  WARNING: docs/ contains read-only files from Nix store\n")
      cat("   Next build will fail unless docs/ is deleted first\n")
      cat("   Run this script again or manually: rm -rf docs/\n\n")
    }
  }
}

# Step 4: Report result
if (result) {
  cat("\n✅ Build completed successfully\n")
  cat("   View site: open docs/index.html\n")
} else {
  cat("\n❌ Build failed - see errors above\n")
  quit(status = 1)
}
