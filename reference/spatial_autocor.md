# Compute a spatial autocorrelation matrix

This function computes a spatial autocorrelation matrix using a
radius-based nearest neighbor search. The function leverages the mgcv
package to fit a generalized additive model (GAM) to the data and
constructs the autocorrelation matrix using the fitted model.

## Usage

``` r
spatial_autocor(X, cds, radius = 8, nsamples = 1000, maxk = 64)
```

## Arguments

- X:

  A numeric matrix or data.frame, where each column represents a
  variable and each row represents an observation.

- cds:

  A numeric matrix or data.frame of spatial coordinates (x, y, or more
  dimensions) with the same number of rows as X.

- radius:

  A positive numeric value representing the search radius for the
  radius-based nearest neighbor search. Default is 8.

- nsamples:

  A positive integer indicating the number of samples to be taken for
  fitting the GAM. Default is 1000.

- maxk:

  Maximum number of neighbors to request from the NN search before
  radius filtering (prevents O(n^2) memory). Default 64.

## Value

A sparse matrix representing the spatial autocorrelation matrix for the
input data.

## Examples

``` r
# \donttest{
set.seed(1)
cds <- as.matrix(expand.grid(1:10, 1:10))
X <- matrix(rnorm(5*nrow(cds)), nrow=5, ncol=nrow(cds))
S <- spatial_autocor(X, cds, radius=5, nsamples=100, maxk=50)
dim(S)
#> [1] 100 100
# }
```
