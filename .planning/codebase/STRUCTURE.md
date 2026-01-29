# Codebase Structure

**Analysis Date:** 2026-01-28

## Directory Layout

```
graphweights/                          # Package root (name is directory; package name is 'neighborweights')
├── R/                                 # Core R implementation files (18 files, 4587 LOC)
│   ├── all_generic.R                 # S3 generic function definitions (299 LOC)
│   ├── neighbor_graph.R              # Graph object construction & methods (274 LOC)
│   ├── spatial_weights.R             # Spatial adjacency matrices (754 LOC) [LARGEST]
│   ├── knn_weights.R                 # K-NN based adjacency (548 LOC)
│   ├── class_graph.R                 # Class label graphs (450 LOC)
│   ├── design_similarity_kernel.R    # Learned kernel design (423 LOC)
│   ├── label_sim.R                   # Label-based similarity (351 LOC)
│   ├── searcher.R                    # Nearest neighbor search interface (350 LOC)
│   ├── spatial_constraints.R         # Block spatial constraints (319 LOC)
│   ├── repulsion.R                   # Eigenspace repulsion (202 LOC)
│   ├── diffusion.R                   # Diffusion kernels (186 LOC)
│   ├── commute_time.R                # Commute time distance (141 LOC)
│   ├── temporal_weights.R            # Temporal adjacency (128 LOC)
│   ├── local_global_knn.R            # Local+global KNN fusion (125 LOC)
│   ├── neighborweights.R             # Package namespace marker (3 LOC)
│   ├── RcppExports.R                 # Auto-generated Rcpp wrappers (1217 LOC)
│   └── 3 more support files          # DS_Store, etc.
├── src/                               # C++ implementations (Rcpp/RcppArmadillo)
│   ├── weight_funs.cpp               # Performance-critical weight computations (12K LOC)
│   ├── RcppExports.cpp               # Auto-generated Rcpp interface (6798 LOC)
│   ├── Makevars                      # Compiler flags (32 bytes: -DARMA_64BIT_WORD)
│   └── Compiled objects              # .so, .o files (built on compile)
├── man/                               # Roxygen2-generated documentation (92 .Rd files)
├── tests/testthat/                    # Unit test suite (20 test files)
│   ├── test-neighbor-graph.R         # Graph object tests
│   ├── test-spatial-weights.R        # Spatial adjacency tests (NEW)
│   ├── test-knn-weights.R            # K-NN tests
│   ├── test-class-graph.R            # Class graph tests
│   ├── test-design-kernel.R          # Design kernel tests (9K LOC)
│   ├── test-diffusion.R              # Diffusion kernel tests
│   ├── test-label-similarity.R       # Label tests
│   ├── test-searcher.R               # NN searcher tests
│   ├── test-repulsion.R              # Repulsion tests
│   ├── test-commute-time.R           # Commute time tests
│   └── *-extended.R variants         # Comprehensive variant tests
├── data-raw/                          # Raw data and build scripts (19 subdirs)
├── DESCRIPTION                        # Package metadata (R dependencies)
├── NAMESPACE                          # Auto-generated export/import list (roxygen2)
├── README.md                          # Package overview
├── LICENSE                            # MIT license
├── neighborweights.Rproj              # RStudio project file
└── .planning/
    └── codebase/                      # GSD documentation (this file)
```

## Directory Purposes

**R/ - Implementation Core:**
- Purpose: All R source code for package functionality
- Contains: Generic definitions, S3 method implementations, utility functions
- Key patterns: roxygen2 comments with @export/@rdname/@param for docs
- No internal helper files separate; helpers live in same file as public functions

**src/ - Performance Layer:**
- Purpose: C++ code for computationally intensive operations
- Contains: Rcpp-wrapped C++ functions using RcppArmadillo
- Auto-generated: RcppExports.R/cpp from Rcpp::compileAttributes()
- Compilation: Uses Makevars with -DARMA_64BIT_WORD flag

**man/ - Documentation (Generated):**
- Purpose: Roxygen2-generated documentation files (.Rd format)
- Contains: One .Rd file per exported function/generic
- Do not edit directly: Regenerate via devtools::document()
- Linked from: roxygen2 comments in R/ source files

**tests/testthat/ - Test Suite:**
- Purpose: Unit tests using testthat framework
- Contains: 20 test files covering all major functions
- Run: `devtools::test()` or `R CMD check`
- Extended tests: test-*-extended.R have comprehensive coverage

**data-raw/ - Data Build:**
- Purpose: Scripts and raw data for package data objects
- Contains: 19+ subdirectories with various data processing pipelines
- Not included in package: Generated data typically goes to data/
- Usage: Usually not needed for package users

**.planning/codebase/ - GSD Metadata:**
- Purpose: Codebase analysis documents for Claude Code
- Contains: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, etc.
- Not part of package: For development guidance only

## Key File Locations

**Entry Points:**

- `R/spatial_weights.R`: Main entry point for spatial adjacency construction (754 lines)
- `R/knn_weights.R`: Main entry point for feature-based k-NN (548 lines)
- `R/class_graph.R`: Main entry point for class label graphs (450 lines)
- `R/searcher.R`: Main entry point for indexed nearest neighbor search (350 lines)

**Configuration:**

- `DESCRIPTION`: Package dependencies, R version requirement, metadata
- `NAMESPACE`: Roxygen2-generated export/import directives
- `src/Makevars`: Compiler flags for C++ (single line: `PKG_CXXFLAGS += -DARMA_64BIT_WORD`)
- `.Rproj`: RStudio project settings

**Core Logic:**

- `R/all_generic.R`: S3 generic function declarations (299 lines, 25+ generics)
- `R/neighbor_graph.R`: Graph object construction and basic methods (274 lines)
- `R/spatial_weights.R`: Spatial adjacency implementations (754 lines)
- `R/knn_weights.R`: K-NN weight computation (548 lines)
- `src/weight_funs.cpp`: C++ performance-critical kernels (12.5K lines)

**Advanced Features:**

- `R/diffusion.R`: Markov diffusion kernels (186 lines)
- `R/design_similarity_kernel.R`: Learned kernel design (423 lines)
- `R/spatial_constraints.R`: Multi-block spatial constraints (319 lines)
- `R/repulsion.R`: Eigenspace repulsion (202 lines)

**Testing:**

- `tests/testthat/test-neighbor-graph.R`: Core graph tests
- `tests/testthat/test-knn-weights.R`: K-NN tests
- `tests/testthat/test-design-kernel.R`: Design kernel comprehensive tests (9505 LOC)
- `tests/testthat/test-*.R`: One file per major feature

## Naming Conventions

**Files:**

- **R source files:** `lowercase_with_underscores.R` (e.g., `spatial_weights.R`)
- **Test files:** `test-feature-name.R` with optional `-extended.R` variant (e.g., `test-knn-weights.R`)
- **C++ source:** `lowercase_with_underscores.cpp` (e.g., `weight_funs.cpp`)

**Functions:**

- **User-facing:** `snake_case` verbs (e.g., `spatial_adjacency()`, `weighted_knn()`, `class_graph()`)
- **Generic functions:** `snake_case` (e.g., `adjacency()`, `laplacian()`, `neighbors()`)
- **S3 methods:** `generic.class` format (e.g., `adjacency.neighbor_graph()`, `laplacian.neighbor_graph()`)
- **Internal helpers:** `lowercase_with_underscores()` with @keywords internal tag (e.g., `as_triplet()`, `indices_to_sparse()`)

**Variables:**

- **Parameters:** `snake_case` (e.g., `nnk`, `sigma`, `weight_mode`, `shrinkage_factor`)
- **Data:** `X`, `coords`, `cds`, `labels` (conventions from statistics/ML)
- **Matrices:** Capitalized (A, S, W, L for adjacency, similarity, weights, Laplacian)
- **Vectors:** Lowercase (d for degree, x for distance)

**Classes:**

- **S3 classes:** `lowercase_with_underscores` (e.g., `neighbor_graph`, `class_graph`, `nnsearcher`, `nn_search`)

## Where to Add New Code

**New Feature (Graph Construction):**
- Primary code: Create new file `R/feature_name_weights.R` in `R/` directory
- Convention: Export main function via @export roxygen tag
- Register in `NAMESPACE`: roxygen2 auto-generates this via @export
- Pattern: Follow structure of `R/spatial_weights.R` or `R/knn_weights.R`

Example structure:
```r
# In R/my_feature_weights.R
#' My New Adjacency Matrix Constructor
#'
#' Description here.
#'
#' @param X data matrix
#' @param ... parameters
#'
#' @return sparse dgCMatrix adjacency
#' @export
my_feature_adjacency <- function(X, param1=default, ...) {
  # Implementation
  # Return dgCMatrix
}
```

**New Component/Module:**
- **If it needs a new class:** Create `R/myclass.R` with class definition and methods
- **If it adds methods to existing class:** Add to existing file (e.g., add `adjacency.myclass` to `R/neighbor_graph.R`)
- **If performance-critical:** Consider C++ in `src/myfunction.cpp` with Rcpp::export

**New S3 Method:**
- Add to appropriate R file: `generic.newclass <- function(x, ...) { ... }`
- Tag with @method roxygen directive
- If new generic needed: Add stub to `R/all_generic.R` with @export

**Utilities/Helpers:**
- Location: Add to relevant functional file (e.g., utility for spatial goes in `R/spatial_weights.R`)
- Tag with @keywords internal
- Do not create separate utility file unless 50+ lines and unrelated to any single feature

**Tests:**
- New feature: Create `tests/testthat/test-feature-name.R`
- Extended tests: Create `tests/testthat/test-feature-name-extended.R` for comprehensive coverage
- Convention: Use context() for test groups, test_that() for individual tests
- Pattern: Test preconditions, outputs, edge cases

**Documentation:**
- Auto-generated: Run `devtools::document()` to generate from roxygen2 comments
- Do not edit `.Rd` files directly
- Update roxygen comments in R/ source files

## Special Directories

**man/ - Documentation (Generated):**
- Purpose: Roxygen2-generated .Rd documentation files
- Generated: `devtools::document()` from roxygen2 comments
- Committed: Yes (standard practice for CRAN packages)
- Do not edit: Changes made here will be overwritten

**data-raw/ - Data Preprocessing:**
- Purpose: Scripts and raw data for creating package data
- Generated: Not included in installed package
- Committed: Varies; usually yes for reproducibility
- Usage: Run scripts manually when data sources change

**.git/ - Version Control:**
- Purpose: Git repository metadata
- Generated: Yes, by git
- Committed: No (git ignores .git/)

**docs/ - Website (Generated):**
- Purpose: pkgdown-generated website
- Generated: `pkgdown::build_site()` from man/ + vignettes
- Committed: Sometimes (check .gitignore)
- Usage: For online documentation at GitHub Pages

**.Rproj.user/ - RStudio Settings:**
- Purpose: RStudio project-specific settings
- Generated: Yes, by RStudio
- Committed: No (in .gitignore)

## Directory Hierarchy for New Exports

When adding a new major feature (e.g., new adjacency method):

1. Create `R/feature_name.R` with:
   - Main function with @export tag
   - S3 methods if needed
   - Internal helpers with @keywords internal
   - All roxygen2 documentation comments

2. Create `tests/testthat/test-feature-name.R` with:
   - Basic functionality tests
   - Edge case tests
   - Dimension/symmetry validation

3. Add @importFrom directives if using new packages

4. Run `devtools::document()` to update NAMESPACE and man/ files

5. Do not modify NAMESPACE directly; roxygen2 controls it

---

*Structure analysis: 2026-01-28*
