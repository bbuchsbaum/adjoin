# Square root and inverse square root of a PSD kernel

Computes the matrix square root and inverse square root of a positive
semi-definite kernel using eigendecomposition with optional
regularization.

## Usage

``` r
kernel_roots(K, jitter = 1e-10)
```

## Arguments

- K:

  Symmetric positive semi-definite matrix

- jitter:

  Small ridge parameter to ensure numerical stability (default 1e-10)

## Value

A list containing:

- Khalf:

  The matrix square root K^(1/2) with same dimensions as K

- Kihalf:

  The matrix inverse square root K^(-1/2) with same dimensions as K

- evals:

  Eigenvalues (after jitter adjustment)

- evecs:

  Eigenvectors matrix

## Details

For a positive semi-definite matrix K, this function computes K^(1/2)
and K^(-1/2) using the eigendecomposition K = V \* diag(lambda) \* V',
where K^(1/2) = V \* diag(sqrt(lambda)) \* V' and K^(-1/2) = V \*
diag(1/sqrt(lambda)) \* V'. The jitter parameter adds a small ridge to
eigenvalues to prevent numerical issues with near-zero eigenvalues.

## Examples

``` r
K <- matrix(c(2, 1, 1, 2), 2, 2)
result <- kernel_roots(K)
print(dim(result$Khalf))  # 2x2
#> [1] 2 2
```
