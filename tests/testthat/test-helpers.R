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
  expect_equal(guess_frequency(seq(as.Date("2000-01-01"), by = "6 months", length.out = 24)), 2)
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

test_that("ds_label picks the requested language, falling back to English", {
  x <- list(en = "GDP", de = "BIP", fr = "PIB", it = "PIL")
  expect_equal(ds_label(x, "de"), "BIP")
  expect_equal(ds_label(x, "fr"), "PIB")
  expect_equal(ds_label(x, "it"), "PIL")
  # missing translation falls back to English, not to an arbitrary language
  expect_equal(ds_label(list(en = "GDP", fr = "PIB"), "de"), "GDP")
  # no English either: take what is there
  expect_equal(ds_label(list(fr = "PIB"), "de"), "PIB")
  expect_equal(ds_label("GDP", "de"), "GDP")
})

test_that("ds_check_lang accepts the four languages and rejects others", {
  for (l in c("en", "de", "fr", "it")) expect_equal(ds_check_lang(l), l)
  expect_error(ds_check_lang("es"), "must be one of")
  expect_error(ds_check_lang(c("de", "fr")), "must be one of")
  expect_error(ds_check_lang(1), "must be one of")
})

test_that("ds_topic_key takes the stable key, not the translated name", {
  expect_equal(
    ds_topic_key(list(key = "prices", name = list(en = "Prices", de = "Preise"))),
    "prices"
  )
  expect_equal(ds_topic_key("prices"), "prices")
  expect_true(is.na(ds_topic_key(NULL)))
  expect_true(is.na(ds_topic_key(list())))
})

test_that("ds_source_name follows the requested language", {
  src <- list(key = "seco", name = list(en = "SECO", de = "SECO (DE)"))
  expect_equal(ds_source_name(src), "SECO")
  expect_equal(ds_source_name(src, "de"), "SECO (DE)")
  expect_equal(ds_source_name("FSO"), "FSO")
  expect_true(is.na(ds_source_name(NULL)))
})

test_that("semi-annual data becomes a frequency-2 ts, not a gappy quarterly one", {
  # Surveyed in April and October: first half = period 1, second half = period 2
  dates <- as.Date(c("1998-10-01", "1999-04-01", "1999-10-01", "2000-04-01"))
  mat   <- matrix(c(78.7, 80.9, 81.2, 82), ncol = 1, dimnames = list(NULL, "x"))
  out   <- matrix_to_ts(mat, dates)
  expect_equal(frequency(out), 2)
  expect_equal(start(out), c(1998, 2))
  expect_equal(as.numeric(out), c(78.7, 80.9, 81.2, 82))
  expect_false(anyNA(out))

  # same via the frequency given by the dataset metadata
  expect_equal(matrix_to_ts(mat, dates, freq = 2), out)
  # a lone observation cannot be guessed, but the metadata frequency works
  one <- matrix_to_ts(mat[1, , drop = FALSE], dates[1], freq = 2)
  expect_equal(frequency(one), 2)
  expect_equal(start(one), c(1998, 2))
  expect_error(matrix_to_ts(mat[1, , drop = FALSE], dates[1]), "cannot represent")
})

test_that("freq_from_label maps the metadata frequency to a ts frequency", {
  expect_equal(freq_from_label("monthly"), 12)
  expect_equal(freq_from_label("quarterly"), 4)
  expect_equal(freq_from_label("semi-annual"), 2)
  expect_equal(freq_from_label("annual"), 1)
  expect_true(is.na(freq_from_label("daily")))
  expect_true(is.na(freq_from_label("weekly")))
  expect_true(is.na(freq_from_label(NULL)))
})

test_that("class = 'ts' uses the metadata frequency for semi-annual data", {
  csv <- paste("worktype,date,value",
               "total,1998-10-01,78.7", "total,1999-04-01,80.9",
               "total,1999-10-01,81.2", sep = "\n")
  local_mocked_bindings(
    ds_get_csv = function(path, cache = TRUE) read_series_csv(text = csv),
    ds_get_json = function(path, simplify = FALSE, cache = TRUE) {
      list(id = "ch_fso_construction_prices", frequency = "semi-annual")
    }
  )
  x <- ds("ch_fso_construction_prices", class = "ts")
  expect_equal(frequency(x), 2)
  expect_equal(start(x), c(1998, 2))
  expect_equal(as.numeric(x), c(78.7, 80.9, 81.2))
})
