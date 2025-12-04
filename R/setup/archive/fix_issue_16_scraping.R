
# R/setup/fix_issue_16_scraping.R
# Date: 2025-11-29
# Issue: #16 - Strategy: Scraping JavaScript-Rendered Content
# Objective: Update CSS selectors in R/memorials.R to match current website structure,
#            enabling static scraping for list pages (get_memorials_latest and search_memorials).

# 1. Create development branch (already done by agent)
# usethis::pr_init("fix-issue-16-scraping-selectors")

# 2. Modify R/memorials.R (applying changes below)
#    - Update item selector from ".memorial-item, .item" to ".memorial.card"
#    - Update title_elem selector from "h3 a, h2 a, .title a, a.memorial-link" to "h2 a"
#    - Update location_elem selector from ".location, .address" to "h3"
#    - For memorial_type and subjects in list views, they are not directly available,
#      so existing selectors might return NA. This is acceptable for list view.

# 3. Log commands for verification (run after modification)
# devtools::load_all()
# testthat::test_file("tests/testthat/test-memorials.R")
