# R/setup/audit_dependencies.R
# Audits if all packages in DESCRIPTION are present in default.R

# Read DESCRIPTION
d <- read.dcf("DESCRIPTION")
deps <- unique(trimws(unlist(strsplit(c(
  if("Imports" %in% colnames(d)) d[,"Imports"] else NULL, 
  if("Suggests" %in% colnames(d)) d[,"Suggests"] else NULL, 
  if("Depends" %in% colnames(d)) d[,"Depends"] else NULL
), ","))))
deps <- gsub("\\s*\\(.*\\)", "", deps)
deps <- deps[deps != "R"]

# Read default.R
# We look for the vector c(...) inside rix() call. 
# This is a bit hacky to parse text, but robust enough for this check.
default_r <- readLines("default.R")
# Extract lines containing package names (quoted strings inside c())
# This is just a heuristic check.
# Better: source default.R? No, it runs rix().
# We will just grep for the package names in default.R content.

missing <- c()
for (pkg in deps) {
  if (!any(grepl(paste0("\"", pkg, "\""), default_r))) {
    missing <- c(missing, pkg)
  }
}

if (length(missing) > 0) {
  message("❌ The following packages from DESCRIPTION are MISSING in default.R:")
  print(missing)
  stop("Dependency audit failed.")
} else {
  message("✅ All DESCRIPTION dependencies are present in default.R")
}