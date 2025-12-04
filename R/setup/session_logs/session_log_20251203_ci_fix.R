# CI Logic Fix Update
# -------------------
# The pkgdown workflow required an explicit split between dependency installation
# and local package installation to avoid internal pak errors with the local source.
#
# Fix applied in .github/workflows/pkgdown.yml:
# 1. Setup R dependencies: packages: any::pkgdown, any::remotes, deps::.
# 2. Install local package: remotes::install_local(".", dependencies = FALSE, force = TRUE)
#
# This bypassed the 'pak' solver crash and allowed the build to proceed.