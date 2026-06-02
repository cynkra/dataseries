# Small internal helpers shared across the package.

# Null/empty coalesce. Treats NULL, length-0 and "" as "absent".
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || (is.character(x) && all(!nzchar(x)))) y else x
}

# Base URL of the dataseries.org API. Override for testing or self-hosting via
# the `dataseries.api` option or the `DATASERIES_API` environment variable.
ds_api_url <- function() {
  getOption(
    "dataseries.api",
    Sys.getenv("DATASERIES_API", "https://api.dataseries.org")
  )
}

# Pick a label from a translated map (e.g. list(en = "GDP")), preferring English.
# Passes a bare string through; returns NA for an absent value.
ds_label <- function(x) {
  if (is.null(x) || length(x) == 0L) return(NA_character_)
  if (is.list(x)) return(as.character(x$en %||% x[[1]]))
  as.character(x)
}

# Several catalog fields are a string when meaningful and an empty object {}
# (decoded as an empty list) when absent. Collapse both to a scalar or NA.
ds_scalar <- function(x) {
  if (is.null(x) || length(x) == 0L || is.list(x)) return(NA_character_)
  as.character(x)[1]
}

# `source` is a plain string in the catalog but a {name, url} object in a meta.
ds_source_name <- function(x) {
  if (is.null(x)) return(NA_character_)
  if (is.list(x)) return(ds_label(x$name))
  as.character(x)
}
