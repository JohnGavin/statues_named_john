# Analyze Statue Data by Gender

Performs gender analysis on statue subjects to compare representation of
men, women, and other subjects (animals, abstract concepts, etc.)

## Usage

``` r
analyze_by_gender(
  statue_data,
  gender_mapping = NULL,
  person_lookup = NULL,
  threshold = get_param("classification_threshold")
)
```

## Arguments

- statue_data:

  Standardized statue data tibble

- gender_mapping:

  Optional named vector mapping subject names to genders

- person_lookup:

  Optional tibble from \[lookup_wikidata_people()\] (`x`, `sex`,
  `confidence`) used for text such as "Statue of X".

- threshold:

  Minimum confidence to accept a gender; defaults to the single project
  setting `get_param("classification_threshold")`.

## Value

A list containing: - summary: tibble with gender counts and
percentages - by_source: gender breakdown by data source - top_subjects:
most frequently commemorated subjects - top_names_by_gender: top 5 first
names for each gender - data: original data with 'inferred_gender'
column
