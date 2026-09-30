#' Format a percentage for display
#'
#' @description
#' The single place where displayed percentages are rounded (#102). Stored
#' values keep 2 decimal places; everything shown to readers (headline,
#' vignette text, table columns, plot labels) is rounded to the nearest
#' whole percent. The label is always computed from the raw counts, never
#' from an already-rounded percentage, so a value is never rounded twice.
#'
#' @param count Numeric vector of counts.
#' @param total Numeric vector of totals (recycled against `count`).
#' @return Character vector such as "10%", or "n/a" when the total is
#'   missing or zero.
#' @export
#' @examples
#' format_percent(229, 2301)
format_percent <- function(count, total) {
  pct <- 100 * count / total
  ifelse(is.finite(pct), sprintf("%.0f%%", pct), "n/a")
}
