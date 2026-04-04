# Compute the doubly stochastic matrix from a given matrix

This function iteratively computes the doubly stochastic matrix from a
given input matrix. A doubly stochastic matrix is a matrix in which both
row and column elements sum to 1.

## Usage

``` r
make_doubly_stochastic(A, iter = 30, tol = 1e-06)
```

## Arguments

- A:

  A numeric matrix for which to compute the doubly stochastic matrix

- iter:

  Integer, the number of iterations to perform (default is 30)

- tol:

  Numeric convergence tolerance; iteration stops when max row-sum
  deviation from 1 is below this value (default 1e-6)

## Value

A numeric matrix representing the computed doubly stochastic matrix

## Examples

``` r
A <- matrix(c(2, 4, 6, 8, 10, 12), nrow = 3, ncol = 2)

result <- make_doubly_stochastic(A, iter = 30)
```
