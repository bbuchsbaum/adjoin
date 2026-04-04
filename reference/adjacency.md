# Extract Adjacency Matrix from Graph Objects

Extract the adjacency matrix from graph objects such as neighbor_graph
or nnsearch objects.

## Usage

``` r
adjacency(x, ...)
```

## Arguments

- x:

  A graph object (neighbor_graph, nnsearch, etc.).

- ...:

  Additional arguments passed to specific methods.

## Value

A sparse Matrix object representing the adjacency matrix.

## Examples

``` r
adj_matrix <- matrix(c(0,1,0,
                       1,0,1,
                       0,1,0), nrow=3, byrow=TRUE)
ng <- neighbor_graph(adj_matrix)
adjacency(ng)
#> 3 x 3 sparse Matrix of class "dgCMatrix"
#>           
#> [1,] . 1 .
#> [2,] 1 . 1
#> [3,] . 1 .
```
