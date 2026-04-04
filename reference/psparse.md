# Apply a Function to Non-Zero Elements in a Sparse Matrix

This function applies a specified function (e.g., max) to each pair of
non-zero elements in a sparse matrix. It can return the result as a
triplet representation or a sparse matrix.

## Usage

``` r
psparse(M, FUN, return_triplet = FALSE)
```

## Arguments

- M:

  A sparse matrix object from the Matrix package.

- FUN:

  A function to apply to each pair of non-zero elements in the sparse
  matrix.

- return_triplet:

  A logical value indicating whether to return the result as a triplet
  representation. Default is FALSE.

## Value

If return_triplet is TRUE, a matrix containing the i, j, and x values in
the triplet format; otherwise, a sparse matrix with the updated values.

## Examples

``` r
library(Matrix)
M <- sparseMatrix(i = c(1, 3, 1), j = c(2, 3, 3), x = c(1, 2, 3))
psparse_max <- psparse(M, FUN = max)
psparse_sum_triplet <- psparse(M, FUN = `+`, return_triplet = TRUE)
```
