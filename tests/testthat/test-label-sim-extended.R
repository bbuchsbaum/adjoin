library(testthat)
library(Matrix)

context("Label similarity extended tests")

# ---------- diagonal_label_matrix ----------

test_that("diagonal_label_matrix type='s' returns correct diagonal", {
  a <- factor(c("x", "y", "x"))
  b <- factor(c("x", "x", "x"))

  result <- diagonal_label_matrix(a, b, type = "s")
  mat <- as.matrix(result)

  # Position 1: x==x -> 1, Position 2: y!=x -> 0, Position 3: x==x -> 1
  expect_equal(mat[1, 1], 1)
  expect_equal(mat[2, 2], 0)
  expect_equal(mat[3, 3], 1)

  # Off-diagonal should be 0
  expect_equal(sum(mat) - sum(diag(mat)), 0)
})

test_that("diagonal_label_matrix type='d' returns correct diagonal", {
  a <- factor(c("x", "y", "x"))
  b <- factor(c("x", "x", "x"))

  result <- diagonal_label_matrix(a, b, type = "d")
  mat <- as.matrix(result)

  expect_equal(mat[1, 1], 0)
  expect_equal(mat[2, 2], 1)  # y != x
  expect_equal(mat[3, 3], 0)
})

test_that("diagonal_label_matrix with custom dims", {
  a <- factor(c("x", "y"))
  b <- factor(c("x", "x"))

  result <- diagonal_label_matrix(a, b, type = "s", dim1 = 5, dim2 = 5)

  expect_equal(dim(result), c(5, 5))
})

test_that("diagonal_label_matrix warns on different lengths", {
  a <- factor(c("x", "y", "z"))
  b <- factor(c("x", "y"))

  expect_warning(diagonal_label_matrix(a, b), "different lengths")
})

# ---------- diagonal_label_matrix_na ----------

test_that("diagonal_label_matrix_na handles NAs in same-label comparison", {
  a <- c("x", "y", NA, "x")
  b <- c("x", "y", "y", NA)

  result <- diagonal_label_matrix_na(a, b, type = "s")
  mat <- as.matrix(result)

  # Position 1: x==x -> 1
  expect_equal(mat[1, 1], 1)
  # Position 2: y==y -> 1
  expect_equal(mat[2, 2], 1)
  # Position 3: NA -> excluded
  expect_equal(mat[3, 3], 0)
  # Position 4: NA -> excluded
  expect_equal(mat[4, 4], 0)
})

test_that("diagonal_label_matrix_na handles NAs in different-label comparison", {
  # Use factors with consistent levels to ensure correct comparison
  a <- factor(c("x", "y", NA), levels = c("x", "y"))
  b <- factor(c("y", "y", "y"), levels = c("x", "y"))

  result <- diagonal_label_matrix_na(a, b, type = "d")
  mat <- as.matrix(result)

  # Position 1: x!=y -> 1
  expect_equal(mat[1, 1], 1)
  # Position 2: y==y -> 0
  expect_equal(mat[2, 2], 0)
  # Position 3: NA -> excluded
  expect_equal(mat[3, 3], 0)
})

test_that("diagonal_label_matrix_na return_matrix=FALSE", {
  a <- c("x", "y")
  b <- c("x", "x")

  result <- diagonal_label_matrix_na(a, b, type = "s", return_matrix = FALSE)

  expect_true(is.matrix(result))
  expect_equal(ncol(result), 3)
  # Only position 1 matches
  expect_equal(nrow(result), 1)
})

test_that("diagonal_label_matrix_na all NAs returns empty", {
  a <- c(NA, NA)
  b <- c(NA, NA)

  result <- diagonal_label_matrix_na(a, b, type = "s")

  expect_true(inherits(result, "Matrix"))
  expect_equal(sum(result), 0)
})

test_that("diagonal_label_matrix_na return_matrix=FALSE empty case", {
  a <- c(NA, NA)
  b <- c(NA, NA)

  result <- diagonal_label_matrix_na(a, b, type = "s", return_matrix = FALSE)

  expect_true(is.matrix(result))
  expect_equal(nrow(result), 0)
})

test_that("diagonal_label_matrix_na warns on different lengths", {
  a <- c("x", "y", "z")
  b <- c("x", "y")

  expect_warning(diagonal_label_matrix_na(a, b), "different lengths")
})

# ---------- convolve_matrix ----------

test_that("convolve_matrix without normalization", {
  X <- matrix(1:6, nrow = 2, ncol = 3)
  K <- diag(3)

  result <- convolve_matrix(X, K)

  expect_equal(result, X)
})

test_that("convolve_matrix with normalization", {
  X <- matrix(1:4, nrow = 2, ncol = 2)
  K <- matrix(c(2, 0, 0, 2), nrow = 2)

  result <- convolve_matrix(X, K, normalize = TRUE)

  expect_equal(dim(result), c(2, 2))
  expect_true(all(is.finite(result)))
})

test_that("convolve_matrix validates dimensions", {
  X <- matrix(1:6, nrow = 2, ncol = 3)
  K <- diag(2)  # Wrong dimension

  expect_error(convolve_matrix(X, K))
})

test_that("convolve_matrix validates square kernel", {
  X <- matrix(1:6, nrow = 2, ncol = 3)
  K <- matrix(1:6, nrow = 2, ncol = 3)  # Not square

  expect_error(convolve_matrix(X, K))
})

# ---------- binary_label_matrix extended ----------

test_that("binary_label_matrix with different a and b vectors", {
  a <- c("x", "y")
  b <- c("y", "x", "y")

  result <- binary_label_matrix(a, b, type = "s")

  expect_equal(dim(result), c(2, 3))
  mat <- as.matrix(result)
  # a[1]="x" matches b[2]="x"
  expect_equal(mat[1, 2], 1)
  # a[2]="y" matches b[1]="y" and b[3]="y"
  expect_equal(mat[2, 1], 1)
  expect_equal(mat[2, 3], 1)
})

test_that("binary_label_matrix type='d' with different vectors", {
  a <- c("x", "y")
  b <- c("y", "x", "y")

  result <- binary_label_matrix(a, b, type = "d")
  mat <- as.matrix(result)

  # a[1]="x" differs from b[1]="y" and b[3]="y"
  expect_equal(mat[1, 1], 1)
  expect_equal(mat[1, 3], 1)
  # a[1]="x" matches b[2]="x" -> should be 0
  expect_equal(mat[1, 2], 0)
})

test_that("binary_label_matrix default b is a", {
  a <- c("x", "y", "x")
  result <- binary_label_matrix(a, type = "s")

  expect_equal(dim(result), c(3, 3))
  mat <- as.matrix(result)
  expect_equal(mat[1, 3], 1)  # both "x"
  expect_equal(mat[1, 2], 0)  # different
})

# ---------- expand_label_similarity ----------

test_that("expand_label_similarity returns symmetric matrix", {
  sim_mat <- matrix(c(1, 0.5, 0.5, 1), nrow = 2)
  rownames(sim_mat) <- colnames(sim_mat) <- c("a", "b")
  labels <- c("a", "b", "a", "b")

  result <- expand_label_similarity(labels, sim_mat, threshold = 0.3)

  expect_true(Matrix::isSymmetric(result))
  expect_equal(dim(result), c(4, 4))
})

test_that("expand_label_similarity above=FALSE", {
  sim_mat <- matrix(c(1, 0.2, 0.2, 1), nrow = 2)
  rownames(sim_mat) <- colnames(sim_mat) <- c("a", "b")
  labels <- c("a", "b", "a")

  result <- expand_label_similarity(labels, sim_mat, threshold = 0.5, above = FALSE)

  expect_true(inherits(result, "Matrix"))
  expect_equal(dim(result), c(3, 3))
})

test_that("expand_label_similarity errors on no matching labels", {
  sim_mat <- matrix(c(1, 0.5, 0.5, 1), nrow = 2)
  rownames(sim_mat) <- colnames(sim_mat) <- c("a", "b")
  labels <- c("x", "y", "z")

  expect_error(expand_label_similarity(labels, sim_mat), "no matches")
})

test_that("expand_label_similarity errors on unnamed sim_mat", {
  sim_mat <- matrix(c(1, 0.5, 0.5, 1), nrow = 2)
  labels <- c("a", "b")

  expect_error(expand_label_similarity(labels, sim_mat))
})
