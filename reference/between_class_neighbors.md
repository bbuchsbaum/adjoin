# Between-Class Neighbors

A generic function to compute the between-class neighbors of a graph.

## Usage

``` r
between_class_neighbors(x, ng, ...)
```

## Arguments

- x:

  An object.

- ng:

  A neighbor graph object.

- ...:

  Additional arguments passed to specific methods.

## Value

An object representing the between-class neighbors of the input graph,
the structure of which depends on the input object's class.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
ng <- neighbor_graph(matrix(c(0,1,1,1,0,1,1,1,0),3))
between_class_neighbors(cg, ng)
#> $G
#> IGRAPH 1aae20d U-W- 3 3 -- 
#> + attr: weight (e/n)
#> + edges from 1aae20d:
#> [1] 1--2 1--3 2--3
#> 
#> $params
#> list()
#> 
#> attr(,"class")
#> [1] "neighbor_graph"
```
