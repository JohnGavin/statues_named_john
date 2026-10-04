# Target source code for the vignette (#81).
#
# The vignette shows pipeline results via tar_read(), so "Show code" used to
# reveal only the object name. target_commands() reads each tar_target()
# command from the plan files, exactly as written there, so the vignette can
# show the code that produced each result without copying it.

#' Read the command of every target defined in plan files
#'
#' @description
#' Parses each plan file and returns the command of every
#' \code{tar_target()} call, as written in the file (comments and layout
#' kept), with the line it starts on. The only change is to indentation:
#' the whitespace its later lines share is removed, up to the width of the
#' text before the command on its first line, so code inside \code{\{} and
#' arguments aligned under a call both keep their relative layout. Lines
#' inside multi-line strings are left untouched.
#'
#' @param files Paths to plan files, e.g.
#'   \code{list.files("R/tar_plans", full.names = TRUE)}.
#' @return A data frame with columns \code{name}, \code{command},
#'   \code{file} and \code{line}, one row per target.
#' @export
#' @examples
#' plan <- tempfile(fileext = ".R")
#' writeLines(c(
#'   "plan <- list(",
#'   "  tar_target(x, 1 + 1),",
#'   "  tar_target(y, {",
#'   "    x * 2  # double it",
#'   "  })",
#'   ")"
#' ), plan)
#' target_commands(plan)
target_commands <- function(files) {
  rows <- lapply(files, target_commands_one)
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    out <- data.frame(name = character(0), command = character(0),
                      file = character(0), line = integer(0))
  }
  dups <- unique(out$name[duplicated(out$name)])
  if (length(dups) > 0) {
    cli::cli_abort("Target{?s} defined more than once: {.val {dups}}.", call = NULL)
  }
  out
}

target_commands_one <- function(file) {
  exprs <- parse(file, keep.source = TRUE)
  pd <- utils::getParseData(exprs, includeText = TRUE)
  src <- readLines(file, warn = FALSE)
  # Lines that continue a multi-line string: their leading whitespace is
  # part of the string, so dedent() must not touch it (#108).
  strs <- pd[pd$token == "STR_CONST" & pd$line2 > pd$line1, ]
  in_string <- unlist(Map(function(a, b) seq(a + 1, b), strs$line1, strs$line2))
  # Each tar_target() call: the call expression is the grandparent of the
  # SYMBOL_FUNCTION_CALL token (token -> function-name expr -> call expr).
  fn_tokens <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text == "tar_target", ]
  calls <- pd$parent[match(fn_tokens$parent, pd$id)]
  rows <- lapply(calls, function(call_id) {
    kids <- pd[pd$parent == call_id, ]
    kids <- kids[order(kids$line1, kids$col1), ]
    args <- call_args(kids)
    named <- args$name != ""
    positional <- args$id[!named]
    name_id <- if ("name" %in% args$name) args$id[args$name == "name"] else positional[1]
    cmd_id <- if ("command" %in% args$name) args$id[args$name == "command"] else positional[2]
    if (is.na(name_id) || is.na(cmd_id)) {
      cli::cli_abort("Cannot read a tar_target() call in {.path {file}}.", call = NULL)
    }
    cmd_row <- pd[pd$id == cmd_id, ]
    keep <- seq(cmd_row$line1 + 1, length.out = cmd_row$line2 - cmd_row$line1) %in% in_string
    data.frame(
      name = utils::getParseText(pd, name_id),
      command = dedent(utils::getParseText(pd, cmd_id),
                       cap = chars_before_col(src[cmd_row$line1], cmd_row$col1),
                       keep = keep),
      file = file,
      line = cmd_row$line1
    )
  })
  do.call(rbind, rows)
}

# Arguments of a call from its child tokens: each argument is an expr,
# optionally preceded by SYMBOL_SUB (its name) and EQ_SUB.
call_args <- function(kids) {
  ids <- integer(0)
  nms <- character(0)
  pending <- ""
  after_fn <- FALSE
  for (i in seq_len(nrow(kids))) {
    tok <- kids$token[i]
    if (tok == "'('") {
      after_fn <- TRUE
    } else if (!after_fn) {
      next
    } else if (tok == "SYMBOL_SUB") {
      pending <- kids$text[i]
    } else if (tok == "expr") {
      ids <- c(ids, kids$id[i])
      nms <- c(nms, pending)
      pending <- ""
    }
  }
  data.frame(id = ids, name = nms)
}

# Number of characters before parse-data column `col` on `line`. R's parser
# counts a tab as advancing to the next multiple of 8, so columns and
# characters differ on tab-indented lines.
chars_before_col <- function(line, col) {
  chars <- strsplit(line, "")[[1]]
  column <- 0L
  for (i in seq_along(chars)) {
    if (column + 1L >= col) {
      return(i - 1L)
    }
    column <- if (chars[i] == "\t") (column %/% 8L + 1L) * 8L else column + 1L
  }
  length(chars)
}

# Remove the indentation the command had in its plan file. The parse text
# of the first line has none; later lines carry their source indentation.
# Strip the whitespace they share, but never more characters than stood
# before the command on its first line (`cap`): that keeps a body inside
# `{` relative to the line, and an argument aligned under its call still
# aligned (#110). Leading whitespace is compared as literal characters, so
# tabs work. Lines flagged in `keep` are inside a multi-line string and are
# left exactly as written (#108); other whitespace-only lines become empty.
dedent <- function(text, cap, keep = logical(0)) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  if (length(lines) < 2) {
    return(text)
  }
  rest <- lines[-1]
  keep <- rep_len(c(keep, logical(length(rest))), length(rest))
  code <- !keep & grepl("\\S", rest)
  lead <- sub("^([ \t]*).*$", "\\1", rest[code])
  common <- if (length(lead) > 0) Reduce(common_prefix, lead) else ""
  n <- min(nchar(common), cap)
  rest[code] <- substring(rest[code], n + 1)
  rest[!keep & !grepl("\\S", rest)] <- ""
  paste(c(lines[1], rest), collapse = "\n")
}

common_prefix <- function(a, b) {
  x <- strsplit(a, "")[[1]]
  y <- strsplit(b, "")[[1]]
  n <- 0L
  while (n < min(length(x), length(y)) && x[n + 1] == y[n + 1]) {
    n <- n + 1L
  }
  substr(a, 1, n)
}

#' Markdown blocks showing the code of pipeline targets
#'
#' @description
#' For each target, a collapsed "Show code" block holding its command and a
#' link to where it is defined. A vignette prints one with
#' \code{cat(blocks[["target_name"]])} in a chunk with \code{results: asis}.
#'
#' @param code Data frame from \code{target_commands()}.
#' @param repo_url Base URL for links to the plan files, or \code{NULL} for
#'   no links. Links point at \code{main} on purpose (#108): line numbers
#'   come from the working tree at render time, and the re-rendered
#'   vignette is committed together with the plan edit, so the deployed
#'   site (built from \code{main}) links to the right lines. Pinning the
#'   current commit SHA instead would point at the commit before the edit.
#'   Links from a branch render match only once that branch is merged.
#' @return Named character vector of markdown, one element per target.
#' @export
target_code_markdown <- function(code,
                                 repo_url = "https://github.com/JohnGavin/statues_named_john/blob/main") {
  where <- sprintf("%s#L%d", code$file, code$line)
  if (!is.null(repo_url)) {
    where <- sprintf("[%s](%s/%s)", where, repo_url, where)
  }
  md <- paste0(
    "\n<details><summary>Show code for target <code>", code$name, "</code></summary>\n\n",
    "Defined in ", where, ":\n\n",
    "```r\n", code$command, "\n```\n\n",
    "</details>\n\n"
  )
  stats::setNames(md, code$name)
}
