# Live tests against the dataseries.org API. Skipped on CRAN and when offline.

skip_api <- function() {
  skip_on_cran()
  skip_if_offline("api.dataseries.org")
}

test_that("ds_catalog() returns a populated catalog", {
  skip_api()
  cat <- ds_catalog()
  expect_s3_class(cat, "data.frame")
  expect_true(nrow(cat) > 0)
  expect_true(all(c("id", "title", "frequency", "n_series") %in% names(cat)))
  expect_true("ch_fso_cpi" %in% cat$id)
})

test_that("ds_search() returns a flat series list and filters by pattern", {
  skip_api()
  all <- ds_search()
  expect_s3_class(all, "data.frame")
  expect_true(nrow(all) > 0)
  expect_true(all(c("dataset", "dim", "code", "label", "frequency") %in% names(all)))

  hits <- ds_search("price")
  expect_true(nrow(hits) > 0)
  expect_true(nrow(hits) < nrow(all))
  expect_true(all(
    grepl("price", hits$label, ignore.case = TRUE) |
    grepl("price", hits$dataset_title, ignore.case = TRUE)
  ))
})

test_that("ds() returns a long data.frame with typed columns", {
  skip_api()
  x <- ds("ch_fso_cpi", item = "100_100", from = "2024-01-01")
  expect_s3_class(x, "data.frame")
  expect_true(all(c("item", "date", "value") %in% names(x)))
  expect_s3_class(x$date, "Date")
  expect_type(x$value, "double")
  expect_true(all(x$item == "100_100"))
})

test_that("ds() accepts dims as named args or a named list", {
  skip_api()
  by_args <- ds("ch_fso_cpi", item = "100_100", from = "2024-01-01")
  by_list <- ds("ch_fso_cpi", list(item = "100_100"), from = "2024-01-01")
  expect_equal(by_args, by_list)
})

test_that("ds() selects a single cell from a multi-dim cube", {
  skip_api()
  g <- ds("ch_seco_gdp", type = "real", structure = "gdp", seas_adj = "csa",
          from = "2020-01-01")
  expect_true(nrow(g) > 0)
  expect_true(all(g$type == "real" & g$structure == "gdp" & g$seas_adj == "csa"))
})

test_that("ds() returns ts objects, one column per series", {
  skip_api()
  ts_obj <- ds("ch_fso_cpi", item = "100_100", from = "2020-01-01", class = "ts")
  expect_s3_class(ts_obj, "ts")
  expect_equal(frequency(ts_obj), 12)

  mts_obj <- ds("ch_fso_cpi", item = c("100_100", "100_1"),
                from = "2020-01-01", class = "ts")
  expect_s3_class(mts_obj, "ts")
  expect_equal(ncol(mts_obj), 2L)
})

test_that("ds_meta() exposes dimensions and a clear error for unknown ids", {
  skip_api()
  m <- ds_meta("ch_seco_gdp")
  expect_true("type" %in% unlist(m$dim_order))
  expect_true(length(m$dimensions$type$levels) > 0)
  expect_error(ds_meta("no_such_dataset"), "unknown dataset")
})
