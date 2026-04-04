library(testthat)
library(Matrix)

context("Class graph extended tests")

# ---------- class_graph construction ----------

test_that("class_graph creates correct adjacency structure (sparse)", {
  labels <- factor(c("a", "a", "b", "b", "c"))
  cg <- class_graph(labels, sparse = TRUE)
  A <- adjacency(cg)
  mat <- as.matrix(A)

  # Same-class pairs should be 1

  expect_equal(mat[1, 2], 1)
  expect_equal(mat[2, 1], 1)
  expect_equal(mat[3, 4], 1)
  expect_equal(mat[4, 3], 1)

  # Different-class pairs should be 0
  expect_equal(mat[1, 3], 0)
  expect_equal(mat[1, 5], 0)
  expect_equal(mat[3, 5], 0)

  # Self-connections should be 1
  expect_equal(mat[1, 1], 1)
  expect_equal(mat[5, 5], 1)
})

test_that("class_graph creates correct adjacency structure (dense)", {
  labels <- factor(c("a", "a", "b"))
  cg <- class_graph(labels, sparse = FALSE)
  A <- adjacency(cg)
  mat <- as.matrix(A)

  expect_equal(mat[1, 2], 1)
  expect_equal(mat[2, 1], 1)
  expect_equal(mat[1, 3], 0)
})

test_that("class_graph has correct class attributes", {
  labels <- factor(c("x", "y", "x"))
  cg <- class_graph(labels)
  expect_true(inherits(cg, "class_graph"))
  expect_true(inherits(cg, "neighbor_graph"))
  expect_equal(cg$levels, c("x", "y"))
  expect_equal(length(cg$class_indices), 2)
})

test_that("class_graph class_freq is correct", {
  labels <- factor(c("a", "a", "a", "b", "b"))
  cg <- class_graph(labels)
  expect_equal(as.numeric(cg$class_freq["a"]), 3)
  expect_equal(as.numeric(cg$class_freq["b"]), 2)
})

# ---------- heterogeneous_neighbors ----------

test_that("heterogeneous_neighbors returns correct structure", {
  set.seed(42)
  labels <- factor(c("a", "a", "a", "b", "b", "b"))
  X <- matrix(rnorm(12), ncol = 2)
  cg <- class_graph(labels)

  result <- heterogeneous_neighbors(cg, X, k = 2, weight_mode = "binary")

  expect_true(inherits(result, "neighbor_graph"))
  A <- adjacency(result)
  expect_equal(dim(A), c(6, 6))
})

test_that("heterogeneous_neighbors only connects different classes", {
  set.seed(42)
  labels <- factor(c("a", "a", "b", "b"))
  X <- matrix(c(0, 0, 0, 1, 10, 0, 10, 1), ncol = 2, byrow = TRUE)
  cg <- class_graph(labels)

  result <- heterogeneous_neighbors(cg, X, k = 1, weight_mode = "binary")
  A <- adjacency(result)
  mat <- as.matrix(A)

  # Within-class edges should be 0
  expect_equal(mat[1, 2], 0)
  expect_equal(mat[3, 4], 0)
})

test_that("heterogeneous_neighbors with heat kernel", {
  set.seed(42)
  labels <- factor(c("a", "a", "b", "b"))
  X <- matrix(c(0, 0, 0, 1, 10, 0, 10, 1), ncol = 2, byrow = TRUE)
  cg <- class_graph(labels)

  result <- heterogeneous_neighbors(cg, X, k = 1, weight_mode = "heat", sigma = 1)
  A <- adjacency(result)
  expect_true(all(A@x >= 0))
  expect_true(all(A@x <= 1))
})

test_that("heterogeneous_neighbors euclidean weights use direct Euclidean distance", {
  labels <- factor(c("a", "b"))
  X <- matrix(c(0, 0,
                3, 4), ncol = 2, byrow = TRUE)
  cg <- class_graph(labels)

  result <- heterogeneous_neighbors(cg, X, k = 1, weight_mode = "euclidean")
  A <- adjacency(result)

  expect_equal(as.matrix(A),
               matrix(c(0, 5,
                        5, 0), nrow = 2, byrow = TRUE),
               tolerance = 1e-8)
})

# ---------- homogeneous_neighbors ----------

test_that("homogeneous_neighbors returns correct structure", {
  set.seed(42)
  labels <- factor(c("a", "a", "a", "b", "b", "b"))
  X <- matrix(rnorm(12), ncol = 2)
  cg <- class_graph(labels)

  result <- homogeneous_neighbors(cg, X, k = 2, weight_mode = "heat", sigma = 1)

  expect_true(inherits(result, "neighbor_graph"))
  A <- adjacency(result)
  expect_equal(dim(A), c(6, 6))
})

test_that("homogeneous_neighbors only connects same-class points", {
  set.seed(42)
  labels <- factor(c("a", "a", "b", "b"))
  # Put class a far from class b
  X <- matrix(c(0, 0, 0.1, 0.1, 100, 100, 100.1, 100.1), ncol = 2, byrow = TRUE)
  cg <- class_graph(labels)

  result <- homogeneous_neighbors(cg, X, k = 1, weight_mode = "binary")
  A <- adjacency(result)
  mat <- as.matrix(A)

  # Between-class edges should be 0
  expect_equal(mat[1, 3], 0)
  expect_equal(mat[1, 4], 0)
  expect_equal(mat[2, 3], 0)
  expect_equal(mat[2, 4], 0)

  # Within-class edges should exist
  expect_true(mat[1, 2] > 0 || mat[2, 1] > 0)
  expect_true(mat[3, 4] > 0 || mat[4, 3] > 0)
})

test_that("homogeneous_neighbors handles single-element class", {
  set.seed(42)
  labels <- factor(c("a", "b", "b", "b"))
  X <- matrix(rnorm(8), ncol = 2)
  cg <- class_graph(labels)

  # Class 'a' has only 1 element, should be skipped
  result <- homogeneous_neighbors(cg, X, k = 1, weight_mode = "binary")
  A <- adjacency(result)
  mat <- as.matrix(A)
  # Row/col 1 should have no edges (single-element class)
  expect_equal(sum(mat[1, ]), 0)
  expect_equal(sum(mat[, 1]), 0)
})

test_that("homogeneous_neighbors euclidean weights use direct Euclidean distance", {
  labels <- factor(c("a", "a"))
  X <- matrix(c(0, 0,
                3, 4), ncol = 2, byrow = TRUE)
  cg <- class_graph(labels)

  result <- homogeneous_neighbors(cg, X, k = 1, weight_mode = "euclidean")
  A <- adjacency(result)

  expect_equal(as.matrix(A),
               matrix(c(0, 5,
                        5, 0), nrow = 2, byrow = TRUE),
               tolerance = 1e-8)
})

# ---------- within_class_neighbors (more thorough) ----------

test_that("within_class_neighbors preserves only within-class edges", {
  labels <- factor(c("a", "a", "b", "b"))
  cg <- class_graph(labels)

  # Fully connected neighbor graph
  adj <- Matrix(1, nrow = 4, ncol = 4, sparse = TRUE)
  diag(adj) <- 0
  ng <- neighbor_graph(adj)

  result <- within_class_neighbors(cg, ng)
  A <- adjacency(result)
  mat <- as.matrix(A)

  # Only within-class edges should remain
  expect_true(mat[1, 2] > 0)
  expect_true(mat[3, 4] > 0)
  expect_equal(mat[1, 3], 0)
  expect_equal(mat[1, 4], 0)
  expect_equal(mat[2, 3], 0)
  expect_equal(mat[2, 4], 0)
})

# ---------- between_class_neighbors (more thorough) ----------

test_that("between_class_neighbors preserves only between-class edges", {
  labels <- factor(c("a", "a", "b", "b"))
  cg <- class_graph(labels)

  # Fully connected neighbor graph
  adj <- Matrix(1, nrow = 4, ncol = 4, sparse = TRUE)
  diag(adj) <- 0
  ng <- neighbor_graph(adj)

  result <- between_class_neighbors(cg, ng)
  A <- adjacency(result)
  mat <- as.matrix(A)

  # Only between-class edges should remain
  expect_equal(mat[1, 2], 0)
  expect_equal(mat[3, 4], 0)
  expect_true(mat[1, 3] > 0)
  expect_true(mat[1, 4] > 0)
  expect_true(mat[2, 3] > 0)
  expect_true(mat[2, 4] > 0)
})

# ---------- discriminating_distance ----------

test_that("discriminating_distance returns valid matrix", {
  set.seed(42)
  X <- matrix(rnorm(40), ncol = 2)
  labels <- factor(rep(c("a", "b"), each = 10))

  result <- discriminating_distance(X, labels, k = 5, sigma = 0.7)

  expect_true(inherits(result, "Matrix") || is.matrix(result))
  expect_equal(dim(result), c(20, 20))
  # All entries should be non-negative
  if (inherits(result, "sparseMatrix")) {
    expect_true(all(result@x >= 0))
  }
})

# ---------- discriminating_similarity ----------

test_that("discriminating_similarity returns valid matrix", {
  set.seed(42)
  X <- matrix(rnorm(40), ncol = 2)
  labels <- factor(rep(c("a", "b"), each = 10))
  cg <- class_graph(labels)

  result <- discriminating_similarity(X, k = 5, sigma = 0.7, cg = cg)

  expect_true(inherits(result, "Matrix") || is.matrix(result))
  expect_equal(dim(result), c(20, 20))
})

