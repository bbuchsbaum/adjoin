library(testthat)
library(Matrix)
library(neighborweights)

dominant_modulus <- function(M) {
  max(Mod(eigen(as.matrix(M), only.values = TRUE)$values))
}

test_that("spatial_constraints single block has normalized spectral radius and finite values", {
  coords <- as.matrix(expand.grid(1:3, 1:3))
  S <- spatial_constraints(coords, nblocks = 1,
                           sigma_within = 1, nnk_within = 4)
  expect_equal(dim(S), c(nrow(coords), nrow(coords)))
  expect_true(all(is.finite(S@x)))
  expect_lt(abs(dominant_modulus(S) - 1), 1e-6)
})

test_that("spatial_constraints two blocks yields normalized spectral radius", {
  coords_list <- list(matrix(c(0,0, 1,0), ncol = 2, byrow = TRUE),
                      matrix(c(0,1, 1,1), ncol = 2, byrow = TRUE))
  S <- spatial_constraints(coords_list, nblocks = 2,
                           sigma_within = 1, sigma_between = 1,
                           nnk_within = 2, nnk_between = 2,
                           shrinkage_factor = 0.2)
  expect_equal(dim(S), c(4, 4))
  expect_true(all(is.finite(S@x)))
  expect_lt(abs(dominant_modulus(S) - 1), 1e-6)
})

test_that("spatial_constraints with matrix coords and nblocks > 1 is valid", {
  coords <- as.matrix(expand.grid(1:2, 1:2))
  S <- spatial_constraints(
    coords, nblocks = 3,
    sigma_within = 1, sigma_between = 1,
    nnk_within = 3, nnk_between = 2,
    shrinkage_factor = 0.25
  )
  expect_equal(dim(S), c(12, 12))
  expect_true(all(is.finite(S@x)))
  expect_lt(abs(dominant_modulus(S) - 1), 1e-6)
})

test_that("spatial_constraints infers nblocks from coords list", {
  coords_list <- list(
    matrix(c(0,0, 1,0), ncol = 2, byrow = TRUE),
    matrix(c(0,1, 1,1), ncol = 2, byrow = TRUE)
  )
  S <- spatial_constraints(
    coords_list,
    sigma_within = 1, sigma_between = 1,
    nnk_within = 2, nnk_between = 2,
    shrinkage_factor = 0.2
  )
  expect_equal(dim(S), c(4, 4))
})

test_that("spatial_constraints rejects mismatched nblocks for list coords", {
  coords_list <- list(
    matrix(c(0,0, 1,0), ncol = 2, byrow = TRUE),
    matrix(c(0,1, 1,1), ncol = 2, byrow = TRUE)
  )
  expect_error(
    spatial_constraints(coords_list, nblocks = 3),
    "must match `length\\(coords\\)`"
  )
})

# Regression: spatial_constraints() with a single coord matrix and nblocks > 1
# failed in older package versions because `coords[[i]]` on a matrix extracts
# a column vector rather than a sub-matrix, producing NULL dims inside
# sparseMatrix().  The safe calling convention is to pass a list of coord
# matrices (one per block) with an explicit nblocks argument.
test_that("spatial_constraints list-of-coords with repeated grid produces correct n*nblocks dims", {
  coords <- as.matrix(expand.grid(x = 1:4, y = 1:4))   # 16 locations
  n <- nrow(coords)

  S <- spatial_constraints(
    list(coords, coords), nblocks = 2,
    sigma_within  = 1.5, nnk_within  = 6,
    sigma_between = 2.0, nnk_between = 4,
    shrinkage_factor = 0.15
  )

  expect_equal(dim(S), c(n * 2L, n * 2L),
               info = "result must be (n*nblocks) x (n*nblocks)")
  expect_true(all(is.finite(S@x)),
              info = "all constraint weights must be finite")
  # Leading eigenvalue normalised to 1
  ev <- RSpectra::eigs_sym(S, k = 1, which = "LA")$values[1]
  expect_lt(abs(ev - 1), 1e-4)
})

test_that("feature_weighted_spatial_constraints returns finite normalized matrix", {
  set.seed(123)
  coords <- matrix(c(0,0, 1,0, 0,1), ncol = 2, byrow = TRUE)
  feats <- list(matrix(rnorm(3*2), 2, 3),
                matrix(rnorm(3*2), 2, 3))
  S <- suppressWarnings(
    feature_weighted_spatial_constraints(coords, feats,
                                         sigma_within = 1.2, sigma_between = 1.2,
                                         nnk_within = 2, nnk_between = 2,
                                         maxk_within = 2, maxk_between = 2,
                                         shrinkage_factor = 0.3)
  )
  expect_equal(dim(S), c(6, 6))
  expect_true(all(is.finite(S@x)))
  expect_lt(abs(dominant_modulus(S) - 1), 0.01)
})
