# Within-Class Neighbors for class_graph Objects

Compute the within-class neighbors of a class_graph object.

## Usage

``` r
# S3 method for class 'class_graph'
within_class_neighbors(x, ng, ...)
```

## Arguments

- x:

  A class_graph object.

- ng:

  A neighbor graph object.

- ...:

  Additional arguments (currently ignored).

## Value

A neighbor_graph object representing the within-class neighbors of the
input class_graph.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
ng <- neighbor_graph(matrix(c(0,1,0,1,0,0,0,0,0),3))
within_class_neighbors(cg, ng)
#> $G
#> IGRAPH 38f997e U-W- 3 1 -- 
#> + attr: weight (e/n)
#> + edge from 38f997e:
#> [1] 1--2
#> 
#> $params
#> list()
#> 
#> attr(,"class")
#> [1] "neighbor_graph"
```
