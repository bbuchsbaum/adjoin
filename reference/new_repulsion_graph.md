# Constructor for Repulsion Graph Objects (Internal)

Constructor for Repulsion Graph Objects (Internal)

## Usage

``` r
new_repulsion_graph(adjacency_matrix, params = list(), ...)
```

## Arguments

- adjacency_matrix:

  The final sparse adjacency matrix of the repulsion graph.

- params:

  A list of parameters used in its construction.

- ...:

  Additional attributes to store (inherited from neighbor_graph).

## Value

An object of class \`c("repulsion_graph", "neighbor_graph")\`.
