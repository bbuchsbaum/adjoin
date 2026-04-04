library(testthat)
library(Matrix)

context("Diffusion kernel and diffusion map")

# Helper: create a simple symmetric sparse adjacency matrix (path graph)
make_path_graph <- function(n) {
  i <- seq_len(n - 1)
  A <- sparseMatrix(i = c(i, i + 1), j = c(i + 1, i),
                    x = rep(1, 2 * (n - 1)), dims = c(n, n))
  A
}

# Helper: create a graph with isolated nodes appended
# Uses direct construction to avoid summary() issues
make_path_with_isolate <- function(n_path, n_total) {
  stopifnot(n_total > n_path)
  i_idx <- seq_len(n_path - 1)
  sparseMatrix(
    i = c(i_idx, i_idx + 1),
    j = c(i_idx + 1, i_idx),
    x = rep(1, 2 * (n_path - 1)),
    dims = c(n_total, n_total)
  )
}

# ---------- compute_diffusion_kernel ----------

test_that("compute_diffusion_kernel returns correct dimensions", {
  A <- make_path_graph(6)
  K <- compute_diffusion_kernel(A, t = 1)
  expect_equal(dim(K), c(6, 6))
})

test_that("compute_diffusion_kernel result is symmetric with integer t", {
  A <- make_path_graph(8)
  K <- compute_diffusion_kernel(A, t = 2)
  K_dense <- as.matrix(K)
  expect_true(all(abs(K_dense - t(K_dense)) < 1e-10))
})

test_that("compute_diffusion_kernel small t gives more diagonal dominance than large t", {
  A <- make_path_graph(6)
  # Use integer t to avoid NaN from negative eigenvalues
  K1 <- compute_diffusion_kernel(A, t = 1)
  K2 <- compute_diffusion_kernel(A, t = 10)

  K1_dense <- as.matrix(K1)
  K2_dense <- as.matrix(K2)

  # Ratio of diagonal to max off-diagonal should be larger for smaller t
  ratio1 <- diag(K1_dense)[3] / max(abs(K1_dense[3, -3]))
  ratio2 <- diag(K2_dense)[3] / max(abs(K2_dense[3, -3]))

  expect_true(ratio1 > ratio2)
})

test_that("compute_diffusion_kernel with k parameter works", {
  A <- make_path_graph(10)
  K_full <- compute_diffusion_kernel(A, t = 1, k = NULL)
  K_approx <- compute_diffusion_kernel(A, t = 1, k = 5)

  expect_equal(dim(K_full), c(10, 10))
  expect_equal(dim(K_approx), c(10, 10))
})

test_that("compute_diffusion_kernel with symmetric=FALSE works", {
  A <- make_path_graph(6)
  K <- compute_diffusion_kernel(A, t = 1, symmetric = FALSE)
  expect_equal(dim(K), c(6, 6))
  expect_true(all(is.finite(as.matrix(K))))
})

test_that("compute_diffusion_kernel validates inputs", {
  A <- make_path_graph(5)
  expect_error(compute_diffusion_kernel(A, t = -1), "positive scalar")
  expect_error(compute_diffusion_kernel(A, t = c(1, 2)), "positive scalar")
  expect_error(compute_diffusion_kernel(A, t = 0), "positive scalar")
})

test_that("compute_diffusion_kernel validates k", {
  A <- make_path_graph(5)
  expect_error(compute_diffusion_kernel(A, t = 1, k = 5), "k must be less than n")
  expect_error(compute_diffusion_kernel(A, t = 1, k = 0), "k must be at least 1")
})

test_that("compute_diffusion_kernel rejects non-square matrix", {
  A <- sparseMatrix(i = c(1, 2), j = c(1, 2), x = c(1, 1), dims = c(3, 4))
  expect_error(compute_diffusion_kernel(A, t = 1), "square")
})

test_that("compute_diffusion_kernel handles isolated nodes with warning", {
  A_big <- make_path_with_isolate(4, 5)
  expect_warning(compute_diffusion_kernel(A_big, t = 1), "Isolated")
})

test_that("compute_diffusion_kernel accepts dense matrix input", {
  A_dense <- matrix(c(0, 1, 0, 1, 0, 1, 0, 1, 0), nrow = 3)
  K <- compute_diffusion_kernel(A_dense, t = 1)
  expect_equal(dim(K), c(3, 3))
})

test_that("compute_diffusion_kernel with even integer t produces valid results", {
  # Even integer t avoids NaN from negative eigenvalues
  A <- make_path_graph(6)
  K <- compute_diffusion_kernel(A, t = 2)
  K_dense <- as.matrix(K)
  expect_true(all(is.finite(K_dense)))
  expect_true(all(K_dense >= -1e-10))
})

test_that("compute_diffusion_kernel full vs truncated are consistent", {
  A <- make_path_graph(8)
  K_full <- as.matrix(compute_diffusion_kernel(A, t = 2, k = NULL))
  K_trunc <- as.matrix(compute_diffusion_kernel(A, t = 2, k = 6))

  # Truncated should be a reasonable approximation
  expect_true(cor(as.vector(K_full), as.vector(K_trunc)) > 0.9)
})

# ---------- compute_diffusion_map ----------

test_that("compute_diffusion_map returns correct components", {
  A <- make_path_graph(10)
  result <- compute_diffusion_map(A, t = 1, k = 3)

  expect_true(is.list(result))
  expect_true("embedding" %in% names(result))
  expect_true("distances" %in% names(result))
})

test_that("compute_diffusion_map embedding has correct dimensions", {
  A <- make_path_graph(10)
  k <- 4
  result <- compute_diffusion_map(A, t = 1, k = k)

  expect_equal(nrow(result$embedding), 10)
  expect_equal(ncol(result$embedding), k)
})

test_that("compute_diffusion_map distances are non-negative", {
  A <- make_path_graph(10)
  result <- compute_diffusion_map(A, t = 1, k = 3)

  expect_true(all(result$distances >= -1e-10))
})

test_that("compute_diffusion_map distance matrix is symmetric", {
  A <- make_path_graph(10)
  result <- compute_diffusion_map(A, t = 1, k = 3)

  expect_true(all(abs(result$distances - t(result$distances)) < 1e-10))
})

test_that("compute_diffusion_map self-distance is zero", {
  A <- make_path_graph(8)
  result <- compute_diffusion_map(A, t = 1, k = 3)

  expect_true(all(abs(diag(result$distances)) < 1e-10))
})

test_that("compute_diffusion_map validates inputs", {
  A <- make_path_graph(10)
  expect_error(compute_diffusion_map(A, t = -1), "positive scalar")
  expect_error(compute_diffusion_map(A, t = 1, k = 0), "positive integer")
  expect_error(compute_diffusion_map(A, t = 1, k = 9), "less than n - 1")
})

test_that("compute_diffusion_map rejects non-square matrix", {
  A <- sparseMatrix(i = c(1, 2), j = c(1, 2), x = c(1, 1), dims = c(3, 4))
  expect_error(compute_diffusion_map(A, t = 1, k = 1), "square")
})

test_that("compute_diffusion_map handles isolated nodes with warning", {
  A_big <- make_path_with_isolate(4, 6)
  expect_warning(compute_diffusion_map(A_big, t = 1, k = 2), "Isolated")
})

test_that("compute_diffusion_map adjacent nodes closer than distant on path", {
  # Path graph with enough nodes: adjacent should be closer
  A <- make_path_graph(20)
  result <- compute_diffusion_map(A, t = 2, k = 10)

  # Node 10-11 (adjacent) should be closer than node 1-20 (far ends)
  expect_true(result$distances[10, 11] < result$distances[1, 20])
})

test_that("compute_diffusion_map with dense matrix", {
  A <- matrix(c(0, 1, 0, 0,
                1, 0, 1, 0,
                0, 1, 0, 1,
                0, 0, 1, 0), nrow = 4)
  A <- as(A, "CsparseMatrix")
  result <- compute_diffusion_map(A, t = 1, k = 2)

  expect_equal(nrow(result$embedding), 4)
  expect_equal(ncol(result$embedding), 2)
})
