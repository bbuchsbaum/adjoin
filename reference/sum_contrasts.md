# Build sum-to-zero contrasts

Creates sum-to-zero contrast matrices for a set of factors, suitable for
use with effect-coded kernels.

## Usage

``` r
sum_contrasts(Ls)
```

## Arguments

- Ls:

  Named integer vector specifying the number of levels per factor

## Value

Named list of contrast matrices, each of dimension L x (L-1) where L is
the number of levels for that factor. Each matrix has row sums of zero.

## Examples

``` r
contrasts <- sum_contrasts(c(A=3, B=4))
print(dim(contrasts$A))  # 3 x 2
#> [1] 3 2
print(dim(contrasts$B))  # 4 x 3
#> [1] 4 3
```
