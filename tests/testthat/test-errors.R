# Offline tests for error messages (the request layer is mocked).

fake_meta <- list(
  id = "ch_fso_construction_prices",
  dim_order = list("worktype"),
  dimensions = list(worktype = list(levels = list(
    total = list(), hochbau = list(), tiefbau = list()
  )))
)

# A dataseries.org that is up: metadata for one dataset, HTTP errors on bad
# /series.csv requests (as read.csv() sees them), unknown datasets in the meta.
mock_api_up <- function(code = parent.frame()) {
  local_mocked_bindings(
    ds_get_csv = function(path, cache = TRUE) {
      stop(ds_request_error(paste0("https://x", path),
                            "HTTP status was '400 Bad Request'"))
    },
    ds_get_json = function(path, simplify = FALSE, cache = TRUE) {
      if (grepl("ch_fso_construction_prices", path)) fake_meta
      else list(error = "unknown dataset")
    },
    .env = code
  )
}

test_that("an unknown dataset is reported as such, not as a network problem", {
  mock_api_up()
  expect_error(ds("ch_nope"), "unknown dataset: 'ch_nope'.*ds_catalog")
  expect_no_match(tryCatch(ds("ch_nope"), error = conditionMessage),
                  "could not reach")
})

test_that("an unknown dimension lists the valid ones", {
  mock_api_up()
  expect_error(
    ds("ch_fso_construction_prices", item = "x"),
    "unknown dimension 'item'.*Valid dimensions: worktype"
  )
})

test_that("an unknown code lists the valid ones", {
  mock_api_up()
  expect_error(
    ds("ch_fso_construction_prices", worktype = c("total", "nope")),
    "unknown code 'nope' for dimension 'worktype'.*Valid codes: total, hochbau, tiefbau"
  )
})

test_that("a rejected request with valid inputs still names the API", {
  mock_api_up()
  expect_error(
    ds("ch_fso_construction_prices", worktype = "total"),
    "API rejected the request.*400"
  )
})

test_that("'could not reach' is kept for real network failures", {
  down <- function(path, ...) stop(ds_request_error(path, "no internet"))
  local_mocked_bindings(ds_get_csv = down, ds_get_json = down)
  expect_error(ds("ch_fso_construction_prices"), "could not reach the dataseries.org API")
  expect_error(ds_meta("ch_fso_construction_prices"), "could not reach")
})
