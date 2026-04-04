# Threshold Adjacency

This function extracts the k-nearest neighbors from an existing
adjacency matrix. It returns a new adjacency matrix containing only the
specified number of nearest neighbors.

## Usage

``` r
threshold_adjacency(A, k = 5, type = c("normal", "mutual"), ncores = 1)
```

## Arguments

- A:

  An adjacency matrix representing the graph.

- k:

  An integer specifying the number of neighbors to consider (default:
  5).

- type:

  A character string indicating the type of k-nearest neighbors graph to
  compute. One of "normal" or "mutual" (default: "normal").

- ncores:

  An integer specifying the number of cores to use for parallel
  computation (default: 1).

## Value

A sparse adjacency matrix containing only the specified number of
nearest neighbors.

## Examples

``` r
A <- matrix(runif(100), 10, 10)
A_thresholded <- threshold_adjacency(A, k = 5)
```
