# Within-Class Neighbors

A generic function to compute the within-class neighbors of a graph.

## Usage

``` r
within_class_neighbors(x, ng, ...)
```

## Arguments

- x:

  An object.

- ng:

  A neighbor graph object.

- ...:

  Additional arguments passed to specific methods.

## Value

An object representing the within-class neighbors of the input graph,
the structure of which depends on the input object's class.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
ng <- neighbor_graph(diag(3))
within_class_neighbors(cg, ng)
#> $G
#> IGRAPH 4934752 U--- 3 0 -- 
#> + edges from 4934752:
#> 
#> $params
#> list()
#> 
#> attr(,"class")
#> [1] "neighbor_graph"
```
