test_that("local_global_adjacency respects L and K", {
  set.seed(123)
  coords <- matrix(runif(40), ncol = 2)

  A <- local_global_adjacency(coords, L = 2, K = 2, r = 0.2,
                              symmetric = FALSE, normalized = FALSE,
                              nnk_buffer = 5)

  expect_equal(nrow(A), nrow(coords))
  deg <- Matrix::rowSums(A > 0)
  expect_true(all(deg <= 4))

  dist_mat <- as.matrix(dist(coords))
  for (i in seq_len(nrow(coords))) {
    loc_js <- which(A[i, ] != 0 & dist_mat[i, ] <= 0.2)
    far_js <- which(A[i, ] != 0 & dist_mat[i, ] > 0.2)
    expect_true(length(loc_js) <= 2)
    expect_true(length(far_js) <= 2)
  }
})

test_that("local_global_adjacency can symmetrize and normalize", {
  set.seed(99)
  coords <- matrix(runif(60), ncol = 2)

  A_sym <- local_global_adjacency(coords, L = 3, K = 2, r = 0.18,
                                  symmetric = TRUE, normalized = FALSE)
  expect_true(Matrix::isSymmetric(A_sym, tol = 1e-8))

  A_norm <- local_global_adjacency(coords, L = 3, K = 2, r = 0.18,
                                   symmetric = FALSE, normalized = TRUE)
  rs <- Matrix::rowSums(A_norm)
  nz <- rs > 0
  expect_true(all(abs(rs[nz] - 1) < 1e-8))
})

test_that("far_penalty exp produces distance-decaying far weights", {
  set.seed(5)
  coords <- matrix(runif(80), ncol = 2)

  A_exp <- local_global_adjacency(coords, L = 1, K = 3, r = 0.1,
                                  far_penalty = "exp", tau = 0.1,
                                  symmetric = FALSE, normalized = FALSE)

  dist_mat <- as.matrix(dist(coords))
  i <- 1
  far_js <- which(A_exp[i, ] != 0 & dist_mat[i, ] > 0.1)
  expect_true(length(far_js) > 1)  # need at least two to compare

  far_d <- dist_mat[i, far_js]
  far_w <- as.numeric(A_exp[i, far_js])
  ord <- order(far_d)
  far_d <- far_d[ord]
  far_w <- far_w[ord]

  # weights should be non-increasing as distance grows
  expect_true(all(diff(far_w) <= 1e-12))
})

test_that("local_global_adjacency include_diagonal retains self loops", {
  set.seed(7)
  coords <- matrix(runif(40), ncol = 2)

  A <- local_global_adjacency(coords, L = 2, K = 1, r = 0.15,
                              include_diagonal = TRUE,
                              symmetric = FALSE, normalized = FALSE)

  expect_equal(diag(as.matrix(A)), rep(1, nrow(coords)))
})

test_that("local_global_adjacency binary weight mode", {
  set.seed(42)
  coords <- matrix(runif(60), ncol = 2)

  A <- local_global_adjacency(coords, L = 3, K = 2, r = 0.2,
                              weight_mode = "binary",
                              symmetric = FALSE, normalized = FALSE)

  expect_true(inherits(A, "Matrix"))
  expect_equal(dim(A), c(nrow(coords), nrow(coords)))
  # binary: all non-zero weights should be 1 (before far penalty)
  expect_true(all(is.finite(A@x)))
  expect_true(all(A@x >= 0))
})

test_that("local_global_adjacency binary mode with exp far_penalty", {
  set.seed(43)
  coords <- matrix(runif(60), ncol = 2)

  A <- local_global_adjacency(coords, L = 2, K = 3, r = 0.15,
                              weight_mode = "binary",
                              far_penalty = "exp", tau = 0.1,
                              symmetric = FALSE, normalized = FALSE)

  expect_true(inherits(A, "Matrix"))
  expect_true(all(is.finite(A@x)))
})

test_that("local_global_adjacency with n=2 returns valid matrix", {
  coords <- matrix(c(0, 0, 1, 1), ncol = 2, byrow = TRUE)
  A <- local_global_adjacency(coords, L = 1, K = 0, r = 2,
                              weight_mode = "heat",
                              symmetric = TRUE, normalized = FALSE)
  expect_equal(dim(A), c(2, 2))
})

test_that("local_global_adjacency is permutation-equivariant", {
  set.seed(11)
  coords <- matrix(runif(60), ncol = 2)
  perm <- c(8, 3, 10, 1, 5, 2, 7, 4, 6, 9,
            11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
            21, 22, 23, 24, 25, 26, 27, 28, 29, 30)

  A1 <- local_global_adjacency(
    coords, L = 3, K = 2, r = 0.15,
    symmetric = FALSE, normalized = FALSE
  )
  A2 <- local_global_adjacency(
    coords[perm, , drop = FALSE], L = 3, K = 2, r = 0.15,
    symmetric = FALSE, normalized = FALSE
  )

  expect_equal(as.matrix(A2), as.matrix(A1)[perm, perm], tolerance = 1e-8)
})
