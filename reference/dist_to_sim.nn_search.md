# Convert Distance to Similarity for nn_search Objects

Convert distance values in a nearest neighbor search result to
similarity values.

## Usage

``` r
# S3 method for class 'nn_search'
dist_to_sim(
  x,
  method = c("heat", "binary", "normalized", "cosine", "correlation"),
  sigma = 1,
  ...
)
```

## Arguments

- x:

  An object of class "nn_search".

- method:

  The transformation method for converting distances to similarities.

- sigma:

  The bandwidth parameter for the heat kernel method.

- ...:

  Additional arguments (currently ignored).

## Value

The modified nn_search object with distances converted to similarities.

## Examples

``` r
res <- list(indices = matrix(c(1L,2L), nrow=1),
            distances = matrix(c(0.5, 1.0), nrow=1))
class(res) <- "nn_search"; attr(res,"len") <- 2; attr(res,"metric") <- "l2"
dist_to_sim(res, method="heat", sigma=1)
#> $indices
#>      [,1] [,2]
#> [1,]    1    2
#> 
#> $distances
#>           [,1]      [,2]
#> [1,] 0.8824969 0.6065307
#> 
#> attr(,"class")
#> [1] "nn_search"
#> attr(,"len")
#> [1] 2
#> attr(,"metric")
#> [1] "l2"
```
