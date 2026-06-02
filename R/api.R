# Low-level access to the dataseries.org API plus a simple in-memory cache.
#
# Everything fetched from the API (catalog, metadata, series) is cached by URL
# for the lifetime of the R session, so repeated calls are free. Use cache_rm()
# to force a fresh download.

env.cache <- new.env(parent = emptyenv())

cache_get <- function(key) {
  if (exists(key, envir = env.cache, inherits = FALSE)) {
    get(key, envir = env.cache, inherits = FALSE)
  } else {
    NULL
  }
}

cache_set <- function(key, value) {
  assign(key, value, envir = env.cache)
  invisible(value)
}

# GET a path and parse the JSON body. `simplify = FALSE` keeps the nested list
# structure (used for metadata); `TRUE` lets jsonlite simplify where it can.
ds_get_json <- function(path, simplify = FALSE, cache = TRUE) {
  url <- paste0(ds_api_url(), path)
  key <- paste0("json:", url)
  if (cache) {
    hit <- cache_get(key)
    if (!is.null(hit)) return(hit)
  }
  out <- tryCatch(
    jsonlite::fromJSON(url, simplifyVector = simplify),
    error = function(e) {
      stop("could not reach the dataseries.org API (", url, "): ",
           conditionMessage(e), call. = FALSE)
    }
  )
  if (cache) cache_set(key, out)
  out
}

# GET a /series.csv path and read it as a data.frame. All columns are read as
# character (dimension codes such as "100_100" must not be coerced to numbers);
# `date` and `value` are converted by the caller.
ds_get_csv <- function(path, cache = TRUE) {
  url <- paste0(ds_api_url(), path)
  key <- paste0("csv:", url)
  if (cache) {
    hit <- cache_get(key)
    if (!is.null(hit)) return(hit)
  }
  out <- tryCatch(
    utils::read.csv(url, stringsAsFactors = FALSE, colClasses = "character"),
    error = function(e) {
      stop("could not reach the dataseries.org API (", url, "): ",
           conditionMessage(e), call. = FALSE)
    }
  )
  if (cache) cache_set(key, out)
  out
}

#' List or clear the in-memory cache
#'
#' Everything downloaded from [dataseries.org](https://dataseries.org) is cached
#' in memory for the lifetime of the R session. `cache_ls()` lists the cached
#' objects (keyed by request URL); `cache_rm()` empties the cache, which forces
#' the next call to download fresh data.
#'
#' @return `cache_ls()` returns a character vector of cache keys; `cache_rm()`
#'   is called for its side effect and returns `NULL` invisibly.
#' @examples
#' \donttest{
#' ds_catalog()
#' cache_ls()
#' cache_rm()
#' }
#' @export
cache_ls <- function() {
  ls(envir = env.cache)
}

#' @rdname cache_ls
#' @export
cache_rm <- function() {
  rm(list = cache_ls(), envir = env.cache)
  invisible(NULL)
}
