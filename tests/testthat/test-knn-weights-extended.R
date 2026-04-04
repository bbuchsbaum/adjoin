library(testthat)
library(Matrix)

context("KNN weights extended tests")

# ---------- graph_weights ----------

test_that("graph_weights returns neighbor_graph with knn mode", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  result <- graph_weights(X, k = 3, weight_mode = "binary", neighbor_mode = "knn")

  expect_true(inherits(result, "neighbor_graph"))
  A <- adjacency(result)
  expect_equal(dim(A), c(20, 20))
})

test_that("graph_weights with heat kernel auto-estimates sigma", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  expect_message(
    result <- graph_weights(X, k = 3, weight_mode = "heat", neighbor_mode = "knn"),
    "sigma is"
  )
  expect_true(inherits(result, "neighbor_graph"))
})

test_that("graph_weights with normalized weight_mode", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  expect_message(
    result <- graph_weights(X, k = 3, weight_mode = "normalized", neighbor_mode = "knn"),
    "sigma is"
  )
  expect_true(inherits(result, "neighbor_graph"))
})

test_that("graph_weights with cosine weight_mode", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  result <- graph_weights(X, k = 3, weight_mode = "cosine", neighbor_mode = "knn")
  expect_true(inherits(result, "neighbor_graph"))
})

test_that("graph_weights with correlation weight_mode", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  result <- graph_weights(X, k = 3, weight_mode = "correlation", neighbor_mode = "knn")
  expect_true(inherits(result, "neighbor_graph"))
})

test_that("graph_weights with euclidean weight_mode", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  result <- graph_weights(X, k = 3, weight_mode = "euclidean", neighbor_mode = "knn")
  expect_true(inherits(result, "neighbor_graph"))
})

test_that("graph_weights epsilon mode not implemented", {
  X <- matrix(rnorm(20), ncol = 2)
  expect_error(graph_weights(X, k = 3, neighbor_mode = "epsilon"))
})

test_that("graph_weights stores params", {
  set.seed(42)
  X <- matrix(rnorm(60), ncol = 3)
  result <- graph_weights(X, k = 3, weight_mode = "binary", neighbor_mode = "knn")
  expect_equal(result$params$k, 3)
  expect_equal(result$params$weight_mode, "binary")
  expect_equal(result$params$neighbor_mode, "knn")
})

test_that("graph_weights forwards HNSW backend to weighted_knn", {
  skip_if_not_installed("RcppHNSW")

  set.seed(42)
  X <- matrix(rnorm(120), ncol = 3)
  result <- graph_weights(X, k = 3, weight_mode = "binary",
                          neighbor_mode = "knn", backend = "hnsw")

  expect_true(inherits(result, "neighbor_graph"))
  expect_equal(dim(adjacency(result)), c(nrow(X), nrow(X)))
})

test_that("graph_weights is permutation-equivariant on exact backend", {
  set.seed(123)
  X <- matrix(rnorm(48), ncol = 3)
  perm <- c(5, 1, 8, 3, 2, 7, 4, 6, 9, 10, 11, 12, 13, 14, 15, 16)

  A1 <- adjacency(graph_weights(
    X, k = 3, weight_mode = "binary",
    neighbor_mode = "knn", backend = "nanoflann"
  ))
  A2 <- adjacency(graph_weights(
    X[perm, , drop = FALSE], k = 3, weight_mode = "binary",
    neighbor_mode = "knn", backend = "nanoflann"
  ))

  expect_equal(as.matrix(A2), as.matrix(A1)[perm, perm], tolerance = 1e-8)
})

test_that("graph_weights cosine and correlation modes handle zero rows", {
  X <- rbind(
    c(0, 0, 0),
    c(1, 0, 0),
    c(0, 1, 0),
    c(0, 0, 1)
  )

  A_cos <- adjacency(graph_weights(
    X, k = 2, weight_mode = "cosine",
    neighbor_mode = "knn", backend = "nanoflann"
  ))
  A_cor <- adjacency(graph_weights(
    X, k = 2, weight_mode = "correlation",
    neighbor_mode = "knn", backend = "nanoflann"
  ))

  expect_true(all(is.finite(A_cos@x)))
  expect_true(all(is.finite(A_cor@x)))
})

test_that("graph_weights HNSW agrees with exact backend on a canonical separated fixture", {
  skip_if_not_installed("RcppHNSW")

  X <- matrix(c(
    0, 0,
    0, 1,
    10, 0,
    10, 1
  ), ncol = 2, byrow = TRUE)

  A_exact <- adjacency(graph_weights(
    X, k = 1, weight_mode = "binary",
    neighbor_mode = "knn", backend = "nanoflann"
  ))
  A_hnsw <- adjacency(graph_weights(
    X, k = 1, weight_mode = "binary",
    neighbor_mode = "knn", backend = "hnsw", ef = 50
  ))

  expect_equal(as.matrix(A_hnsw), as.matrix(A_exact), tolerance = 1e-8)
})

# ---------- weighted_knn types ----------

test_that("weighted_knn mutual type works", {
  set.seed(42)
  X <- matrix(rnorm(20), ncol = 2)

  adj <- weighted_knn(X, k = 3, type = "mutual", as = "sparse")

  expect_true(inherits(adj, "sparseMatrix"))
  expect_true(Matrix::isSymmetric(adj))
})

test_that("weighted_knn asym type works", {
  set.seed(42)
  X <- matrix(rnorm(20), ncol = 2)

  g <- weighted_knn(X, k = 3, type = "asym", as = "igraph")

  expect_true(inherits(g, "igraph"))
  expect_true(igraph::is_directed(g))
})

test_that("weighted_knn as igraph returns igraph", {
  set.seed(42)
  X <- matrix(rnorm(20), ncol = 2)

  g <- weighted_knn(X, k = 3, as = "igraph")

  expect_true(inherits(g, "igraph"))
})

test_that("weighted_knn uses Euclidean distances from Rnanoflann directly", {
  X <- matrix(c(0, 0,
                3, 4), ncol = 2, byrow = TRUE)

  adj <- weighted_knn(X, k = 1, FUN = identity, type = "asym", as = "sparse")

  expect_equal(as.matrix(adj),
               matrix(c(0, 5,
                        5, 0), nrow = 2, byrow = TRUE),
               tolerance = 1e-8)
})

test_that("weighted_knn sparse output matches igraph adjacency", {
  set.seed(42)
  X <- matrix(rnorm(40), ncol = 2)

  adj <- weighted_knn(X, k = 3, type = "normal", as = "sparse")
  g <- weighted_knn(X, k = 3, type = "normal", as = "igraph")

  expect_equal(as.matrix(adj),
               as.matrix(igraph::as_adjacency_matrix(g, attr = "weight", sparse = TRUE)),
               tolerance = 1e-8)
})

test_that("weighted_knn supports HNSW backend", {
  skip_if_not_installed("RcppHNSW")

  X <- matrix(c(0, 0,
                3, 4), ncol = 2, byrow = TRUE)

  adj <- weighted_knn(X, k = 1, FUN = identity, type = "asym",
                      as = "sparse", backend = "hnsw", ef = 50)

  expect_equal(as.matrix(adj),
               matrix(c(0, 5,
                        5, 0), nrow = 2, byrow = TRUE),
               tolerance = 1e-8)
})

# ---------- cross_adjacency ----------

test_that("cross_adjacency as sparse works for square case", {
  set.seed(42)
  X <- matrix(rnorm(20), ncol = 2)
  Y <- matrix(rnorm(20), ncol = 2)

  result <- cross_adjacency(X, Y, k = 3, as = "sparse")

  expect_true(inherits(result, "Matrix"))
  expect_equal(nrow(result), nrow(Y))
  expect_equal(ncol(result), nrow(X))
})

test_that("cross_adjacency as igraph works for square case", {
  set.seed(42)
  X <- matrix(rnorm(20), ncol = 2)
  Y <- matrix(rnorm(20), ncol = 2)

  result <- cross_adjacency(X, Y, k = 3, as = "igraph")
  expect_true(inherits(result, "igraph"))
})

test_that("cross_adjacency as index_sim returns correct format", {
  set.seed(42)
  X <- matrix(rnorm(10), ncol = 2)
  Y <- matrix(rnorm(8), ncol = 2)

  result <- cross_adjacency(X, Y, k = 2, as = "index_sim")

  expect_true(is.matrix(result))
  expect_equal(ncol(result), 2)
})

test_that("cross_adjacency keeps exactly k neighbors for distinct query/reference sets", {
  X <- matrix(c(0, 0,
                10, 0), ncol = 2, byrow = TRUE)
  Y <- matrix(c(1, 0,
                9, 0), ncol = 2, byrow = TRUE)

  result <- cross_adjacency(X, Y, k = 1, FUN = identity, as = "index_sim")

  expect_equal(result[, 1], c(1, 2))
  expect_equal(result[, 2], c(1, 1), tolerance = 1e-8)
})

test_that("cross_adjacency supports HNSW backend", {
  skip_if_not_installed("RcppHNSW")

  X <- matrix(c(0, 0,
                10, 0), ncol = 2, byrow = TRUE)
  Y <- matrix(c(1, 0,
                9, 0), ncol = 2, byrow = TRUE)

  result <- cross_adjacency(X, Y, k = 1, FUN = identity,
                            as = "index_sim", backend = "hnsw", ef = 50)

  expect_equal(result[, 1], c(1, 2))
  expect_equal(result[, 2], c(1, 1), tolerance = 1e-8)
})

test_that("cross_adjacency is permutation-equivariant in query order", {
  X <- matrix(c(
    0, 0,
    10, 0,
    20, 0
  ), ncol = 2, byrow = TRUE)
  Y <- matrix(c(
    1, 0,
    19, 0,
    9, 0
  ), ncol = 2, byrow = TRUE)
  perm <- c(3, 1, 2)

  A1 <- cross_adjacency(X, Y, k = 1, FUN = identity, as = "sparse")
  A2 <- cross_adjacency(X, Y[perm, , drop = FALSE], k = 1, FUN = identity, as = "sparse")

  expect_equal(as.matrix(A2), as.matrix(A1)[perm, , drop = FALSE], tolerance = 1e-8)
})

test_that("cross_adjacency non-square returns sparse", {
  set.seed(42)
  X <- matrix(rnorm(10), ncol = 2)  # 5 rows
  Y <- matrix(rnorm(6), ncol = 2)   # 3 rows

  result <- cross_adjacency(X, Y, k = 2, as = "sparse")
  expect_true(inherits(result, "Matrix"))
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 5)
})

test_that("cross_adjacency mutual type works", {
  set.seed(42)
  X <- matrix(rnorm(20), ncol = 2)
  Y <- matrix(rnorm(20), ncol = 2)

  result <- cross_adjacency(X, Y, k = 3, type = "mutual", as = "sparse")
  expect_true(inherits(result, "Matrix"))
})

# ---------- estimate_sigma ----------

test_that("estimate_sigma returns positive scalar", {
  set.seed(42)
  X <- matrix(rnorm(200), ncol = 2)
  sigma <- estimate_sigma(X)

  expect_true(is.numeric(sigma))
  expect_equal(length(sigma), 1)
  expect_true(sigma > 0)
})

test_that("estimate_sigma with custom quantile", {
  set.seed(42)
  X <- matrix(rnorm(200), ncol = 2)
  s1 <- estimate_sigma(X, prop = 0.1)
  s2 <- estimate_sigma(X, prop = 0.5)

  # Higher quantile should give larger sigma
  expect_true(s2 > s1)
})

test_that("estimate_sigma samples when data is large", {
  set.seed(42)
  X <- matrix(rnorm(20000), ncol = 2)
  sigma <- estimate_sigma(X, nsamples = 100)
  expect_true(sigma > 0)
})

# ---------- psparse ----------

test_that("psparse with max function", {
  M <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(3, 5), dims = c(3, 3))
  result <- psparse(M, FUN = max)

  expect_true(inherits(result, "Matrix"))
  mat <- as.matrix(result)
  expect_equal(mat[1, 2], 5)
  expect_equal(mat[2, 1], 5)
})

test_that("psparse with sum function", {
  M <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(3, 5), dims = c(3, 3))
  result <- psparse(M, FUN = `+`)

  mat <- as.matrix(result)
  expect_equal(mat[1, 2], 8)
  expect_equal(mat[2, 1], 8)
})

test_that("psparse return_triplet=TRUE", {
  M <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(3, 5), dims = c(3, 3))
  result <- psparse(M, FUN = max, return_triplet = TRUE)

  expect_true(is.matrix(result))
  expect_equal(ncol(result), 3)
})

test_that("psparse with diagonal elements", {
  M <- sparseMatrix(i = c(1, 1, 2), j = c(1, 2, 1), x = c(10, 3, 5), dims = c(2, 2))
  result <- psparse(M, FUN = max)

  mat <- as.matrix(result)
  # Diagonal should be preserved
  expect_equal(mat[1, 1], 10)
  # Off-diagonal should use max
  expect_equal(mat[1, 2], 5)
  expect_equal(mat[2, 1], 5)
})

# ---------- threshold_adjacency ----------

test_that("threshold_adjacency with mutual type", {
  set.seed(42)
  A <- matrix(runif(25), 5, 5)
  result <- threshold_adjacency(A, k = 2, type = "mutual")

  expect_true(inherits(result, "Matrix"))
  expect_equal(dim(result), c(5, 5))
})

# ---------- factor_sim ----------

test_that("factor_sim Jaccard produces valid similarity", {
  des <- data.frame(
    v1 = factor(c("a", "b", "a", "b")),
    v2 = factor(c("x", "x", "y", "y"))
  )

  result <- factor_sim(des, method = "Jaccard")

  expect_true(inherits(result, "dist") || inherits(result, "simil"))
})

test_that("factor_sim Dice produces valid similarity", {
  des <- data.frame(
    v1 = factor(c("a", "b", "a")),
    v2 = factor(c("x", "x", "y"))
  )
  result <- factor_sim(des, method = "Dice")
  expect_true(inherits(result, "dist") || inherits(result, "simil"))
})

# ---------- weighted_factor_sim ----------

test_that("weighted_factor_sim with equal weights", {
  des <- data.frame(
    v1 = factor(c("a", "a", "b")),
    v2 = factor(c("x", "y", "x"))
  )

  result <- weighted_factor_sim(des)

  expect_true(inherits(result, "Matrix") || is.matrix(result))
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 3)
})

test_that("weighted_factor_sim with custom weights", {
  des <- data.frame(
    v1 = factor(c("a", "a", "b")),
    v2 = factor(c("x", "y", "x"))
  )

  result <- weighted_factor_sim(des, wts = c(0.8, 0.2))

  expect_true(inherits(result, "Matrix") || is.matrix(result))
  expect_equal(dim(result), c(3, 3))
})

# ---------- get_neighbor_fun ----------

test_that("get_neighbor_fun returns correct functions", {
  f_heat <- get_neighbor_fun("heat", sigma = 1)
  f_binary <- get_neighbor_fun("binary", sigma = 1)
  f_euclidean <- get_neighbor_fun("euclidean", sigma = 1)

  dists <- c(0, 1, 2)

  # Heat kernel should return values in [0, 1]
  expect_true(all(f_heat(dists) >= 0))
  expect_true(all(f_heat(dists) <= 1))

  # Binary should return all 1s
  expect_equal(f_binary(dists), c(1, 1, 1))

  # Euclidean should return distances unchanged
  expect_equal(f_euclidean(dists), dists)
})

test_that("get_neighbor_fun normalized", {
  f_norm <- get_neighbor_fun("normalized", sigma = 1, len = 4)
  dists <- c(0, 1, 2)
  result <- f_norm(dists)
  expect_equal(length(result), 3)
  expect_true(all(result >= 0))
})

test_that("get_neighbor_fun cosine", {
  f_cos <- get_neighbor_fun("cosine", sigma = 1)
  dists <- c(0, 0.5, 1)
  result <- f_cos(dists)
  expect_equal(length(result), 3)
})

test_that("get_neighbor_fun correlation", {
  f_cor <- get_neighbor_fun("correlation", sigma = 1, len = 10)
  dists <- c(0, 1, 2)
  result <- f_cor(dists)
  expect_equal(length(result), 3)
})

# ---------- indices_to_sparse ----------

test_that("indices_to_sparse creates valid sparse matrix", {
  nn_index <- matrix(c(2, 3, 1, 3, 1, 2), nrow = 3, ncol = 2)
  hval <- matrix(c(0.5, 0.3, 0.5, 0.2, 0.3, 0.2), nrow = 3, ncol = 2)

  result <- indices_to_sparse(nn_index, hval, idim = 3, jdim = 3)

  expect_true(inherits(result, "Matrix"))
  expect_equal(dim(result), c(3, 3))
})

test_that("indices_to_sparse return_triplet=TRUE", {
  nn_index <- matrix(c(2, 1), nrow = 2, ncol = 1)
  hval <- matrix(c(0.5, 0.3), nrow = 2, ncol = 1)

  result <- indices_to_sparse(nn_index, hval, return_triplet = TRUE)

  expect_true(is.matrix(result))
  expect_equal(ncol(result), 3)
})

test_that("indices_to_sparse handles NA values", {
  nn_index <- matrix(c(2, NA, 1, 3), nrow = 2, ncol = 2)
  hval <- matrix(c(0.5, 0.3, 0.4, 0.2), nrow = 2, ncol = 2)

  result <- indices_to_sparse(nn_index, hval, idim = 3, jdim = 3)

  expect_true(inherits(result, "Matrix"))
  # NA entry should be excluded
  expect_equal(length(result@x), 3)
})
