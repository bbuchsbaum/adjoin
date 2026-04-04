library(testthat)
library(Matrix)

context("Searcher extended tests")

# ---------- nnsearcher ----------

test_that("nnsearcher creates valid object", {
  X <- matrix(rnorm(50), nrow = 10, ncol = 5)
  s <- nnsearcher(X)

  expect_true(inherits(s, "nnsearcher"))
  expect_equal(nrow(s$X), 10)
  expect_equal(ncol(s$X), 5)
  expect_equal(s$distance, "l2")
  expect_equal(length(s$labels), 10)
})

test_that("nnsearcher with custom labels", {
  X <- matrix(rnorm(20), nrow = 5, ncol = 4)
  labs <- c("a", "b", "c", "d", "e")
  s <- nnsearcher(X, labels = labs)

  expect_equal(s$labels, labs)
})

test_that("nnsearcher with cosine distance", {
  X <- matrix(rnorm(20), nrow = 5, ncol = 4)
  s <- nnsearcher(X, distance = "cosine")

  expect_equal(s$distance, "cosine")
})

test_that("nnsearcher validates label length", {
  X <- matrix(rnorm(20), nrow = 5, ncol = 4)
  expect_error(nnsearcher(X, labels = 1:3), "Number of labels")
})

test_that("nnsearcher rejects NA labels", {
  X <- matrix(rnorm(20), nrow = 5, ncol = 4)
  expect_error(nnsearcher(X, labels = c(1, 2, NA, 4, 5)), "NA values")
})

# ---------- search_result.nnsearcher ----------

test_that("search_result.nnsearcher maps field names", {
  X <- matrix(rnorm(20), nrow = 5, ncol = 4)
  s <- nnsearcher(X)

  raw_result <- list(idx = matrix(1:4, nrow = 2), dist = matrix(c(0.1, 0.2, 0.3, 0.4), nrow = 2))
  sr <- search_result(s, raw_result)

  expect_true(inherits(sr, "nn_search"))
  expect_true("indices" %in% names(sr))
  expect_true("distances" %in% names(sr))
  expect_equal(attr(sr, "len"), 4)
  expect_equal(attr(sr, "metric"), "l2")
})

# ---------- dist_to_sim.nn_search ----------

test_that("dist_to_sim.nn_search converts distances to similarities", {
  res <- list(indices = matrix(c(1L, 2L), nrow = 1),
              distances = matrix(c(0.5, 1.0), nrow = 1))
  class(res) <- "nn_search"
  attr(res, "len") <- 2
  attr(res, "metric") <- "l2"

  sim <- dist_to_sim(res, method = "heat", sigma = 1)

  expect_true(inherits(sim, "nn_search"))
  # Heat kernel values should be between 0 and 1
  expect_true(all(sim$distances >= 0))
  expect_true(all(sim$distances <= 1))
})

test_that("dist_to_sim.nn_search binary method", {
  res <- list(indices = matrix(c(1L, 2L), nrow = 1),
              distances = matrix(c(0.5, 1.0), nrow = 1))
  class(res) <- "nn_search"
  attr(res, "len") <- 2
  attr(res, "metric") <- "l2"

  sim <- dist_to_sim(res, method = "binary")

  expect_true(all(sim$distances == 1))
})

# ---------- dist_to_sim.Matrix ----------

test_that("dist_to_sim.Matrix converts distances", {
  m <- Matrix::Matrix(c(0, 1, 2, 1, 0, 3, 2, 3, 0), nrow = 3, sparse = TRUE)

  sim <- dist_to_sim(m, method = "heat", sigma = 1)

  expect_true(inherits(sim, "Matrix"))
  expect_true(all(sim@x >= 0))
  expect_true(all(sim@x <= 1))
})

# ---------- adjacency.nn_search ----------

test_that("adjacency.nn_search creates sparse matrix", {
  res <- list(indices = matrix(c(2L, 1L), nrow = 2),
              distances = matrix(c(0.5, 0.3), nrow = 2))
  class(res) <- "nn_search"
  attr(res, "len") <- 2
  attr(res, "metric") <- "l2"

  A <- adjacency(res, idim = 2, jdim = 2)

  expect_true(inherits(A, "Matrix"))
  expect_equal(dim(A), c(2, 2))
})

test_that("adjacency.nn_search return_triplet=TRUE", {
  res <- list(indices = matrix(c(2L, 1L), nrow = 2),
              distances = matrix(c(0.5, 0.3), nrow = 2))
  class(res) <- "nn_search"
  attr(res, "len") <- 2
  attr(res, "metric") <- "l2"

  trip <- adjacency(res, idim = 2, jdim = 2, return_triplet = TRUE)

  expect_true(is.matrix(trip))
  expect_equal(ncol(trip), 3)
})

# ---------- find_nn.nnsearcher ----------

test_that("find_nn.nnsearcher with query", {
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  s <- nnsearcher(X)

  query <- matrix(rnorm(8), nrow = 2, ncol = 4)
  result <- find_nn(s, query = query, k = 3)

  expect_true(inherits(result, "nn_search"))
  expect_equal(nrow(result$indices), 2)
  expect_equal(ncol(result$indices), 3)
})

test_that("find_nn.nnsearcher without query searches self", {
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  s <- nnsearcher(X)

  result <- find_nn(s, k = 3)

  expect_equal(nrow(result$indices), 10)
  expect_equal(ncol(result$indices), 3)
})

test_that("find_nn.nnsearcher returns labels", {
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  labs <- letters[1:10]
  s <- nnsearcher(X, labels = labs)

  result <- find_nn(s, k = 3)

  expect_true("labels" %in% names(result))
  expect_equal(nrow(result$labels), 10)
  expect_true(all(result$labels %in% labs))
})

test_that("find_nn.nnsearcher returns Euclidean distances for nanoflann backend", {
  X <- matrix(c(0, 0,
                3, 4), ncol = 2, byrow = TRUE)
  s <- nnsearcher(X)

  result <- find_nn(s, query = X[1, , drop = FALSE], k = 2)

  expect_equal(as.numeric(result$distances[1, ]), c(0, 5), tolerance = 1e-8)
})

# ---------- find_nn_among.nnsearcher ----------

test_that("find_nn_among.nnsearcher works with subset", {
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  s <- nnsearcher(X)

  result <- find_nn_among(s, k = 2, idx = 1:5)

  expect_true(inherits(result, "nn_search"))
  expect_equal(nrow(result$indices), 5)
})

# ---------- find_nn_among.class_graph ----------

test_that("find_nn_among.class_graph finds within-class neighbors", {
  set.seed(42)
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  labels <- factor(rep(c("a", "b"), each = 5))
  cg <- class_graph(labels)

  result <- find_nn_among(cg, X, k = 2)

  expect_true(inherits(result, "nn_search"))
  expect_equal(nrow(result$indices), 10)
})

# ---------- find_nn_between.nnsearcher ----------

test_that("find_nn_between.nnsearcher unrestricted", {
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  s <- nnsearcher(X)

  result <- find_nn_between(s, k = 2, idx1 = 1:5, idx2 = 6:10)

  expect_true(inherits(result, "nn_search"))
  expect_equal(nrow(result$indices), 5)
})

test_that("find_nn_between.nnsearcher restricted mode", {
  X <- matrix(rnorm(40), nrow = 10, ncol = 4)
  s <- nnsearcher(X)

  result <- find_nn_between(s, k = 2, idx1 = 1:5, idx2 = 6:10, restricted = TRUE)

  expect_true(inherits(result, "nn_search"))
  expect_equal(nrow(result$indices), 5)
})

# ---------- neighbor_graph.nnsearcher ----------

test_that("neighbor_graph.nnsearcher creates valid graph", {
  X <- matrix(rnorm(50), nrow = 10, ncol = 5)
  s <- nnsearcher(X)

  ng <- neighbor_graph(s, k = 3, type = "normal", transform = "heat", sigma = 1)

  expect_true(inherits(ng, "neighbor_graph"))
  A <- adjacency(ng)
  expect_equal(dim(A), c(10, 10))
})

test_that("neighbor_graph.nnsearcher with binary transform", {
  X <- matrix(rnorm(50), nrow = 10, ncol = 5)
  s <- nnsearcher(X)

  ng <- neighbor_graph(s, k = 3, transform = "binary", sigma = 1)

  expect_true(inherits(ng, "neighbor_graph"))
  A <- adjacency(ng)
  # Binary: all non-zero values should be 1
  expect_true(all(A@x == 1))
})

test_that("neighbor_graph.nnsearcher mutual type", {
  X <- matrix(rnorm(50), nrow = 10, ncol = 5)
  s <- nnsearcher(X)

  ng <- neighbor_graph(s, k = 3, type = "mutual", transform = "heat", sigma = 1)

  expect_true(inherits(ng, "neighbor_graph"))
  A <- adjacency(ng)
  expect_true(Matrix::isSymmetric(A))
})
