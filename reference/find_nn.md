# Find nearest neighbors

Find nearest neighbors

## Usage

``` r
find_nn(x, ...)
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
find_nn(nn, k=2)
#> $labels
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    2    3
#> [3,]    3    1
#> [4,]    4    5
#> [5,]    5    4
#> 
#> $indices
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    2    3
#> [3,]    3    1
#> [4,]    4    5
#> [5,]    5    4
#> 
#> $distances
#>      [,1]     [,2]
#> [1,]    0 1.514573
#> [2,]    0 2.079928
#> [3,]    0 1.514573
#> [4,]    0 1.687891
#> [5,]    0 1.687891
#> 
#> attr(,"len")
#> [1] 4
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
# }
```
