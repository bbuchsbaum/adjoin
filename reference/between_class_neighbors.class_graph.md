# Between-Class Neighbors for class_graph Objects

Compute the between-class neighbors of a class_graph object.

## Usage

``` r
# S3 method for class 'class_graph'
between_class_neighbors(x, ng, ...)
```

## Arguments

- x:

  A class_graph object.

- ng:

  A neighbor_graph object.

- ...:

  Additional arguments (currently ignored).

## Value

A neighbor_graph object representing the between-class neighbors.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
ng <- neighbor_graph(matrix(c(0,1,1,1,0,1,1,1,0),3))
between_class_neighbors(cg, ng)
#> $G
#> IGRAPH f91f644 U-W- 3 3 -- 
#> + attr: weight (e/n)
#> + edges from f91f644:
#> [1] 1--2 1--3 2--3
#> 
#> $params
#> list()
#> 
#> attr(,"class")
#> [1] "neighbor_graph"
```
