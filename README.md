# londonremembers

<!-- badges: start -->
[![R-CMD-check](https://github.com/yourusername/statues_named_john/workflows/R-CMD-check/badge.svg)](https://github.com/yourusername/statues_named_john/actions)
[![codecov](https://codecov.io/gh/yourusername/statues_named_john/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/statues_named_john)
<!-- badges: end -->

An R package for accessing and analyzing memorial data from [London Remembers](https://www.londonremembers.com/).

## Installation

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("yourusername/londonremembers")
```

## Features

- Scrape memorial data from London Remembers website
- Access memorials by type, category, and location
- Search for specific subjects and memorials
- Analyze patterns in London's commemorative landscape

## Usage

```r
library(londonremembers)

# Get latest memorials
memorials <- get_memorials_latest(pages = 2)

# Search for specific subjects
johns <- search_memorials("John")

# Get subjects by category
subjects <- get_subjects_by_category("Literature")
```

## Vignettes

See the vignette for a comparative analysis of memorials:
```r
vignette("memorial-analysis", package = "londonremembers")
```

## License

MIT
