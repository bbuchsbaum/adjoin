# Diagonal Label Comparison with NA Handling

Compares labels at corresponding positions (element-wise) between two
equal-length vectors \`a\` and \`b\`, with explicit NA handling. Creates
a sparse matrix with entries only on the diagonal.

## Usage

``` r
diagonal_label_matrix_na(
  a,
  b,
  type = c("s", "d"),
  return_matrix = TRUE,
  dim1 = length(a),
  dim2 = length(b)
)
```

## Arguments

- a:

  The first categorical label vector.

- b:

  The second categorical label vector. Must have same length as \`a\`.

- type:

  The type of comparison: "s" for same labels (a\[i\] == b\[i\]) or "d"
  for different labels (a\[i\] != b\[i\]). Default is "s".

- return_matrix:

  A logical flag indicating whether to return the result as a sparse
  matrix (default: TRUE) or a triplet matrix with columns (i, j, x).

- dim1:

  The row dimension of the output matrix (default: length(a)).

- dim2:

  The column dimension of the output matrix (default: length(b)).

## Value

If return_matrix is TRUE, a sparse diagonal matrix where entry (i, i) is
1 if the labels at position i satisfy the comparison (and neither is
NA). If return_matrix is FALSE, a 3-column matrix of (row, col, value)
triplets.

## Details

This function performs element-wise (positional) comparison, NOT
all-pairs comparison. Positions where either label is NA are excluded
from the result.

For all-pairs comparison (block structure), use
[`binary_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/binary_label_matrix.md).
For diagonal comparison without NA handling, use
[`diagonal_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/diagonal_label_matrix.md).

## See also

[`binary_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/binary_label_matrix.md),
[`diagonal_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/diagonal_label_matrix.md)

## Examples

``` r
a <- c("x","y", NA)
b <- c("x","y","y")
diagonal_label_matrix_na(a, b, type="s", return_matrix=TRUE)
#> 3 x 3 sparse Matrix of class "dgCMatrix"
#>           
#> [1,] 1 . .
#> [2,] . 1 .
#> [3,] . . .
```
