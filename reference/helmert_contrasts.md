# Build Helmert orthonormal contrasts

Creates orthonormal Helmert contrast matrices for a set of factors,
suitable for use with effect-coded kernels. The resulting contrasts are
orthonormal, which can improve numerical stability.

## Usage

``` r
helmert_contrasts(Ls)
```

## Arguments

- Ls:

  Named integer vector specifying the number of levels per factor

## Value

Named list of orthonormal contrast matrices, each of dimension L x (L-1)
where L is the number of levels for that factor. Each matrix has
orthonormal columns.

## Examples

``` r
contrasts <- helmert_contrasts(c(A=3, B=4))
print(dim(contrasts$A))  # 3 x 2
#> [1] 3 2
print(dim(contrasts$B))  # 4 x 3
#> [1] 4 3
```
