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
most frequently commemorated subjects - top_names_by_gender: top 5 first
names for each gender - data: original data with 'inferred_gender'
column
