# Nearest Neighbor Searcher

Create a nearest neighbor searcher object for efficient nearest neighbor
search. Uses Rnanoflann (exact Euclidean search) by default, or RcppHNSW
(approximate search with cosine/inner-product support) when those
distance metrics are requested.

## Usage

``` r
nnsearcher(
  X,
  labels = 1:nrow(X),
  ...,
  distance = c("l2", "euclidean", "cosine", "ip"),
  M = 16,
  ef = 200
)
```

## Arguments

- X:

  A numeric matrix where each row represents a data point.

- labels:

  A vector of labels corresponding to each row in X. Defaults to row
  indices.

- ...:

  Additional arguments (currently unused).

- distance:

  The distance metric to use. One of "l2", "euclidean", "cosine", or
  "ip". Note: "cosine" and "ip" require the RcppHNSW package.

- M:

  The maximum number of connections for HNSW (only used with cosine/ip).

- ef:

  The size of the dynamic candidate list for HNSW (only used with
  cosine/ip).

## Value

An object of class "nnsearcher" containing the data matrix, labels,
search index, and search parameters.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(100), nrow=10, ncol=10)
searcher <- nnsearcher(X)
# }
```
