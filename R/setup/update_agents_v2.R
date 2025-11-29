# R/setup/update_agents_v2.R
# Purpose: Update Step 0 in AGENTS.md to mandate PLAN_what.md and PLAN_how.md

file_path <- "../context_claude.md" # The symlink target of AGENTS.md

# Read the file
content <- readLines(file_path)

# Define the search pattern (the start of Step 0)
start_pattern <- "### 5.0 Step 0: Project Initiation"

# Define the new content for Step 0
new_step_0 <- c(
  "### 5.0 Step 0: Project Initiation",
  "- **Plan Proposal (`PLAN_what.md`)**: Create a high-level plan file focusing on *what* will be achieved.",
  "  - **Objective**: Clear statement of goals.",
  "  - **Data Sources**: List of data sources.",
  "  - **Required R Packages**: A table grouped by highest-level purpose (e.g., Data Acquisition, Analysis), ordered alphanumerically within groups. Include a summary for each package.",
  "  - **Package List**: A single line listing all packages, comma-separated, quoted, and sorted alphanumerically.",
  "  - **Requires User Approval** before proceeding.",
  "",
  "- **Implementation Strategy (`PLAN_how.md`)**: Create a detailed strategy file focusing on *how* the plan will be implemented.",
  "  - **Implementation Details**: Specific functions, logic, file structures, and algorithms.",
  "  - **Requires User Approval** after `PLAN_what.md` is approved.",
  ""
)

# Find the start and end of the existing Step 0 section
start_idx <- which(content == start_pattern)

if (length(start_idx) == 1) {
  # Find the start of the next step (Step 1) to define the replacement range
  next_step_idx <- which(grepl("### 5.1 Step 1:", content))
  
  # Handle case where Step 1 might not be immediately following or not found (though it should be)
  if (length(next_step_idx) == 0) {
     # Fallback: replace 5 lines after start_idx (assuming old Step 0 was short)
     end_idx <- start_idx + 4 
  } else {
     end_idx <- next_step_idx - 1
  }

  # Construct new content
  new_content <- c(
    content[1:(start_idx - 1)],
    new_step_0,
    content[(end_idx + 1):length(content)]
  )
  
  # Write back to file
  writeLines(new_content, file_path)
  message("Successfully updated Step 0 in ", file_path)
} else {
  stop("Could not find the target section '", start_pattern, "' or found multiple matches.")
}
