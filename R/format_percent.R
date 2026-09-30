#' Format a percentage for display
#'
#' @description
#' The single place where displayed percentages are rounded (#102). Stored
#' values keep 2 decimal places; everything shown to readers (headline,
#' vignette text, table columns, plot labels) is rounded to the nearest
#' whole percent, with halves rounded up (12.5% -> "13%"). The label is
#' always computed from the raw counts, never from an already-rounded
#' percentage, so a value is never rounded twice.
#'
#' A non-zero share that would round to 0 is shown as "<1%", so a small
#' but real group (e.g. 7 of 2,301) is never displayed as "0%".
#'
#' @param count Numeric vector of counts.
#' @param total Numeric vector of totals (recycled against `count`).
#' @return Character vector such as "10%" or "<1%", or "n/a" when the
#'   total is missing or zero.
#' @export
#' @examples
#' format_percent(229, 2301)
#' format_percent(7, 2301)
format_percent <- function(count, total) {
  pct <- 100 * count / total
  out <- rep("n/a", length(pct))
  ok <- is.finite(pct)
  rounded <- floor(pct[ok] + 0.5)
  label <- sprintf("%.0f%%", rounded)
  label[rounded == 0 & pct[ok] > 0] <- "<1%"
  out[ok] <- label
  out
}
