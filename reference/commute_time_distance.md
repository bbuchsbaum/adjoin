# Compute the commute-time distance between nodes in a graph

This function computes the commute-time distance between nodes in a
graph using either eigenvalue or pseudoinverse methods.

## Usage

``` r
commute_time_distance(A, ncomp = nrow(A) - 1)
```

## Arguments

- A:

  A symmetric, non-negative matrix representing the adjacency matrix of
  the graph

- ncomp:

  Integer, number of components to use in the computation, default is
  (nrow(A) - 1)

## Value

A list with the following components:

- eigenvectors:

  Matrix, eigenvectors of the matrix M

- eigenvalues:

  Vector, eigenvalues of the matrix M

- cds:

  Matrix, the computed commute-time distances

- gap:

  Numeric, the gap between the two largest eigenvalues

The returned object has class "commute_time" and "list".

## Examples

``` r
A <- matrix(c(0, 1, 1, 0,
             1, 0, 1, 1,
             1, 1, 0, 1,
             0, 1, 1, 0), nrow = 4, byrow = TRUE)

result <- commute_time_distance(A)
#> Warning: all eigenvalues are requested, eigen() is used instead
```
