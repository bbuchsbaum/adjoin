library(testthat)
library(Matrix)

test_that("graph_weights_fast returns valid sparse matrix (nanoflann)", {
  set.seed(1)
  X <- matrix(rnorm(200 * 10), nrow = 200)

  W <- graph_weights_fast(
    X, k = 10,
    weight_mode = "self_tuned",
    type = "normal",
    backend = "nanoflann"
  )

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(200, 200))
  expect_true(all(is.finite(W@x)))
  expect_true(all(diag(W) == 0))

  D <- W - Matrix::t(W)
  if (length(D@x)) {
    expect_lt(max(abs(D@x)), 1e-12)
  }

  expect_true(all(W@x >= 0))
  expect_true(all(W@x <= 1))
})

test_that("graph_weights_fast mutual graph is a subset of normal graph", {
  set.seed(2)
  X <- matrix(rnorm(300 * 8), nrow = 300)

  Wn <- graph_weights_fast(X, k = 12, weight_mode = "heat", type = "normal", backend = "nanoflann")
  Wm <- graph_weights_fast(X, k = 12, weight_mode = "heat", type = "mutual", backend = "nanoflann")

  expect_equal(dim(Wn), c(300, 300))
  expect_equal(dim(Wm), c(300, 300))
  expect_true(length(Wm@x) <= length(Wn@x))

  D <- Wm - Matrix::t(Wm)
  if (length(D@x)) {
    expect_lt(max(abs(D@x)), 1e-12)
  }
})

test_that("graph_weights_fast works with backend = hnsw when available", {
  skip_if_not_installed("RcppHNSW")

  set.seed(3)
  X <- matrix(rnorm(1000 * 16), nrow = 1000)

  W <- graph_weights_fast(
    X, k = 15,
    weight_mode = "self_tuned",
    type = "normal",
    backend = "hnsw",
    ef = 100
  )

  expect_equal(dim(W), c(1000, 1000))
  expect_true(all(is.finite(W@x)))
  expect_true(all(W@x >= 0))
})

# --- weight modes ---

test_that("graph_weights_fast binary weight mode", {
  set.seed(10)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "binary", backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(W@x >= 0))
  # binary weights should all be 0 or 1
  expect_true(all(W@x <= 1 + 1e-10))
})

test_that("graph_weights_fast euclidean weight mode", {
  set.seed(11)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "euclidean", backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(W@x >= 0))
  expect_true(all(is.finite(W@x)))
})

test_that("graph_weights_fast cosine weight mode", {
  set.seed(12)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "cosine", backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(is.finite(W@x)))
})

test_that("graph_weights_fast normalized weight mode", {
  set.seed(13)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "normalized", backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(is.finite(W@x)))
  expect_true(all(W@x >= 0))
})

test_that("graph_weights_fast normalized with explicit sigma", {
  set.seed(14)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "normalized",
                          sigma = 1.5, backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(is.finite(W@x)))
})

test_that("graph_weights_fast correlation weight mode", {
  set.seed(15)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "correlation", backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(is.finite(W@x)))
})

test_that("graph_weights_fast heat with explicit sigma skips auto-estimation", {
  set.seed(16)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "heat",
                          sigma = 0.5, backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  expect_true(all(W@x >= 0))
  expect_true(all(W@x <= 1 + 1e-10))
})

# --- symmetry types ---

test_that("graph_weights_fast asym type produces non-symmetric matrix", {
  set.seed(20)
  X <- matrix(rnorm(100), nrow = 20)
  W <- graph_weights_fast(X, k = 4, weight_mode = "heat",
                          type = "asym", backend = "nanoflann")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(20, 20))
  # asym does not force symmetry
  expect_true(all(is.finite(W@x)))
})

# --- backend ---

test_that("graph_weights_fast backend=auto resolves without error", {
  set.seed(21)
  X <- matrix(rnorm(60), nrow = 15)
  W <- graph_weights_fast(X, k = 3, weight_mode = "heat", backend = "auto")

  expect_true(inherits(W, "Matrix"))
  expect_equal(dim(W), c(15, 15))
})

# --- input validation errors ---

test_that("graph_weights_fast rejects k >= n", {
  X <- matrix(rnorm(20), nrow = 5)
  expect_error(graph_weights_fast(X, k = 5), "k.*must be between")
})

test_that("graph_weights_fast rejects local_k out of range", {
  X <- matrix(rnorm(60), nrow = 15)
  expect_error(graph_weights_fast(X, k = 5, local_k = 0), "local_k")
  expect_error(graph_weights_fast(X, k = 5, local_k = 10), "local_k")
})

test_that("graph_weights_fast rejects invalid sigma", {
  X <- matrix(rnorm(60), nrow = 15)
  expect_error(graph_weights_fast(X, k = 4, weight_mode = "heat", sigma = -1),
               "sigma.*positive scalar")
})

