library(testthat)

test_that("HNSW remains faster than exact search on representative high-dimensional input", {
  skip_on_cran()
  skip_if_not_installed("RcppHNSW")
  skip_if_not(nzchar(Sys.getenv("NEIGHBORWEIGHTS_RUN_PERF")))

  set.seed(1)
  X <- matrix(rnorm(4000 * 64), nrow = 4000)

  t_nan <- system.time(
    graph_weights(X, k = 15, weight_mode = "binary",
                  neighbor_mode = "knn", backend = "nanoflann")
  )[["elapsed"]]
  t_hnsw <- system.time(
    graph_weights(X, k = 15, weight_mode = "binary",
                  neighbor_mode = "knn", backend = "hnsw", ef = 100)
  )[["elapsed"]]

  expect_lt(t_hnsw, t_nan)
})
