# Weighted k-Nearest Neighbors

This function computes a weighted k-nearest neighbors graph or adjacency
matrix from a data matrix. The function takes into account the Euclidean
distance between instances and applies a kernel function to convert the
distances into similarities.

## Usage

``` r
weighted_knn(
  X,
  k = 5,
  FUN = heat_kernel,
  type = c("normal", "mutual", "asym"),
  as = c("igraph", "sparse"),
  backend = c("nanoflann", "hnsw"),
  M = 16,
  ef = 200,
  ...
)
```

## Arguments

- X:

  A data matrix where rows are instances and columns are features.

- k:

  An integer specifying the number of nearest neighbors to consider
  (default: 5).

- FUN:

  A kernel function used to convert Euclidean distances into
  similarities (default: heat_kernel).

- type:

  A character string indicating the type of k-nearest neighbors graph to
  compute. One of "normal", "mutual", or "asym" (default: "normal").

- as:

  A character string specifying the format of the output. One of
  "igraph" or "sparse" (default: "igraph").

- backend:

  Nearest-neighbor backend. \`"nanoflann"\` uses exact Euclidean search;
  \`"hnsw"\` uses approximate search via \`RcppHNSW\`.

- M, ef:

  HNSW tuning parameters used only when \`backend="hnsw"\`.

- ...:

  Additional arguments passed to the nearest neighbor search function
  (Rnanoflann::nn).

## Value

If 'as' is "igraph", an igraph object representing the weighted
k-nearest neighbors graph. If 'as' is "sparse", a sparse adjacency
matrix.

## Details

Distances passed to \`FUN\` are Euclidean distances. With
\`backend="hnsw"\`, squared L2 distances from \`RcppHNSW\` are converted
back to Euclidean distances before weighting.

## Examples

``` r
X <- matrix(rnorm(10 * 10), 10, 10)
w <- weighted_knn(X, k = 5)
```
