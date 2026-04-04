#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(devtools)
  library(Matrix)
})

load_all()

set.seed(1)
n <- 10000
p <- 20
k <- 15
X <- matrix(rnorm(n * p), nrow = n)

sigma <- estimate_sigma(X, nsamples = 300)
cat("n =", n, "p =", p, "k =", k, "sigma =", sigma, "\n\n")

cat("legacy weighted_knn (Rnanoflann + igraph):\n")
print(system.time({
  W_legacy <- weighted_knn(
    X, k = k,
    FUN = function(d) heat_kernel(d, sigma = sigma),
    type = "normal",
    as = "sparse"
  )
}))
cat("nnz:", length(W_legacy@x), "\n\n")

cat("graph_weights_fast (nanoflann exact):\n")
print(system.time({
  W_fast_exact <- graph_weights_fast(
    X, k = k,
    weight_mode = "heat",
    type = "normal",
    backend = "nanoflann",
    sigma = sigma
  )
}))
cat("nnz:", length(W_fast_exact@x), "\n\n")

if (requireNamespace("RcppHNSW", quietly = TRUE)) {
  cat("graph_weights_fast (hnsw approximate):\n")
  print(system.time({
    W_fast_hnsw <- graph_weights_fast(
      X, k = k,
      weight_mode = "heat",
      type = "normal",
      backend = "hnsw",
      sigma = sigma,
      ef = 100
    )
  }))
  cat("nnz:", length(W_fast_hnsw@x), "\n")
}

