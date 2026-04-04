# Compute the temporal autocorrelation of a matrix

This function computes the temporal autocorrelation of a given matrix
using a specified window size and optionally inverts the correlation
matrix.

## Usage

``` r
temporal_autocor(X, window = 3, inverse = FALSE)
```

## Arguments

- X:

  A numeric matrix for which to compute the temporal autocorrelation

- window:

  integer, the window size for computing the autocorrelation, must be
  between 1 and ncol(X) (default is 3)

- inverse:

  logical, whether to compute the inverse of the correlation matrix
  (default is FALSE)

## Value

A sparse symmetric matrix representing the computed temporal
autocorrelation

## Examples

``` r
X <- matrix(rnorm(50), nrow = 10, ncol = 5)

result <- temporal_autocor(X, window = 2)
```
