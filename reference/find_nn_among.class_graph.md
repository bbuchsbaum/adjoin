# Find Nearest Neighbors Among Classes

Find the nearest neighbors within each class for a class_graph object.

## Usage

``` r
# S3 method for class 'class_graph'
find_nn_among(x, X, k = 5, ...)
```

## Arguments

- x:

  A class_graph object.

- X:

  The data matrix corresponding to the graph nodes.

- k:

  The number of nearest neighbors to find.

- ...:

  Additional arguments (currently unused).

## Value

A search result object containing indices, distances, and labels.

## Examples

``` r
# \donttest{
labs <- factor(c("a","a","b","b"))
cg <- class_graph(labs)
X <- matrix(rnorm(12), nrow=4)
find_nn_among(cg, X, k=1)
#> $labels
#>      [,1]
#> [1,] "a" 
#> [2,] "a" 
#> [3,] "b" 
#> [4,] "b" 
#> 
#> $indices
#>      [,1]
#> [1,]    1
#> [2,]    2
#> [3,]    3
#> [4,]    4
#> 
#> $distances
#>      [,1]
#> [1,]    0
#> [2,]    0
#> [3,]    0
#> [4,]    0
#> 
#> attr(,"len")
#> [1] 3
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
# }
```
