# Find nearest neighbors among a subset

Find nearest neighbors among a subset

## Usage

``` r
find_nn_among(x, ...)
```

## Arguments

- x:

  An object of class "nnsearcher" or "class_graph".

- ...:

  Further arguments passed to or from other methods.

## Value

A nearest neighbors result object.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(20), nrow=5)
nn <- nnsearcher(X)
find_nn_among(nn, k=2, idx=1:3)
#> $indices
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    2    3
#> [3,]    3    2
#> 
#> $distances
#>      [,1]     [,2]
#> [1,]    0 2.766934
#> [2,]    0 1.955822
#> [3,]    0 1.955822
#> 
#> attr(,"len")
#> [1] 4
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
# }
```
