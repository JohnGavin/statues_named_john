# R/setup/update_agents_plan_how.R
# Purpose: Update PLAN_how.md description in AGENTS.md

file_path <- "../context_claude.md" 

# Read the file
content <- readLines(file_path)

# Define the search pattern for the line to modify
search_pattern <- "- **Implementation Strategy (`PLAN_how.md`)**: Create a detailed strategy file focusing on *how* the plan will be implemented."
details_line_pattern <- "  - **Implementation Details**: Specific functions, logic, file structures, and algorithms."

# Define the new content to insert for the summary
summary_instruction <- "  - **Summary**: Start with a concise bullet-point summary of the implementation approach."

# Find the line index of the search pattern
strategy_line_idx <- which(grepl(search_pattern, content, fixed = TRUE))
details_line_idx <- which(grepl(details_line_pattern, content, fixed = TRUE))

if (length(strategy_line_idx) == 1 && length(details_line_idx) == 1 && details_line_idx > strategy_line_idx) {
  
  # Insert the summary instruction right after the main strategy line
  new_content <- c(
    content[1:strategy_line_idx],
    summary_instruction,
    content[(strategy_line_idx + 1):length(content)]
  )
  
  # Re-calculate index for details line in new_content
  details_line_idx_new <- which(grepl(details_line_pattern, new_content, fixed = TRUE))

  message("Successfully updated PLAN_how.md instructions in ", file_path)
} else {
  stop("Could not find the target section for PLAN_how.md or found multiple matches. Aborting.")
}

writeLines(new_content, file_path)
