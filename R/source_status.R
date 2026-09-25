#' Fetch an optional data source, recording its status explicitly
#'
#' @description
#' Evaluates \code{expr} (a fetch such as \code{get_statues_glher()}). A
#' failure does not stop the pipeline but is recorded as
#' \code{"unavailable"} with its reason, so an optional source that cannot
#' be fetched is never mistaken for one that returned no records (#94).
#' Required sources (Wikidata, OSM) should be called directly so their
#' failures stop the pipeline.
#'
#' @param source Source name, e.g. \code{"glher"}.
#' @param expr Expression returning a data frame. Evaluated lazily inside
#'   this function so its error can be captured.
#'
#' @return A list with \code{data} (the fetched tibble, or a zero-row
#'   tibble when unavailable) and \code{status} (a one-row tibble:
#'   \code{source}, \code{status} one of "ok"/"empty"/"unavailable",
#'   \code{rows}, \code{reason}).
#' @export
fetch_optional_source <- function(source, expr) {
  result <- tryCatch(
    list(data = expr, reason = NA_character_),
    error = function(e) {
      list(data = tibble::tibble(), reason = conditionMessage(e))
    }
  )
  if (!is.na(result$reason)) {
    status <- tibble::tibble(source = source, status = "unavailable",
                             rows = 0L, reason = result$reason)
    cli::cli_inform(c("!" = "{source}: unavailable, recorded in source_status.",
                      "x" = "{result$reason}"))
  } else {
    status <- source_row(source, result$data)
  }
  list(data = result$data, status = status)
}

#' One-row status summary for a fetched source
#'
#' @param source Source name.
#' @param data The fetched data frame.
#' @return A one-row tibble: \code{source}, \code{status} ("ok" or
#'   "empty"), \code{rows}, \code{reason} (\code{NA}).
#' @export
source_row <- function(source, data) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{source}: fetch returned {.cls {class(data)}}, not a data frame.", call = NULL)
  }
  rows <- nrow(data)
  tibble::tibble(
    source = source,
    status = if (rows > 0) "ok" else "empty",
    rows = as.integer(rows),
    reason = NA_character_
  )
}

#' Should the optional GLHER fetch be re-run?
#'
#' Used as a \code{tar_cue_force()} condition: TRUE when no stored
#' \code{glher_fetch} exists or its status is anything but "ok", so an
#' "unavailable" or "empty" result is retried on the next \code{tar_make()}
#' rather than cached.
#'
#' @param store Path to the targets store.
#' @return Logical scalar.
#' @noRd
glher_needs_refetch <- function(store = targets::tar_config_get("store")) {
  prev <- tryCatch(targets::tar_read_raw("glher_fetch", store = store),
                   error = function(e) NULL)
  !identical(prev$status$status, "ok")
}
