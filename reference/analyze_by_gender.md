# Analyze Statue Data by Gender

Performs gender analysis on statue subjects to compare representation of
men, women, and other subjects (animals, abstract concepts, etc.)

## Usage

``` r
analyze_by_gender(statue_data, gender_mapping = NULL)
```

## Arguments

- statue_data:

  Standardized statue data tibble

- gender_mapping:

  Optional named vector mapping subject names to genders

## Value

A list containing: - summary: tibble with gender counts and
percentages - by_source: gender breakdown by data source - top_subjects:
most frequently commemorated subjects - data: original data with
'inferred_gender' column

## Examples

``` r
if (FALSE) { # \dontrun{
all_statues <- get_all_statue_data()
gender_analysis <- analyze_by_gender(all_statues)
print(gender_analysis$summary)
} # }
```
