# Find Nearest Neighbors Among Subset Using nnsearcher

Search for the k nearest neighbors within a specified subset of points.

## Usage

``` r
# S3 method for class 'nnsearcher'
find_nn_among(x, k = 5, idx, ...)
```

## Arguments

- x:

  An object of class "nnsearcher".

- k:

  The number of nearest neighbors to find.

- idx:

  A numeric vector specifying the subset of point indices to search
  among.

- ...:

  Additional arguments (currently unused).

## Value

An object of class "nn_search" containing indices, distances, and
labels.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(20), nrow=5)
searcher <- nnsearcher(X)
find_nn_among(searcher, k=2, idx=1:3)
#> $indices
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    2    3
#> [3,]    3    1
#> 
#> $distances
#>      [,1]     [,2]
#> [1,]    0 2.949371
#> [2,]    0 3.635629
#> [3,]    0 2.949371
#> 
#> attr(,"len")
#> [1] 4
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
# }
```
