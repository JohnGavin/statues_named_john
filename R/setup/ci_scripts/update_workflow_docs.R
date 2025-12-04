# R/setup/update_workflow_docs.R
# Purpose: Insert "Step 0: Project Initiation" into the mandatory workflow in ../context_claude.md

file_path <- "../context_claude.md"

# Read the file
content <- readLines(file_path)

# Define the search pattern (using fixed string matching for safety)
search_text <- "### 5.1 Step 1: Create GitHub Issue"

# Define the new content to insert
insertion_text <- c(
  "### 5.0 Step 0: Project Initiation",
  "- **Propose Plan**: Provide a bullet-point plan of the project/task. **Requires User Approval.**",
  "- **Implementation Strategy**: Provide a bullet-point summary of implementation details. **Requires User Approval.**",
  ""
)

# Find the line number
line_idx <- which(content == search_text)

if (length(line_idx) == 1) {
  # Insert the text before the found line
  new_content <- c(
    content[1:(line_idx - 1)],
    insertion_text,
    content[line_idx:length(content)]
  )
  
  # Write back to file
  writeLines(new_content, file_path)
  message("Successfully updated ", file_path)
} else if (length(line_idx) == 0) {
  stop("Could not find the target section: ", search_text)
} else {
  stop("Found multiple matches for the target section. Aborting to prevent errors.")
}
