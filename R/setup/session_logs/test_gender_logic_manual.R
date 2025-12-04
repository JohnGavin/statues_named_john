
library(dplyr)
library(stringr)
library(purrr)
library(tibble)

source("R/utils.R") # for clean_text if needed
source("R/analyze_statues.R")

# Mock data
dummy_data <- tibble::tibble(
  subject = c("Queen Victoria", "King George", "John Smith", "Unknown Person", "Alice Wonderland"),
  name = c("Victoria", "George", "John", "Unknown", "Alice"),
  subject_gender = c("female", "male", NA, NA, NA),
  type = "person",
  source = "test"
)

# analyze_by_gender calls extract_first_names which is in the same file.

# Run analysis
# We need to mock classify_gender_from_subject dependencies? No, it uses standard pkgs.

result <- analyze_by_gender(dummy_data)

print(result$summary)
print(result$data$inferred_gender)

if (result$data$inferred_gender[5] == "Unknown") {
  message("Graceful degradation confirmed: Alice remains Unknown without gender package.")
}
