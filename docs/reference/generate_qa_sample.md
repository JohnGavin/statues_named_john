# Generate QA Sample for Manual Validation

Selects a random sample of statue records that require manual
validation, focusing on 'Unknown' genders, potential errors, or missing
metadata.

## Usage

``` r
generate_qa_sample(statue_data, sample_size = 50, output_path = NULL)
```

## Arguments

- statue_data:

  The standardized statue data tibble

- sample_size:

  Number of records to sample (default: 50)

- output_path:

  Optional path to save the CSV (default: NULL)

## Value

A tibble containing the sample
