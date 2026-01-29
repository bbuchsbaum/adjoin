# Coding Conventions

**Analysis Date:** 2026-01-28

## Naming Patterns

**Files:**
- All R source files use lowercase with underscores: `spatial_weights.R`, `knn_weights.R`, `neighbor_graph.R`
- C++ wrapper files: `RcppExports.R` (auto-generated from Rcpp)
- Test files follow pattern: `test-{module-name}.R` (e.g., `test-spatial-weights.R`)

**Functions:**
- Public functions use snake_case: `spatial_adjacency()`, `weighted_knn()`, `compute_diffusion_kernel()`, `class_graph()`
- Generic S3 functions use snake_case: `laplacian()`, `adjacency()`, `neighbors()`, `nvertices()`, `non_neighbors()`
- S3 methods use dot notation: `neighbor_graph.igraph()`, `neighbor_graph.Matrix()`, `adjacency.neighbor_graph()`, `laplacian.neighbor_graph()`
- Internal helper functions (marked with `@keywords internal`) also use snake_case: `as_triplet()`, `triplet_to_matrix()`, `indices_to_sparse()`, `get_neighbor_fun()`
- Kernel/weight functions use snake_case: `heat_kernel()`, `inverse_heat_kernel()`, `normalized_heat_kernel()`

**Variables:**
- Local variables in functions use snake_case: `nn_result`, `weight_mode`, `feature_mat`, `coord_mat`, `spatial_coords`
- Matrix abbreviations are common: `A` (adjacency), `X` (feature matrix), `K` (kernel), `L` (Laplacian), `D` (degree matrix), `P` (transition matrix)
- Single/short names for loop counters: `i`, `j`, `k`, `n`
- Descriptive names for important variables: `indices`, `distances`, `weights`, `sigma`, `radius`, `threshold`

**Types/Classes:**
- S3 class names use snake_case: `neighbor_graph`, `class_graph`, `nnsearcher`, `nn_search`
- Class attributes stored in lists under descriptive names: `$G` (igraph object), `$params`, `$labels`, `$class_indices`, `$class_freq`, `$levels`

## Code Style

**Formatting:**
- Roxygen2 v7.3.3 is configured in DESCRIPTION: `RoxygenNote: 7.3.3`
- Two-space indentation is standard (observed in all R files)
- Opening braces typically on same line: `function(x) {`
- One statement per line is preferred

**Linting:**
- No explicit linting tool configuration found (no .eslintrc, biome.json, etc.)
- Code follows CRAN standards (evidenced by successful `R CMD check`)
- Input validation is consistent and thorough

## Import Organization

**Order:**
1. Documentation roxygen comments (`@useDynLib`, `@importFrom`, `@keywords`)
2. Package imports: `library()` or roxygen `@importFrom` declarations
3. Function definitions

**Path Aliases:**
- Not applicable (R package, not JavaScript/Node.js project)

**Common Import Patterns:**
```r
#' @useDynLib neighborweights, .registration=TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom Matrix sparseMatrix Diagonal
#' @importFrom Rnanoflann nn
#' @importFrom mgcv gam
#' @importFrom assertthat assert_that
#' @importFrom RcppHNSW hnsw_build hnsw_search
#' @importFrom RSpectra eigs
```

## Error Handling

**Patterns:**
- **Assertions using `assertthat` package**: Preferred for input validation in most functions
  - Example: `assertthat::assert_that(radius > 0)` in `spatial_autocor()` (line 34-35 of `spatial_weights.R`)
  - Example: `assert_that(inherits(cg, "class_graph"), msg = "...")` in `repulsion.R`
  - Allows custom error messages with `msg` parameter

- **Base R `stopifnot()` for simple conditions**: Used for direct validation
  - Example: `stopifnot(ncol(Kern) == nrow(Kern), ncol(X) == nrow(Kern))` in `label_sim.R` (line 174)
  - Example: `stopifnot("Error message" = condition)` format (named assertion, R 4.0+)

- **`stop()` for explicit errors with context**:
  - Example in `diffusion.R`: `stop("t must be a positive scalar")` (line 32)
  - Example: `stop("A must be square.", call. = FALSE)` (line 37)
  - Uses `call. = FALSE` to suppress function call from error message

- **`warning()` for non-fatal issues**:
  - Example in `diffusion.R`: `warning("Isolated nodes present; they will remain isolated in kernel.")` (line 49)
  - Used for edge cases that don't prevent computation

- **Error handling in C++ interfaces**: Validation happens before Rcpp calls
  - Data structure checks before calling compiled functions
  - Distance/dimension validation on matrices

**Validation Order:**
1. Check for missing required parameters using `!missing(param)` assertions
2. Validate numeric ranges: `radius > 0`, `alpha >= 0 && alpha <= 1`
3. Validate matrix dimensions: `nrow(X) == nrow(cds)`
4. Validate object classes: `inherits(x, "class_graph")`
5. Warn about special cases: isolated nodes, NA values

## Logging

**Framework:** `base::print()` or `base::cat()` (no dedicated logging library)

**Patterns:**
- Minimal logging in production functions (library optimizes for performance)
- Errors and warnings through standard R mechanisms (`stop()`, `warning()`)
- Information printed only in examples or interactive contexts
- C++ functions don't log; validation happens in R wrapper layer

## Comments

**When to Comment:**
- Complex algorithms documented with roxygen `@details` sections
- Mathematical concepts explained in function documentation
- Internal helper functions use `@keywords internal` to hide from public docs
- Code itself is generally self-documenting with clear names

**JSDoc/TSDoc:**
- Not applicable (R package, uses roxygen2 instead)
- Roxygen documentation format in `#'` comments above functions

**Roxygen Pattern:**
```r
#' Function Title
#'
#' Longer description of what function does
#'
#' @param X Parameter description
#' @param k Parameter description with defaults
#'
#' @return What the function returns
#'
#' @details Mathematical details or algorithm explanation
#'
#' @examples
#' # Example usage
#' X <- matrix(rnorm(20), nrow=5)
#' result <- function_name(X, k=3)
#'
#' @importFrom Package function_name
#' @export
function_name <- function(X, k = 3) {
  # Implementation
}
```

## Function Design

**Size:**
- Most functions 15-80 lines (observed range)
- Larger functions (150+ lines) break complex algorithms into logical blocks
- Example: `spatial_adjacency()` in `spatial_weights.R` is ~280 lines but handles complex spatial weight computation with internal organization
- Large functions typically in specialized modules: `knn_weights.R` (548 lines), `spatial_weights.R` (754 lines)

**Parameters:**
- Default parameters are common: `sigma=1`, `weight_mode="heat"`, `as="sparse"`
- Parameter validation happens at function entry with assertions
- Use `...` for method dispatch in S3 generic functions: `function(x, ...) UseMethod("function")`
- Optional parameters documented as `Default is [value]` in roxygen

**Return Values:**
- Sparse matrices preferred: Functions return `Matrix` objects with `sparse=TRUE`
- Example: `spatial_adjacency()` returns sparse `dgCMatrix`
- Consistent return types across overloads: All `adjacency()` methods return sparse matrices
- Single return via `return()` statement or implicit last expression
- Complex returns use named lists: `list(embedding=..., distances=...)`

## Module Design

**Exports:**
- Public functions marked with `@export` in roxygen
- S3 methods marked with `@method class_name method_name` and `@export`
- Internal functions marked with `@keywords internal` (not exported to NAMESPACE)
- Example from `neighbor_graph.R`: All `neighbor_graph.*` and `adjacency.*` methods are explicitly exported

**Barrel Files:**
- Not applicable (R package structure uses NAMESPACE, not barrel exports)
- All functions imported via `library(neighborweights)` namespace

**Module Organization:**
- One primary concept per file: `spatial_weights.R` for spatial operations, `knn_weights.R` for k-nearest neighbor methods
- Generic functions in `all_generic.R` (299 lines) provide public S3 interface
- Supporting internal functions kept in same file as public API
- Rcpp-generated bindings in `RcppExports.R` (auto-generated, not manually edited)

**Class Patterns:**
- S3 classes created via `structure(list(...), class=c(...))`
- Example from `class_graph()` (line 51 of `class_graph.R`):
```r
ret <- neighbor_graph(
  out,
  params = list(weight_mode = "binary", neighbor_mode = "supervised"),
  labels = labels,
  class_indices = split(seq_len(n), labels),
  class_freq = table(labels),
  levels = lvls,
  classes = "class_graph"
)
```
- Multiple class inheritance: `class=c("class_graph", "neighbor_graph")`
- Attributes stored as list components: `x$G`, `x$params`, `x$labels`

---

*Convention analysis: 2026-01-28*
