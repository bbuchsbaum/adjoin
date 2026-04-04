# Print method for repulsion_graph objects

Print method for repulsion_graph objects

## Usage

``` r
# S3 method for class 'repulsion_graph'
print(x, ...)
```

## Arguments

- x:

  A repulsion_graph object

- ...:

  Additional arguments passed to print

## Value

The input `x`, invisibly.

## Examples

``` r
coords <- matrix(c(0,0,1,0), ncol=2, byrow=TRUE)
W <- neighbor_graph(spatial_adjacency(coords, nnk=2, sigma=1))
cg <- class_graph(factor(c(1,2)))
rg <- repulsion_graph(W, cg)
print(rg)
#> Repulsion Graph Object
#> ----------------------
#> $G
#> IGRAPH 64d75b2 U-W- 2 1 -- 
#> + attr: weight (e/n)
#> + edge from 64d75b2:
#> [1] 1--2
#> 
#> $params
#> $params$method
#> [1] "weighted"
#> 
#> $params$threshold
#> [1] 0
#> 
#> $params$norm_fac
#> [1] 1
#> 
#> $params$original_W_type
#> [1] "neighbor_graph"
#> 
#> $params$original_cg_levels
#> [1] "1" "2"
#> 
#> 
#> attr(,"class")
#> [1] "repulsion_graph" "neighbor_graph" 
#> Repulsion Params:
#>   Method: weighted 
#>   Normalization Factor: 1 
#>   Input Threshold: 0 
#> ----------------------
```
