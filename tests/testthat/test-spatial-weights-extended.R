library(testthat)
library(Matrix)

context("Spatial weights extended tests")

# ---------- spatial_adjacency extended ----------

test_that("spatial_adjacency with include_diagonal=FALSE", {
  coords <- matrix(c(0, 0, 1, 0, 0, 1, 1, 1), ncol = 2, byrow = TRUE)
  adj <- spatial_adjacency(coords, sigma = 1, nnk = 3, include_diagonal = FALSE)

  expect_equal(diag(as.matrix(adj)), rep(0, 4))
})

test_that("spatial_adjacency stochastic mode", {
  coords <- as.matrix(expand.grid(1:4, 1:4))
  adj <- spatial_adjacency(coords, sigma = 2, nnk = 8, stochastic = TRUE,
                           weight_mode = "heat", normalized = TRUE)

  # Rows should sum to approximately 1
  rs <- rowSums(adj)
  expect_true(all(abs(rs - 1) < 0.05))  # Tolerance for Sinkhorn convergence
})

test_that("spatial_adjacency handle_isolates keep_zero", {
  coords <- matrix(c(0, 0, 100, 100), ncol = 2, byrow = TRUE)
  adj <- spatial_adjacency(coords, sigma = 0.001, nnk = 1,
                           weight_mode = "heat", normalized = TRUE,
                           handle_isolates = "keep_zero")

  expect_equal(dim(adj), c(2, 2))
})

test_that("spatial_adjacency binary mode non-negative", {
  coords <- as.matrix(expand.grid(1:3, 1:3))
  adj <- spatial_adjacency(coords, weight_mode = "binary", nnk = 4, normalized = FALSE)

  expect_true(all(adj@x >= 0))
})

# ---------- cross_spatial_adjacency extended ----------

test_that("cross_spatial_adjacency normalized rows sum to ~1", {
  coords1 <- matrix(c(0, 0, 1, 0, 2, 0), ncol = 2, byrow = TRUE)
  coords2 <- matrix(c(0.5, 0, 1.5, 0, 2.5, 0, 3.5, 0), ncol = 2, byrow = TRUE)

  adj <- cross_spatial_adjacency(coords1, coords2, sigma = 2, nnk = 3, normalized = TRUE)

  expect_equal(nrow(adj), 3)
  expect_equal(ncol(adj), 4)
  rs <- rowSums(adj)
  expect_true(all(abs(rs - 1) < 1e-6 | rs == 0))
})

test_that("cross_spatial_adjacency unnormalized", {
  coords1 <- matrix(c(0, 0, 1, 0), ncol = 2, byrow = TRUE)
  coords2 <- matrix(c(0, 1, 1, 1), ncol = 2, byrow = TRUE)

  adj <- cross_spatial_adjacency(coords1, coords2, sigma = 2, nnk = 2, normalized = FALSE)

  expect_equal(nrow(adj), 2)
  expect_equal(ncol(adj), 2)
  expect_true(all(adj@x >= 0))
})

test_that("cross_spatial_adjacency with heat mode", {
  coords1 <- matrix(c(0, 0, 1, 0), ncol = 2, byrow = TRUE)
  coords2 <- matrix(c(0, 1, 1, 1), ncol = 2, byrow = TRUE)

  adj <- cross_spatial_adjacency(coords1, coords2, sigma = 2, nnk = 2,
                                  weight_mode = "heat", normalized = FALSE)

  expect_true(all(adj@x >= 0))
  expect_true(all(adj@x <= 1))
})

# ---------- normalize_adjacency extended ----------

test_that("normalize_adjacency handle_isolates drop", {
  sm <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(4, 4))

  result <- normalize_adjacency(sm, handle_isolates = "drop")

  # Isolated nodes 3 and 4 should be dropped

  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 2)
})

test_that("normalize_adjacency handle_isolates keep_zero", {
  sm <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(4, 4))

  result <- normalize_adjacency(sm, handle_isolates = "keep_zero")

  expect_equal(dim(result), c(4, 4))
  # Isolated nodes should have zero rows/columns
  expect_equal(sum(abs(result[3, ])), 0)
  expect_equal(sum(abs(result[4, ])), 0)
})

test_that("normalize_adjacency asymmetric=FALSE", {
  sm <- sparseMatrix(i = c(1, 1), j = c(2, 3), x = c(2, 3), dims = c(3, 3))

  result <- normalize_adjacency(sm, symmetric = FALSE)

  expect_equal(dim(result), c(3, 3))
})

# ---------- make_doubly_stochastic ----------

test_that("make_doubly_stochastic handles zero-row matrix", {
  A <- Matrix(0, nrow = 3, ncol = 3, sparse = TRUE)
  A[1, 2] <- 1
  A[2, 1] <- 1

  result <- make_doubly_stochastic(A)

  expect_equal(dim(result), c(3, 3))
  expect_true(all(is.finite(as.matrix(result))))
})

test_that("make_doubly_stochastic with dense input", {
  A <- matrix(c(1, 2, 2, 1), nrow = 2)
  result <- make_doubly_stochastic(A)

  expect_equal(dim(result), c(2, 2))
  rs <- rowSums(result)
  cs <- Matrix::colSums(result)
  expect_true(all(abs(rs - 1) < 1e-4))
  expect_true(all(abs(cs - 1) < 1e-4))
})

# ---------- spatial_smoother extended ----------

test_that("spatial_smoother handle_isolates keep_zero", {
  coords <- matrix(c(0, 0, 1, 0, 100, 100), ncol = 2, byrow = TRUE)
  result <- spatial_smoother(coords, sigma = 0.1, nnk = 2,
                             handle_isolates = "keep_zero")

  expect_equal(dim(result), c(3, 3))
})

test_that("spatial_smoother non-stochastic is symmetric", {
  coords <- as.matrix(expand.grid(1:3, 1:3))
  result <- spatial_smoother(coords, sigma = 2, nnk = 4, stochastic = FALSE)

  expect_true(Matrix::isSymmetric(result, tol = 1e-10))
})

# ---------- pairwise_adjacency ----------

test_that("pairwise_adjacency creates valid block matrix", {
  coords <- list(
    matrix(c(0, 0, 1, 0), ncol = 2, byrow = TRUE),
    matrix(c(0, 1, 1, 1), ncol = 2, byrow = TRUE)
  )
  feats <- list(
    matrix(rnorm(2), ncol = 1),
    matrix(rnorm(2), ncol = 1)
  )

  fself <- function(c, f) spatial_adjacency(c, normalized = FALSE, include_diagonal = FALSE)
  fbetween <- function(c1, c2, f1, f2) cross_spatial_adjacency(c1, c2, normalized = FALSE)

  M <- pairwise_adjacency(coords, feats, fself, fbetween)

  expect_true(inherits(M, "Matrix"))
  expect_equal(dim(M), c(4, 4))
})

test_that("pairwise_adjacency validates input lengths", {
  coords <- list(matrix(c(0, 0), ncol = 2))
  feats <- list(matrix(1, ncol = 1), matrix(2, ncol = 1))

  fself <- function(c, f) sparseMatrix(i = 1, j = 1, x = 0, dims = c(1, 1))
  fbetween <- function(c1, c2, f1, f2) sparseMatrix(i = 1, j = 1, x = 0, dims = c(1, 1))

  expect_error(pairwise_adjacency(coords, feats, fself, fbetween))
})

# ---------- spatial_laplacian extended ----------

test_that("spatial_laplacian binary mode", {
  coords <- as.matrix(expand.grid(1:3, 1:3))
  L <- spatial_laplacian(coords, dthresh = 2, nnk = 4, weight_mode = "binary")

  expect_true(inherits(L, "Matrix"))
  expect_equal(dim(L), c(9, 9))
  # Laplacian row sums should be ~0
  expect_true(all(abs(rowSums(L)) < 1e-8))
})

# ---------- cross_weighted_spatial_adjacency ----------

test_that("cross_weighted_spatial_adjacency returns valid matrix", {
  set.seed(42)
  coords <- as.matrix(expand.grid(1:3, 1:3))
  fmat1 <- matrix(rnorm(9 * 3), 9, 3)
  fmat2 <- matrix(rnorm(9 * 3), 9, 3)

  adj <- cross_weighted_spatial_adjacency(coords, coords, fmat1, fmat2,
                                          nnk = 4, sigma = 2, dthresh = 6)

  expect_true(inherits(adj, "Matrix"))
  expect_equal(dim(adj), c(9, 9))
  expect_true(all(adj@x >= 0))
})

# ---------- weighted_spatial_adjacency extended ----------

test_that("weighted_spatial_adjacency stochastic mode", {
  set.seed(42)
  coords <- as.matrix(expand.grid(1:3, 1:3))
  features <- matrix(rnorm(9 * 3), 9, 3)

  adj <- weighted_spatial_adjacency(coords, features, nnk = 4,
                                    weight_mode = "heat", sigma = 2,
                                    stochastic = TRUE)

  expect_true(inherits(adj, "Matrix"))
  rs <- rowSums(adj)
  expect_true(all(abs(rs - 1) < 0.1))
})

test_that("weighted_spatial_adjacency alpha=0 is purely feature-based", {
  set.seed(42)
  coords <- as.matrix(expand.grid(1:3, 1:3))
  features <- matrix(rnorm(9 * 3), 9, 3)

  adj0 <- weighted_spatial_adjacency(coords, features, alpha = 0,
                                     nnk = 4, sigma = 2)
  adj1 <- weighted_spatial_adjacency(coords, features, alpha = 1,
                                     nnk = 4, sigma = 2)

  # Different alpha should produce different results
  expect_false(all(as.matrix(adj0) == as.matrix(adj1)))
})

test_that("weighted_spatial_adjacency without diagonal", {
  set.seed(42)
  coords <- as.matrix(expand.grid(1:3, 1:3))
  features <- matrix(rnorm(9 * 3), 9, 3)

  adj <- weighted_spatial_adjacency(coords, features, nnk = 4, sigma = 2,
                                    include_diagonal = FALSE)

  expect_equal(diag(as.matrix(adj)), rep(0, 9))
})

# ---------- bilateral_smoother extended ----------

test_that("bilateral_smoother stochastic mode", {
  set.seed(42)
  coords <- as.matrix(expand.grid(1:3, 1:3))
  features <- matrix(rnorm(9 * 3), 9, 3)

  result <- bilateral_smoother(coords, features, s_sigma = 2, f_sigma = 1,
                               nnk = 4, stochastic = TRUE)

  expect_true(inherits(result, "Matrix"))
  expect_equal(dim(result), c(9, 9))
})
