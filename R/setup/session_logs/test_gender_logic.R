
# Test gender logic syntax
# Since 'gender' package is missing in this session, this tests the graceful degradation.

devtools::load_all()

# Mock data
dummy_data <- tibble::tibble(
  subject = c("Queen Victoria", "King George", "John Smith", "Unknown Person", "Alice Wonderland"),
  name = c("Victoria", "George", "John", "Unknown", "Alice"),
  subject_gender = c("female", "male", NA, NA, NA),
  type = "person",
  source = "test"
)

# Run analysis
result <- analyze_by_gender(dummy_data)

print(result$summary)
print(result$data$inferred_gender)

# Expected:
# Victoria -> Female (heuristic)
# George -> Male (heuristic)
# John -> Male (heuristic)
# Unknown -> Unknown (heuristic -> fallback skipped)
# Alice -> Unknown (heuristic fails, fallback skipped)

if (result$data$inferred_gender[5] == "Unknown") {
  message("Graceful degradation confirmed: Alice remains Unknown without gender package.")
} else {
  message("Unexpected result for Alice: ", result$data$inferred_gender[5])
}
