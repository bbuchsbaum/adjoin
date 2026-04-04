library(testthat)
library(Matrix)

context("Repulsion graph extended tests")

# ---------- repulsion_graph ----------

test_that("repulsion_graph from Matrix input", {
  set.seed(42)
  W <- rsparsematrix(10, 10, 0.3)
  W <- abs(W)
  W <- W + t(W)
  diag(W) <- 0

  labels <- factor(rep(1:2, each = 5))
  cg <- class_graph(labels)

  rg <- repulsion_graph(W, cg, method = "weighted")

  expect_true(inherits(rg, "repulsion_graph"))
  expect_true(inherits(rg, "neighbor_graph"))
  A <- adjacency(rg)
  expect_equal(dim(A), c(10, 10))
})

test_that("repulsion_graph from dense matrix input", {
  W <- matrix(runif(16), 4, 4)
  W <- (W + t(W)) / 2
  diag(W) <- 0

  labels <- factor(c(1, 1, 2, 2))
  cg <- class_graph(labels)

  rg <- repulsion_graph(W, cg, method = "binary")

  expect_true(inherits(rg, "repulsion_graph"))
  A <- adjacency(rg)
  # Binary: non-zero entries should be 1
  expect_true(all(A@x == 1))
})

test_that("repulsion_graph with threshold removes low-weight edges", {
  coords <- matrix(c(0, 0, 1, 0, 0, 1, 1, 1), ncol = 2, byrow = TRUE)
  W <- spatial_adjacency(coords, nnk = 3, sigma = 1, weight_mode = "heat",
                          normalized = FALSE, include_diagonal = FALSE)
  labels <- factor(c(1, 2, 1, 2))
  cg <- class_graph(labels)

  rg_nothresh <- repulsion_graph(W, cg, method = "weighted", threshold = 0)
  rg_thresh <- repulsion_graph(W, cg, method = "weighted", threshold = 0.5)

  A1 <- adjacency(rg_nothresh)
  A2 <- adjacency(rg_thresh)

  # Thresholded graph should have fewer or equal edges

  expect_true(sum(A2 != 0) <= sum(A1 != 0))
})

test_that("repulsion_graph with normalization factor", {
  coords <- matrix(c(0, 0, 1, 0, 0, 1, 1, 1), ncol = 2, byrow = TRUE)
  W <- spatial_adjacency(coords, nnk = 3, sigma = 1, weight_mode = "heat",
                          normalized = FALSE, include_diagonal = FALSE)
  labels <- factor(c(1, 2, 1, 2))
  cg <- class_graph(labels)

  rg_norm <- repulsion_graph(W, cg, method = "weighted", norm_fac = 2)
  rg_raw <- repulsion_graph(W, cg, method = "weighted", norm_fac = 1)

  A_norm <- adjacency(rg_norm)
  A_raw <- adjacency(rg_raw)

  # Normalized weights should be half of raw weights
  if (length(A_norm@x) > 0) {
    expect_true(all(abs(A_raw@x / 2 - A_norm@x) < 1e-10))
  }
})

test_that("repulsion_graph rejects zero norm_fac", {
  W <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(2, 2))
  labels <- factor(c(1, 2))
  cg <- class_graph(labels)

  expect_error(repulsion_graph(W, cg, method = "weighted", norm_fac = 0), "zero")
})

test_that("repulsion_graph rejects non-class_graph cg", {
  W <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(2, 2))
  expect_error(repulsion_graph(W, "not_a_cg"), "class_graph")
})

test_that("repulsion_graph rejects dimension mismatch", {
  W <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(3, 3))
  labels <- factor(c(1, 2))
  cg <- class_graph(labels)

  expect_error(repulsion_graph(W, cg), "Dimensions")
})

test_that("repulsion_graph stores parameters", {
  coords <- matrix(c(0, 0, 1, 0), ncol = 2, byrow = TRUE)
  W <- neighbor_graph(spatial_adjacency(coords, nnk = 2, sigma = 1))
  labels <- factor(c(1, 2))
  cg <- class_graph(labels)

  rg <- repulsion_graph(W, cg, method = "binary")

  expect_equal(rg$params$method, "binary")
  expect_true("threshold" %in% names(rg$params))
})

# ---------- print.repulsion_graph ----------

test_that("print.repulsion_graph runs without error", {
  coords <- matrix(c(0, 0, 1, 0), ncol = 2, byrow = TRUE)
  W <- neighbor_graph(spatial_adjacency(coords, nnk = 2, sigma = 1))
  labels <- factor(c(1, 2))
  cg <- class_graph(labels)

  rg <- repulsion_graph(W, cg, method = "weighted")

  expect_output(print(rg), "Repulsion")
})

test_that("print.repulsion_graph binary mode", {
  coords <- matrix(c(0, 0, 1, 0), ncol = 2, byrow = TRUE)
  W <- neighbor_graph(spatial_adjacency(coords, nnk = 2, sigma = 1))
  labels <- factor(c(1, 2))
  cg <- class_graph(labels)

  rg <- repulsion_graph(W, cg, method = "binary")

  expect_output(print(rg), "binary")
})

# ---------- new_repulsion_graph ----------

test_that("new_repulsion_graph creates valid object", {
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(3, 3))
  rg <- new_repulsion_graph(adj, params = list(method = "test"))

  expect_true(inherits(rg, "repulsion_graph"))
  expect_true(inherits(rg, "neighbor_graph"))
  expect_equal(rg$params$method, "test")
})

# ---------- repulse_weight (internal) ----------

test_that("repulse_weight returns non-negative value", {
  x1 <- c(1, 2, 3)
  x2 <- c(4, 5, 6)

  w <- adjoin:::repulse_weight(x1, x2)

  expect_true(is.numeric(w))
  expect_true(w >= 0)
  expect_true(is.finite(w))
})

test_that("repulse_weight handles zero vectors", {
  x1 <- c(0, 0, 0)
  x2 <- c(0, 0, 0)

  w <- adjoin:::repulse_weight(x1, x2)

  expect_equal(w, 0)
})

test_that("repulse_weight sigma parameter", {
  x1 <- c(1, 0)
  x2 <- c(0, 1)

  w1 <- adjoin:::repulse_weight(x1, x2, sigma = 1)
  w2 <- adjoin:::repulse_weight(x1, x2, sigma = 100)

  # Larger sigma should decrease the weight (more penalization)
  expect_true(w1 > w2)
})
