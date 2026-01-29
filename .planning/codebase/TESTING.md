# Testing Patterns

**Analysis Date:** 2026-01-28

## Test Framework

**Runner:**
- testthat v3.0.0+ (specified in DESCRIPTION `Suggests: testthat (>= 3.0.0)`)
- Location: `tests/testthat/` directory
- Config: Tests run via `R -e "devtools::test()"` or within RStudio

**Assertion Library:**
- testthat's built-in assertions: `expect_*()` functions
- 654 total assertion calls across 246 test cases

**Run Commands:**
```bash
# Run all tests
R -e "devtools::test()"

# Run specific test file
R -e "testthat::test_file('tests/testthat/test-spatial-weights.R')"

# Watch mode (requires devtools)
R -e "devtools::test(reporter='progress')"

# Coverage (requires covr)
R -e "covr::package_coverage(type='all')"
```

## Test File Organization

**Location:**
- Tests co-located in `tests/testthat/` directory (separate from source, not alongside `R/` files)
- Total: 21 test files, 246 test cases organized by module

**Naming:**
- Pattern: `test-{module-name}.R`
- Examples: `test-spatial-weights.R`, `test-knn-weights.R`, `test-neighbor-graph.R`, `test-diffusion.R`
- Files correspond to major functional areas: spatial, knn, diffusion, label similarity, class graphs, constraints

**Structure:**
```
tests/
└── testthat/
    ├── test-neighbor-graph.R
    ├── test-spatial-weights.R
    ├── test-knn-weights.R
    ├── test-class-graph.R
    ├── test-diffusion.R
    ├── test-label-similarity.R
    ├── test-repulsion-spatial.R
    └── ... (21 files total)
```

## Test Structure

**Suite Organization:**
```r
library(testthat)
library(Matrix)

context("Neighbor graph construction and operations")

test_that("neighbor_graph.Matrix creates valid neighbor_graph object", {
  # Arrange
  adj <- sparseMatrix(i = c(1, 2, 3), j = c(2, 3, 1),
                      x = c(1, 1, 1), dims = c(3, 3))
  adj <- adj + t(adj)  # Make symmetric

  # Act
  ng <- neighbor_graph(adj)

  # Assert
  expect_true(inherits(ng, "neighbor_graph"))
  expect_true("G" %in% names(ng))
  expect_true(inherits(ng$G, "igraph"))
})
```

**Patterns:**
- **Setup**: Create test data, fixtures, or helper matrices
  - Simple sparse matrices: `sparseMatrix(i=..., j=..., x=..., dims=...)`
  - Random data: `matrix(rnorm(n), nrow=..., ncol=...)`
  - Path graphs for diffusion tests: Helper function `make_path_graph(n)`

- **Teardown**:
  - Implicit through test scoping (no explicit cleanup needed in R)
  - No fixtures or mocks requiring cleanup
  - Garbage collection happens automatically

- **Assertion pattern**: Multiple `expect_*()` calls per test
  - Structure validation: `expect_true(inherits(x, "class_name"))`
  - Dimension checks: `expect_equal(dim(x), c(3, 3))`
  - Value validation: `expect_true(all(x >= 0))`
  - Symmetry checks: `expect_true(Matrix::isSymmetric(x))`
  - Mathematical properties: `expect_true(all(abs(rowSums(L)) < 1e-12))`

## Mocking

**Framework:** Not used
- testthat has mockery/mock capabilities, but not employed in this codebase
- All tests use real data structures and functions
- No external API mocking

**Patterns:**
- Direct function composition testing: Test functions receive matrices, compute results
- Example from `test-spatial-weights.R`: Pass actual sparse matrices to `spatial_adjacency()`, verify output properties
- No dependency injection or mock objects used

**What to Mock:**
- Not applicable - tests use real data and real function calls
- Rcpp C++ functions called directly through R wrappers
- igraph operations called directly (not mocked)

**What NOT to Mock:**
- Matrix operations (test actual sparse/dense behavior)
- Linear algebra computations (eigendecomposition, diffusion kernels)
- Graph structure operations (neighbor finding, adjacency extraction)
- Kernel computations (heat kernel, correlation kernel)

## Fixtures and Factories

**Test Data:**
- Simple synthetic data created in-test:
```r
# Minimal matrices
coords <- matrix(c(0, 0, 1, 0, 0, 1, 1, 1), ncol = 2, byrow = TRUE)

# Random data for robustness
X <- matrix(rnorm(20), nrow=5)

# Sparse adjacency matrices
adj <- sparseMatrix(i = c(1, 2, 3), j = c(2, 3, 1),
                    x = c(1, 1, 1), dims = c(3, 3))
adj <- adj + t(adj)  # Symmetrize
```

- **Helper functions** for repeated patterns:
  ```r
  # From test-diffusion.R (lines 7-25)
  make_path_graph <- function(n) {
    i <- seq_len(n - 1)
    A <- sparseMatrix(i = c(i, i + 1), j = c(i + 1, i),
                      x = rep(1, 2 * (n - 1)), dims = c(n, n))
    A
  }

  make_path_with_isolate <- function(n_path, n_total) {
    stopifnot(n_total > n_path)
    i_idx <- seq_len(n_path - 1)
    sparseMatrix(
      i = c(i_idx, i_idx + 1),
      j = c(i_idx + 1, i_idx),
      x = rep(1, 2 * (n_path - 1)),
      dims = c(n_total, n_total)
    )
  }
  ```

**Location:**
- Helpers defined at top of test files
- Each test file contains only the fixtures it needs
- No separate fixtures directory

## Coverage

**Requirements:** Not enforced by build system
- No coverage thresholds in CI configuration
- Coverage measurement not automated

**View Coverage:**
```bash
# Install covr if needed
R -e "install.packages('covr')"

# Generate coverage report
R -e "covr::report(covr::package_coverage())"

# HTML report
R -e "covr::report(covr::package_coverage(), file='coverage.html')"
```

## Test Types

**Unit Tests:**
- Scope: Individual functions or methods
- Approach: Test function in isolation with known inputs
- Examples from `test-neighbor-graph.R`:
  - `test_that("neighbor_graph.Matrix creates valid neighbor_graph object", {...})`
  - `test_that("adjacency.neighbor_graph extracts adjacency matrix", {...})`
  - `test_that("laplacian.neighbor_graph computes Laplacian matrix", {...})`
- Verify:
  - Return type and structure
  - Mathematical properties (symmetry, zero row sums)
  - Correct extraction of components
  - Edge case handling (single nodes, empty graphs)

**Integration Tests:**
- Scope: Multiple functions working together
- Approach: Create graph via one method, verify with another
- Examples from `test-spatial-weights.R`:
  - `weighted_spatial_adjacency()` combines spatial and feature similarity
  - Test verifies both components integrate correctly
  - Checks symmetry and non-negativity of combined result
- Examples from `test-knn-weights.R`:
  - `nnsearcher` object creation, nearest neighbor search, weight conversion
  - Test chain: Create searcher → find neighbors → verify structure
  - Multiple kernel functions tested together

**E2E Tests:**
- Not explicitly labeled as E2E
- Closest: Extended test files like `test-neighbor-graph-extended.R`, `test-class-graph-extended.R`
- These test complex scenarios with realistic data sizes and parameter combinations
- Example: Full workflow of label similarity computation across multiple steps

## Common Patterns

**Async Testing:**
- Not applicable (R is primarily single-threaded, no async/await)
- Parallel computation handled via `furrr` package where used
- Tests don't explicitly test parallel behavior

**Error Testing:**
```r
# From test-diffusion.R (lines 74-79)
test_that("compute_diffusion_kernel validates inputs", {
  A <- make_path_graph(5)
  expect_error(compute_diffusion_kernel(A, t = -1), "positive scalar")
  expect_error(compute_diffusion_kernel(A, t = c(1, 2)), "positive scalar")
  expect_error(compute_diffusion_kernel(A, t = 0), "positive scalar")
})
```
- Pattern: `expect_error(function_call, pattern_to_match)`
- Verifies both that error is raised AND message contains expected text
- Tests for invalid parameter values
- Tests for dimension mismatches
- Tests for type violations (e.g., non-matrix input)

**Matrix Property Testing:**
```r
# From test-spatial-weights.R (lines 14-21)
test_that("spatial_adjacency produces valid adjacency matrix", {
  coords <- matrix(c(0, 0, 1, 0, 0, 1, 1, 1), ncol = 2, byrow = TRUE)
  adj <- spatial_adjacency(coords, sigma = 1, nnk = 3, weight_mode = "heat")

  expect_true(inherits(adj, "Matrix"))          # Type check
  expect_equal(nrow(adj), 4)                     # Dimension check
  expect_equal(ncol(adj), 4)                     # Dimension check
  expect_true(Matrix::isSymmetric(adj))          # Symmetry property
  expect_true(all(adj@x >= 0))                   # Non-negative weights
})
```
- Pattern: Verify mathematical properties, not just structure
- Symmetry validation: `Matrix::isSymmetric(x)`
- Non-negativity: `all(x >= 0)` or `all(x@x >= 0)` for sparse matrices
- Zero row sum property for Laplacians: `all(abs(rowSums(L)) < 1e-12)`

**Numerical Tolerance:**
```r
# From test-neighbor-graph.R (line 89)
expect_true(all(abs(rowSums(L)) < 1e-12))

# From test-diffusion.R (line 39)
expect_true(all(abs(K_dense - t(K_dense)) < 1e-10))
```
- Pattern: Use small tolerance for floating-point comparisons
- Typical tolerance: 1e-10 to 1e-12
- Always use `abs()` for symmetric/antisymmetric checks

**Kernel Function Testing:**
```r
# From test-knn-weights.R (lines 82-97)
test_that("heat_kernel and inverse_heat_kernel produce valid weights", {
  distances <- c(0, 1, 2, 3)

  weights_heat <- heat_kernel(distances, sigma = 1)
  weights_inv <- inverse_heat_kernel(distances, sigma = 1)

  expect_equal(length(weights_heat), 4)
  expect_equal(length(weights_inv), 4)
  expect_true(all(weights_heat >= 0))
  expect_true(all(weights_inv >= 0))

  # Heat kernel should decrease with distance
  expect_true(weights_heat[1] >= weights_heat[2])
  expect_true(weights_heat[2] >= weights_heat[3])
})
```
- Pattern: Test mathematical properties (monotonicity, bounds)
- Verify kernel behavior matches theory
- Test with edge cases (distance 0, large distances)

---

*Testing analysis: 2026-01-28*
