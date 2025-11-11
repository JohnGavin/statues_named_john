#!/usr/bin/env Rscript
# Setup GitHub Pages for the repository
# This script enables GitHub Pages and configures it to serve from gh-pages branch

library(httr)

# Get GitHub token from environment
github_token <- Sys.getenv("GITHUB_TOKEN")
if (github_token == "") {
  stop("GITHUB_TOKEN environment variable not set")
}

# Repository details
owner <- "JohnGavin"
repo <- "statues_named_john"

# API endpoint
url <- sprintf("https://api.github.com/repos/%s/%s/pages", owner, repo)

# Check if Pages already exists
message("Checking if GitHub Pages is already enabled...")
check_response <- GET(
  url,
  add_headers(
    Authorization = paste("Bearer", github_token),
    Accept = "application/vnd.github+json",
    `X-GitHub-Api-Version` = "2022-11-28"
  )
)

if (status_code(check_response) == 200) {
  message("GitHub Pages is already enabled!")
  pages_info <- content(check_response)
  message(sprintf("Site URL: %s", pages_info$html_url))
  message(sprintf("Status: %s", pages_info$status))
} else if (status_code(check_response) == 404) {
  message("GitHub Pages not found. Enabling now...")

  # Enable GitHub Pages
  response <- POST(
    url,
    add_headers(
      Authorization = paste("Bearer", github_token),
      Accept = "application/vnd.github+json",
      `X-GitHub-Api-Version` = "2022-11-28"
    ),
    body = list(
      source = list(
        branch = "gh-pages",
        path = "/"
      )
    ),
    encode = "json"
  )

  if (status_code(response) %in% c(201, 204)) {
    message("✓ GitHub Pages enabled successfully!")
    pages_info <- content(response)
    message(sprintf("Site URL: %s", pages_info$html_url))
    message("Note: It may take a few minutes for the site to become available.")
  } else {
    message(sprintf("✗ Failed to enable GitHub Pages. Status: %d", status_code(response)))
    message("Response:")
    print(content(response))
  }
} else {
  message(sprintf("Unexpected status code: %d", status_code(check_response)))
  print(content(check_response))
}
