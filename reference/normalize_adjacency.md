# Normalize Adjacency Matrix

This function normalizes an adjacency matrix by dividing each element by
the product of the square root of the corresponding row and column sums.
Optionally, it can also symmetrize the normalized matrix by averaging it
with its transpose.

## Usage

``` r
normalize_adjacency(
  sm,
  symmetric = TRUE,
  handle_isolates = c("self_loop", "keep_zero", "drop")
)
```

## Arguments

- sm:

  A sparse adjacency matrix representing the graph.

- symmetric:

  A logical value indicating whether to symmetrize the matrix after
  normalization (default: TRUE).

- handle_isolates:

  How to treat zero-degree nodes when normalizing: "self_loop" adds a
  self-loop (default), "keep_zero" leaves them as zero, or "drop"
  removes them from the matrix.

## Value

A normalized and, if requested, symmetrized adjacency matrix.

## Examples

``` r
set.seed(123)
A <- matrix(runif(100), 10, 10)
A_normalized <- normalize_adjacency(A)
```
