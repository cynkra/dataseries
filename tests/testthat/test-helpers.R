# Offline unit tests for the pure helpers (no network).

test_that("build_dims renders the dims grammar", {
  expect_equal(build_dims(list()), "")
  expect_equal(build_dims(list(item = "100_100")), "item=100_100")
  expect_equal(
    build_dims(list(type = "real", structure = c("gdp", "gva"))),
    "type=real;structure=gdp,gva"
  )
})

test_that("build_dims rejects unnamed filters", {
  expect_error(build_dims(list("real")), "must be named")
  expect_error(build_dims(list(type = "real", "x")), "must be named")
})

test_that("guess_frequency classifies common spacings", {
  expect_equal(guess_frequency(seq(as.Date("2000-01-01"), by = "month", length.out = 24)), 12)
  expect_equal(guess_frequency(seq(as.Date("2000-01-01"), by = "3 months", length.out = 24)), 4)
  expect_equal(guess_frequency(seq(as.Date("2000-01-01"), by = "year", length.out = 24)), 1)
  expect_true(is.na(guess_frequency(seq(as.Date("2000-01-01"), by = "day", length.out = 24))))
  expect_true(is.na(guess_frequency(as.Date("2000-01-01"))))
})

test_that("matrix_to_ts fills gaps onto a regular grid", {
  dates <- as.Date(c("2000-01-01", "2000-02-01", "2000-04-01")) # March missing
  mat   <- matrix(c(1, 2, 4), ncol = 1, dimnames = list(NULL, "x"))
  out   <- matrix_to_ts(mat, dates)
  expect_s3_class(out, "ts")
  expect_equal(frequency(out), 12)
  expect_equal(as.numeric(out), c(1, 2, NA, 4))
  expect_equal(start(out), c(2000, 1))
})

test_that("%||% coalesces absent values", {
  expect_equal("a" %||% "b", "a")
  expect_equal(NULL %||% "b", "b")
  expect_equal("" %||% "b", "b")
  expect_equal(character(0) %||% "b", "b")
})

test_that("ds_label prefers English and tolerates plain strings", {
  expect_equal(ds_label(list(en = "GDP", de = "BIP")), "GDP")
  expect_equal(ds_label(list(de = "BIP")), "BIP")
  expect_equal(ds_label("GDP"), "GDP")
  expect_true(is.na(ds_label(NULL)))
})
