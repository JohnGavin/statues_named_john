
library(dplyr)
library(ggplot2)
library(stringr)
library(purrr)
library(tibble)

source("R/analyze_statues.R")

# Mock data with clear Male/Female candidates
dummy_data <- tibble::tibble(
  subject = c("Queen Victoria", "King George", "John Smith", "Unknown Person", "Alice Wonderland", "Dog"),
  name = c("Victoria", "George", "John", "Unknown", "Alice", "Fido"),
  subject_gender = c("Female", "Male", NA, NA, NA, NA),
  type = c("person", "person", "person", "person", "person", "animal"),
  source = "test"
)

result <- analyze_by_gender(dummy_data)
print("Summary Table:")
print(result$summary)

# Generate plot object
p <- ggplot(result$summary, aes(x = inferred_gender, y = n, fill = inferred_gender)) +
  geom_col()

print("Plot layers:")
print(p$layers)

# Check if Male is in the summary
if ("Male" %in% result$summary$inferred_gender) {
  message("Male category IS present in the summary.")
} else {
  message("Male category IS MISSING from the summary.")
}
