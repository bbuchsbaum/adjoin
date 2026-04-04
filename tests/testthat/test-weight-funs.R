library(testthat)
library(Matrix)
library(adjoin)

test_that("fspatial_weights spatial-only matches Gaussian kernel", {
  indices <- list(c(2L), c(1L))
  dists   <- list(c(1),  c(1))
  feats   <- matrix(c(0, 1), ncol = 1)

  res <- adjoin:::fspatial_weights(indices, dists, feats,
                          sigma = 1, fsigma = 1,
                          alpha = 1, binary = FALSE)
  expect_equal(nrow(res), 2)
  expect_true(all(res[,3] > 0))
  expected <- exp(-1/2)
  expect_equal(res[,3], rep(expected, 2), tolerance = 1e-8)
})

test_that("fspatial_weights feature-only matches normalized_heat_kernel formula", {
  indices <- list(c(2L), c(1L))
  dists   <- list(c(0.5),  c(0.5))   # spatial ignored (alpha=0)
  feats   <- matrix(c(0, 1), ncol = 1)

  res <- adjoin:::fspatial_weights(indices, dists, feats,
                          sigma = 1, fsigma = 1,
                          alpha = 0, binary = FALSE)
  expect_equal(nrow(res), 2)
  # normalized_heat_kernel: exp(-(dist^2/(2*len)) / (2*fsigma^2))
  expected <- exp(- (1 / 2) / 2)
  expect_equal(res[,3], rep(expected, 2), tolerance = 1e-8)
})

test_that("expand_similarity_cpp filters by threshold and returns triplets", {
  idx  <- c(1L, 2L, 3L)
  mat  <- matrix(c(1, 0.2, 0.6,
                   0.2, 1, 0.4,
                   0.6, 0.4, 1), nrow = 3, byrow = TRUE)
  out <- adjoin:::expand_similarity_cpp(idx, mat, thresh = 0.5)
  # Should keep (1,1),(1,3),(2,2),(3,3)
  expect_true(nrow(out) >= 3)
  expect_true(all(out[,3] > 0.5))
})

test_that("expand_similarity_below_cpp keeps only below threshold", {
  idx  <- c(1L, 2L, 3L)
  mat  <- matrix(c(1, 0.2, 0.6,
                   0.2, 1, 0.4,
                   0.6, 0.4, 1), nrow = 3, byrow = TRUE)
  out <- adjoin:::expand_similarity_below_cpp(idx, mat, thresh = 0.5)
  expect_true(all(out[,3] < 0.5))
})

test_that("cross_fspatial_weights respects maxk and picks top weights", {
  indices <- list(c(1L,3L), c(1L,3L))   # two query points
  dists   <- list(c(1, 1.5), c(1, 0.2))
  f1 <- matrix(c(0,0), ncol=1, byrow=TRUE)
  f2 <- matrix(c(0, 2, 0.1), ncol=1, byrow=TRUE)       # neighbor1 matches, neighbor3 near for query2
  res <- adjoin:::cross_fspatial_weights(indices, dists, f1, f2,
                                                  sigma=1, fsigma=1, alpha=0.5,
                                                  maxk=1, binary=FALSE)
  expect_equal(nrow(res), 2) # one edge per query
  expect_setequal(res[,1], c(1,2))
  # query1 should keep neighbor 1 (closest feature); query2 should keep neighbor3
  sel1 <- res[res[,1]==1,2]
  sel2 <- res[res[,1]==2,2]
  expect_equal(sel1, 1)
  expect_equal(sel2, 3)
})
