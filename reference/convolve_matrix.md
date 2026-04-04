# Convolve a Data Matrix with a Kernel Matrix

Performs right-multiplication of a data matrix \`X\` by a kernel matrix
\`Kern\`, optionally with symmetric normalization.

## Usage

``` r
convolve_matrix(X, Kern, normalize = FALSE)
```

## Arguments

- X:

  A data matrix to be transformed (n x p).

- Kern:

  A square kernel matrix (p x p) used for the transformation.

- normalize:

  A logical flag indicating whether to apply symmetric normalization
  D^(-1/2) Kern D^(-1/2) before multiplication (default: FALSE).

## Value

A matrix resulting from X %\*% Kern (or normalized version).

A matrix resulting from `X %*% Kern` (or the normalized version when
`normalize=TRUE`).

## Examples

``` r
X <- matrix(1:6, nrow=2)
K <- diag(3)
convolve_matrix(X, K)
#>      [,1] [,2] [,3]
#> [1,]    1    3    5
#> [2,]    2    4    6
```
