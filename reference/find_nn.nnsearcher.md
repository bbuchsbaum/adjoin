# Find Nearest Neighbors Using nnsearcher

Search for the k nearest neighbors using a pre-built nnsearcher object.

## Usage

``` r
# S3 method for class 'nnsearcher'
find_nn(x, query = NULL, k = 5, ...)
```

## Arguments

- x:

  An object of class "nnsearcher".

- query:

  A matrix of query points. If NULL, searches within the original data.

- k:

  The number of nearest neighbors to find.

- ...:

  Additional arguments (currently unused).

## Value

An object of class "nn_search" containing indices, distances, and
labels.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(100), nrow=10, ncol=10)
searcher <- nnsearcher(X)
result <- find_nn(searcher, k=3)
# }
```
