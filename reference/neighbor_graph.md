# Neighbor Graph

A generic function to create a neighbor_graph object.

Create a neighbor_graph object from an igraph object or Matrix object.

## Usage

``` r
neighbor_graph(x, ...)

# S3 method for class 'igraph'
neighbor_graph(x, params = list(), type = NULL, classes = NULL, ...)

# S3 method for class 'Matrix'
neighbor_graph(x, params = list(), type = NULL, classes = NULL, ...)

# S3 method for class 'matrix'
neighbor_graph(x, params = list(), type = NULL, classes = NULL, ...)
```

## Arguments

- x:

  An igraph or Matrix object.

- ...:

  Additional arguments.

- params:

  A list of parameters (default: empty list).

- type:

  A character string specifying the type of graph (currently unused).

- classes:

  A character vector specifying additional classes for the object.

## Value

A neighbor_graph object, the structure of which depends on the input
object's class.

A neighbor_graph object wrapping the input graph structure.

## Examples

``` r
library(igraph)
#> 
#> Attaching package: ‘igraph’
#> The following objects are masked from ‘package:purrr’:
#> 
#>     compose, simplify
#> The following objects are masked from ‘package:future’:
#> 
#>     %->%, %<-%
#> The following objects are masked from ‘package:adjoin’:
#> 
#>     edges, neighbors
#> The following objects are masked from ‘package:stats’:
#> 
#>     decompose, spectrum
#> The following object is masked from ‘package:base’:
#> 
#>     union
g <- make_ring(5)
ng1 <- neighbor_graph(g)

adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), 
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng2 <- neighbor_graph(adj_matrix)
```
