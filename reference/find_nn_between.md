# Find nearest neighbors between two sets of data points

Find nearest neighbors between two sets of data points

## Usage

``` r
find_nn_between(x, ...)
```

## Arguments

- x:

  An object of class "nnsearcher".

- ...:

  Further arguments passed to or from other methods.

## Value

A nearest neighbors result object.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(20), nrow=5)
nn <- nnsearcher(X)
find_nn_between(nn, k=1, idx1=1:2, idx2=3:5)
#> $labels
#>      [,1]
#> [1,]    1
#> [2,]    1
#> [3,]    1
#> 
#> $indices
#>      [,1]
#> [1,]    1
#> [2,]    1
#> [3,]    1
#> 
#> $distances
#>          [,1]
#> [1,] 2.793294
#> [2,] 2.665216
#> [3,] 1.572280
#> 
#> attr(,"len")
#> [1] 4
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
# }
```
