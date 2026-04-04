# Create a Binary Label Adjacency Matrix (All Pairs)

Constructs a binary adjacency matrix based on two sets of labels \`a\`
and \`b\`, creating edges for ALL pairs (i, j) where labels match
(type="s") or differ (type="d"). This computes the full cross-product
comparison between the two label vectors.

## Usage

``` r
binary_label_matrix(a, b = NULL, type = c("s", "d"))
```

## Arguments

- a:

  A vector of labels for the first set of data points.

- b:

  A vector of labels for the second set of data points (default: NULL).
  If NULL, \`b\` will be set to \`a\`.

- type:

  A character specifying the type of adjacency matrix to create, either
  "s" for same labels or "d" for different labels (default: "s").

## Value

A sparse binary adjacency matrix of dimensions (length(a) x length(b))
with 1s where the label relationship holds.

## Details

For type="s", the result is a block-diagonal structure when a==b, with
blocks corresponding to each class. For type="d", the result is the
complement.

This function uses efficient sparse matrix multiplication via indicator
matrices, avoiding O(n^2) memory usage from expanding all pairs.

## See also

[`diagonal_label_matrix`](https://bbuchsbaum.github.io/graphweights/reference/diagonal_label_matrix.md)
for element-wise (positional) comparison

## Examples

``` r
data(iris)
a <- iris[,5]
bl <- binary_label_matrix(a, type="d")
```
