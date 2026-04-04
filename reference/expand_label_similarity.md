# Expand Similarity Between Labels Based on a Precomputed Similarity Matrix

Expands the similarity between labels based on a precomputed similarity
matrix, \`sim_mat\`, with either above-threshold or below-threshold
values depending on the value of the \`above\` parameter.

## Usage

``` r
expand_label_similarity(labels, sim_mat, threshold = 0, above = TRUE)
```

## Arguments

- labels:

  A vector of labels for which the similarities will be expanded.

- sim_mat:

  A precomputed similarity matrix containing similarities between the
  unique labels.

- threshold:

  A threshold value used to filter the expanded similarity values
  (default: 0).

- above:

  A boolean flag indicating whether to include the values above the
  threshold (default: TRUE) or below the threshold (FALSE).

## Value

A sparse symmetric similarity matrix with the expanded similarity
values.

## Examples

``` r
labels <- c("a","b","a")
smat <- matrix(c(1,.2,.2, 0.2,1,0.5, 0.2,0.5,1), nrow=3,
               dimnames=list(c("a","b","c"), c("a","b","c")))
expand_label_similarity(labels, smat, threshold=0.1)
#> 3 x 3 sparse Matrix of class "dsCMatrix"
#>                 
#> [1,] 1.0 0.2 1.0
#> [2,] 0.2 1.0 0.2
#> [3,] 1.0 0.2 1.0
```
