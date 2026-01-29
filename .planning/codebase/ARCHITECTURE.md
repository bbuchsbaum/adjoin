# Architecture

**Analysis Date:** 2026-01-28

## Pattern Overview

**Overall:** Modular graph construction library with polymorphic dispatch

The `neighborweights` package implements a graph construction architecture using S3 object-oriented design. The core pattern revolves around:
- Generic functions that dispatch to specialized implementations
- Multiple entry points for graph construction (spatial coordinates, feature similarity, class labels, NN search results)
- Sparse matrix representation throughout (dgCMatrix from Matrix package)
- Underlying igraph objects wrapped by `neighbor_graph` class for uniform interface
- Performance-critical operations in C++ (Rcpp/RcppArmadillo)

**Key Characteristics:**
- Functional composition: Functions take adjacency matrices/graphs and transform them
- Lazy evaluation where possible (graph stored in igraph format until extraction)
- Dual dense/sparse support with consistent output formats
- S3 method dispatch for extensibility without modifying core code

## Layers

**Generic Interface Layer:**
- Purpose: Defines S3 generic functions for public API
- Location: `R/all_generic.R`
- Contains: 25+ generic function stubs (adjacency, laplacian, neighbors, etc.)
- Depends on: Nothing; purely declarative
- Used by: All concrete implementations below

**Graph Construction Layer:**
- Purpose: Create graph objects from various input formats
- Location: `R/neighbor_graph.R`, `R/class_graph.R`
- Contains:
  - `neighbor_graph()` - wraps Matrix/igraph as neighbor_graph object
  - `class_graph()` - creates adjacency from class labels (sparse tcrossprod)
  - Implementations for matrix, igraph, and Matrix inputs
- Depends on: igraph, Matrix
- Used by: All weight computation functions

**Nearest Neighbor Search Layer:**
- Purpose: Efficient NN search with multiple backend algorithms
- Location: `R/searcher.R`
- Contains:
  - `nnsearcher()` - HNSW-based NN searcher (RcppHNSW)
  - `find_nn()`, `find_nn_among()`, `find_nn_between()` - search operations
  - `search_result()` - standardizes output format
- Depends on: RcppHNSW, Rnanoflann
- Used by: knn_weights, spatial_adjacency, spatial_constraints

**Weight Computation Layer:**
- Purpose: Compute adjacency/weight matrices from coordinates or features
- Location: `R/spatial_weights.R`, `R/knn_weights.R`, `R/label_sim.R`, `R/temporal_weights.R`
- Contains:
  - `spatial_adjacency()` - radius/k-NN based from coordinates
  - `weighted_knn()` - k-NN with various weight schemes
  - `label_matrix()`, `label_matrix2()` - label-based similarities
  - `temporal_adjacency()` - time-based adjacency
- Depends on: Rnanoflann, FNN, RcppHNSW, stats (dist, cor)
- Used by: Applications and analysis functions

**Graph Transformation Layer:**
- Purpose: Operations on existing graphs/matrices
- Location: `R/neighbor_graph.R`, `R/spatial_constraints.R`, `R/repulsion.R`
- Contains:
  - `laplacian()` - normalized/unnormalized Laplacian
  - `spatial_constraints()` - spatial block constraints
  - `spatial_smoother()` - GAM-based smoothing
  - `repulsion_graph()` - eigenspace-based repulsion
  - `normalize_adjacency()`, `threshold_adjacency()`
- Depends on: igraph, Matrix, mgcv
- Used by: Graph refinement and analysis workflows

**Kernel/Diffusion Layer:**
- Purpose: Diffusion kernels and kernel methods
- Location: `R/diffusion.R`, `R/design_similarity_kernel.R`
- Contains:
  - `compute_diffusion_kernel()` - Markov kernel via eigendecomposition
  - `compute_diffusion_map()` - diffusion coordinate embedding
  - `heat_kernel()`, `inverse_heat_kernel()`, `normalized_heat_kernel()`
  - `design_kernel()` - learned kernel design
- Depends on: RSpectra, Matrix, igraph
- Used by: Advanced similarity and embedding workflows

**Utility Layer:**
- Purpose: Common data transformations and helper operations
- Location: `R/knn_weights.R`, `R/label_sim.R`, `R/commute_time.R`
- Contains:
  - Distance-to-similarity conversions
  - Label matrix construction (diagonal, binary)
  - Adjacency normalization schemes
  - Spectral methods (commute time distance)
- Depends on: Matrix, stats
- Used by: Multiple weight and kernel functions

## Data Flow

**Standard Adjacency Matrix Creation Flow:**

1. **Input** → Data coordinates, features, or class labels
2. **NN Search** → Find k nearest neighbors (Rnanoflann, RcppHNSW, or FNN)
3. **Weight Computation** → Apply kernel (heat, correlation, etc.) to distances
4. **Sparse Assembly** → Build dgCMatrix from triplet format (i, j, x)
5. **Symmetrization** → Ensure adjacency is symmetric if needed
6. **Wrapping** → Create `neighbor_graph` object with igraph wrapper
7. **Output** → dgCMatrix, neighbor_graph, or derived metrics

**Spatial Constraint Flow (Image-like data):**

1. Partition spatial coordinates into blocks
2. Compute within-block neighbors (high k, heat weights)
3. Compute between-block neighbors (low k, binary weights)
4. Combine with shrinkage: `S = λ*within + (1-λ)*between`
5. Normalize by first eigenvalue for stable conditioning

**Graph Transformation Flow:**

1. Extract adjacency matrix from neighbor_graph via `adjacency()`
2. Apply transformation (Laplacian, normalize, threshold)
3. Wrap result back in neighbor_graph if needed
4. Return transformed graph

**State Management:**

- State is stored as sparse matrices (dgCMatrix)
- neighbor_graph wraps both igraph and parameters
- No mutable state; all functions are pure
- Intermediate results cached in returned objects via params list

## Key Abstractions

**neighbor_graph:**
- Purpose: Unified wrapper for graph objects
- Examples: `R/neighbor_graph.R`
- Pattern: S3 class wrapping igraph with metadata list
- Provides: Single interface for matrix/igraph/nnsearcher inputs via method dispatch

**nnsearcher:**
- Purpose: Abstraction for nearest neighbor index
- Examples: `R/searcher.R`
- Pattern: Encapsulates HNSW index + search methods
- Provides: Consistent API for kNN, range search, between-set search

**nn_search (result):**
- Purpose: Standardized NN search output format
- Examples: `R/searcher.R`
- Pattern: List with `indices` and `distances` matrices + metadata attributes
- Provides: Uniform format across different NN backends

**class_graph:**
- Purpose: Specialized graph for class-based relationships
- Examples: `R/class_graph.R`
- Pattern: neighbor_graph subclass with additional metadata (labels, class_indices)
- Provides: Methods for within/between-class neighbor queries

**Weight Functions:**
- Purpose: Encapsulate distance→similarity transformations
- Examples: `heat_kernel`, `inverse_heat_kernel`, `normalized_heat_kernel`
- Pattern: Simple scalar/vector functions with sigma bandwidth parameter
- Provides: Pluggable kernels for weight computation

## Entry Points

**User-Facing Functions:**

**Spatial Graph Construction:**
- Location: `R/spatial_weights.R`
- `spatial_adjacency(coords, nnk, sigma, ...)` - k-NN spatial graph
- Triggers: Called directly by users with coordinate data
- Responsibilities: Find neighbors in coordinate space, apply heat kernel, return sparse matrix

**KNN Graph Construction:**
- Location: `R/knn_weights.R`
- `weighted_knn(X, k, distance, weight_scheme, ...)` - k-NN on feature data
- Triggers: Called directly with feature matrix
- Responsibilities: Compute distances, select neighbors, apply weights

**Class Graph Construction:**
- Location: `R/class_graph.R`
- `class_graph(labels)` - adjacency from class labels
- Triggers: Called with factor/vector of class labels
- Responsibilities: Build binary adjacency between same-class nodes

**Nearest Neighbor Searcher:**
- Location: `R/searcher.R`
- `nnsearcher(X, ...)` - build indexed searcher
- Triggers: Called to create reusable index for multiple searches
- Responsibilities: Initialize HNSW index, store reference data

**Label Similarity:**
- Location: `R/label_sim.R`
- `label_matrix(labels)`, `label_matrix2(labels)` - label-based weights
- Triggers: Called for categorical/label-based adjacency
- Responsibilities: Create label match matrices

**Spatial Constraints (Image-like):**
- Location: `R/spatial_constraints.R`
- `spatial_constraints(coords, nblocks, ...)` - multi-block spatial graph
- Triggers: Called for image/spatial block data
- Responsibilities: Partition blocks, compute within/between adjacency

**Diffusion Kernels:**
- Location: `R/diffusion.R`
- `compute_diffusion_kernel(A, t, k)` - Markov kernel
- Triggers: Called on existing adjacency matrix
- Responsibilities: Eigendecomposition, compute diffusion kernel

## Error Handling

**Strategy:** Assertion-based validation with informative messages

**Patterns:**

- **Input Validation:** assertthat for preconditions (`assert_that(nrow(X) > 0)`)
- **Matrix Checks:** Matrix format validation (symmetric, sparse conversion)
- **Dimension Mismatches:** stopifnot with descriptive messages
- **Numerical Safety:** Epsilon guards for division by zero, sqrt on negative numbers
- **NA Handling:** Drop NA indices during sparse assembly, warn on isolated nodes

Example from `R/searcher.R`:
```r
stopifnot(
  "Number of labels must equal the number of rows" =
    length(labels) == nrow(X)
)
```

Example from `R/diffusion.R`:
```r
if (any(isolated)) {
  warning("Isolated nodes present; they will remain isolated")
}
```

## Cross-Cutting Concerns

**Logging:**
- Approach: Conditional message() calls, controlled via verbose parameter
- Usage in: `R/spatial_constraints.R`, `R/spatial_weights.R`
- Pattern: `if (verbose) message("step description")`

**Validation:**
- Approach: assertthat package + stopifnot for critical invariants
- Used for: Matrix dimensions, symmetry, parameter ranges
- Example: `assert_that(shrinkage_factor > 0 & shrinkage_factor <= 1)`

**Performance Optimization:**
- Approach: C++ implementations in src/, sparse matrix operations
- Used for: Weight computation (weight_funs.cpp), distance calculations
- Pattern: R wrapper calls Rcpp::sourceCpp for critical loops

**Parallelization:**
- Approach: furrr/parallel for map operations where applicable
- Used in: Label similarity (future_map for multiple labels)
- Pattern: Optional via future_map vs sequential lapply

**Matrix Representation:**
- Approach: Consistent use of dgCMatrix (sparse) format
- Rules: Always return sparse matrices for memory efficiency
- Symmetrization: Enforce A + t(A) when needed
- Normalization: Support both sparse and dense during computation, return sparse

---

*Architecture analysis: 2026-01-28*
