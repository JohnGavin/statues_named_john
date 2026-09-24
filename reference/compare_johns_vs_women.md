# Compare John Statues vs Women Statues

Validates the "Statues for Equality" claim that there are more statues
named John than women in the UK.

## Usage

``` r
compare_johns_vs_women(statue_data)
```

## Arguments

- statue_data:

  Standardized statue data tibble

## Value

A list with comparison results: - total_statues, john_statues,
woman_statues, john_percent, woman_percent, claim_validated, message (as
before) - unknown_statues, unknown_percent: statues whose gender could
not be confidently classified (see classify_gender_from_subject()) -
gender_method: which classification sources were used, in priority order
(Wikidata P21, then the genderdata lookup cascade)
