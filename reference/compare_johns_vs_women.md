# Compare John Statues vs Women Statues

Validates the "Statues for Equality" claim that there are more statues
named John than women in the UK.

## Usage

``` r
compare_johns_vs_women(
  statue_data,
  person_lookup = NULL,
  threshold = get_param("classification_threshold")
)
```

## Arguments

- statue_data:

  Standardized statue data tibble

- person_lookup:

  Optional tibble from \[lookup_wikidata_people()\] (`x`, `sex`,
  `confidence`) used for text such as "Statue of X".

- threshold:

  Minimum confidence to accept a gender; defaults to the single project
  setting `get_param("classification_threshold")`.

## Value

A list with comparison results: - total_statues, john_statues,
woman_statues, john_percent, woman_percent, claim_validated, message.
`woman_statues` counts every statue that depicts a woman:
`woman_only_statues` (only women) plus `mixed_statues` (a woman together
with a man, e.g. "Queen Victoria and Prince Albert"). - unknown_statues,
unknown_percent: statues whose gender could not be confidently
classified (see classify_gender_from_subject()) - john_percent_label,
woman_percent_label, unknown_percent_label: whole-percent display text
from format_percent(). The numeric \*\_percent fields keep 2 decimal
places. - gender_method: which classification sources were used, in
priority order (Wikidata P21, title/term overrides, then the genderdata
lookup cascade when the gender and genderdata packages are available)
