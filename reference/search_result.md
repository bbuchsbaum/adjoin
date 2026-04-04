# Search result for nearest neighbor search

Search result for nearest neighbor search

## Usage

``` r
search_result(x, result)
```

## Arguments

- x:

  An object of class "nnsearcher".

- result:

  The result from the nearest neighbor search.

## Value

An object with the class "nn_search".

## Examples

``` r
res <- list(idx = matrix(c(1L,2L), nrow=1),
            dist = matrix(c(0.1,0.2), nrow=1))
dummy <- nnsearcher(matrix(rnorm(4), nrow=2))
search_result(dummy, res)
#> $indices
#>      [,1] [,2]
#> [1,]    1    2
#> 
#> $distances
#>      [,1] [,2]
#> [1,]  0.1  0.2
#> 
#> attr(,"len")
#> [1] 2
#> attr(,"metric")
#> [1] "l2"
#> attr(,"class")
#> [1] "nn_search"
```
