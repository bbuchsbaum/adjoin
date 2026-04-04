# Create a Diagonal Label Comparison Matrix (Element-wise)

Compares labels at corresponding positions (element-wise) between two
equal-length vectors \`a\` and \`b\`. Creates a sparse matrix with
entries only on the diagonal, where position (i, i) is 1 if \`a\[i\]\`
and \`b\[i\]\` satisfy the comparison.

## Usage

``` r
diagonal_label_matrix(
  a,
  b,
  type = c("s", "d"),
  dim1 = length(a),
  dim2 = length(b)
)
```

## Arguments

- a:

  A vector of labels for the first set of data points.

- b:

  A vector of labels for the second set of data points. Must have same
  length as \`a\`.

- type:

  A character specifying the comparison type: "s" for same labels
  (a\[i\] == b\[i\]) or "d" for different labels (a\[i\] != b\[i\]).
  Default is "s".

- dim1:

  The row dimension of the output matrix (default: length(a)).

- dim2:

  The column dimension of the output matrix (default: length(b)).

## Value

A sparse diagonal matrix where entry (i, i) is 1 if the labels at
position i satisfy the comparison, 0 otherwise.

## Details

This function performs element-wise comparison, NOT all-pairs
comparison. For all-pairs comparison (block structure), use
[`binary_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/binary_label_matrix.md).

The vectors \`a\` and \`b\` must have the same length. If they differ,
recycling will occur which is likely unintended.

## See also

[`binary_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/binary_label_matrix.md)
for all-pairs comparison

## Examples

``` r
a <- factor(c("x","y","x"))
b <- factor(c("x","x","y"))
diagonal_label_matrix(a, b, type="d")
#> 3 x 3 sparse Matrix of class "dgCMatrix"
#>           
#> [1,] . . .
#> [2,] . 1 .
#> [3,] . . 1
```
