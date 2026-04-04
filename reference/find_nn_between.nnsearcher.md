# Find Nearest Neighbors Between Two Sets Using nnsearcher

Search for the k nearest neighbors from one set of points to another
set.

## Usage

``` r
# S3 method for class 'nnsearcher'
find_nn_between(x, k = 5, idx1, idx2, restricted = FALSE, ...)
```

## Arguments

- x:

  An object of class "nnsearcher".

- k:

  The number of nearest neighbors to find.

- idx1:

  A numeric vector specifying indices of the first set of points.

- idx2:

  A numeric vector specifying indices of the second set of points.

- restricted:

  Logical; if TRUE, use restricted search mode.

- ...:

  Additional arguments (currently unused).

## Value

An object of class "nn_search" containing indices, distances, and
labels.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(40), nrow=10)
searcher <- nnsearcher(X)
find_nn_between(searcher, k=2, idx1=1:5, idx2=6:10)
#> $labels
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    4    5
#> [3,]    5    4
#> [4,]    1    3
#> [5,]    4    5
#> 
#> $indices
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    4    5
#> [3,]    5    4
#> [4,]    1    3
#> [5,]    4    5
#> 
#> $distances
#>           [,1]      [,2]
#> [1,] 0.5305985 0.8572827
#> [2,] 1.7245125 2.0161334
#> [3,] 1.9200052 2.3155429
#> [4,] 0.6798527 1.1210416
#> [5,] 1.5298232 1.5455261
#> 
#> attr(,"len")
#> [1] 4
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
# }
```
