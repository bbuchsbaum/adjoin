# Codebase Concerns

**Analysis Date:** 2026-01-28

## Tech Debt

**Package Name Mismatch (Directory vs Package):**
- Issue: Package is named "neighborweights" but repository directory is "graphweights", creating potential confusion
- Files: `DESCRIPTION`, `R/neighborweights.R`
- Impact: Users may struggle to find the correct package, documentation references may be ambiguous
- Fix approach: Either rename directory to match package name, or add prominent documentation clarifying the naming convention

**Incomplete Migration from rflann:**
- Issue: Recent migration from deprecated `rflann` to `Rnanoflann` (commit 3252742) may not have been fully tested across all edge cases
- Files: `R/spatial_weights.R`, `R/knn_weights.R`, `R/searcher.R`, `R/spatial_constraints.R`
- Impact: Subtle behavioral differences between NN search libraries could cause unexpected results in spatial operations
- Fix approach: Expand test coverage for spatial adjacency functions; verify numerical stability of Rnanoflann output

**Unused/Commented-Out Code:**
- Issue: `R/commute_time.R` contains substantial commented-out implementations (lines 58-122) that create maintenance burden
- Files: `R/commute_time.R`
- Impact: Difficult to determine if old implementations are intentionally preserved or should be removed; increases code bloat
- Fix approach: Document rationale for keeping old code or remove it; use git history instead of comments for version tracking

**Design Kernel Complexity:**
- Issue: `R/design_similarity_kernel.R` (423 lines) is highly complex with multiple parameter combinations and contrast matrix handling
- Files: `R/design_similarity_kernel.R`
- Impact: Difficult to maintain, high likelihood of bugs in edge cases with different factor type combinations
- Fix approach: Refactor into smaller, independently testable helper functions; add more specific unit tests for each factor type

## Known Bugs

**Commute-Time Distance with Near-Singular Matrices:**
- Symptoms: `commute_time_distance()` fails or produces NaN values when eigenvalue decomposition encounters numerical issues
- Files: `R/commute_time.R` (lines 42-50)
- Trigger: Graphs with isolated nodes or nearly-disconnected components; very large graphs where eigenvalues approach singular values
- Current handling: Checks for eigenvalues > 1 but doesn't validate input matrix properties; uses `sqrt(1 - ev)` which fails if ev > 1 due to numerical error
- Workaround: Pre-filter graph to ensure connectivity; use only well-conditioned adjacency matrices

**Division by Zero in Repulsion Graph Weighting:**
- Symptoms: `repulse_weight()` returns 0 for edge cases but doesn't document why
- Files: `R/repulsion.R` (lines 2-9)
- Trigger: Zero vectors or vectors where `sqrt(sum(x1^2)) + sqrt(sum(x2^2)) == 0`
- Current handling: Checks `if (!is.finite(denom) || denom == 0) return(0)` but this silent behavior may mask data quality issues
- Workaround: Validate input vectors before calling repulsion functions; monitor for 0 weights in output

**Label Similarity with Unequal Length Vectors:**
- Symptoms: `diagonal_label_matrix()` and similar functions assume `length(a) == length(b)` but error messages are generic
- Files: `R/label_sim.R` (lines 120, 225)
- Trigger: Passing vectors of different lengths when expecting same length
- Current handling: Stops with generic error but doesn't explain context
- Workaround: Ensure input vectors have matching lengths before calling; use wrapper functions that validate dimensions

## Security Considerations

**Insufficient Input Validation for Matrix Dimensions:**
- Risk: Matrix dimension mismatches can cause silent errors or undefined behavior in C++ code
- Files: `src/weight_funs.cpp` (bounds checking at lines 88, 92), `R/repulsion.R` (line 108), `R/diffusion.R` (lines 37, 137)
- Current mitigation: Some bounds checking exists in C++ but not comprehensive; R functions check dimensions inconsistently
- Recommendations: Implement universal dimension validation utility; validate all matrix inputs at entry points before passing to C++

**Unvalidated External Adjacency Matrices:**
- Risk: User-supplied adjacency matrices may not be symmetric or non-negative, violating algorithm assumptions
- Files: `R/diffusion.R`, `R/neighbor_graph.R`, `R/commute_time.R`
- Current mitigation: Documentation states assumptions but doesn't validate; `compute_diffusion_kernel()` checks if square but not for non-negativity
- Recommendations: Add validation functions for adjacency matrix properties (symmetry, non-negativity, connected components); call at function entry

**C++ Memory Safety in Sparse Triplet Operations:**
- Risk: Array indexing in `src/weight_funs.cpp` uses 0-based C++ with 1-based R conversion; off-by-one errors possible
- Files: `src/weight_funs.cpp` (lines 87, 91, 95)
- Current mitigation: Bounds checking present for out-of-range indices
- Recommendations: Add comprehensive unit tests for boundary cases in C++ functions; consider using safer indexing patterns

## Performance Bottlenecks

**O(n²) Memory in Binary Label Matrix for "Different" Labels:**
- Problem: `binary_label_matrix()` with `type="d"` creates dense matrix of dimension (n x n) when computing complement
- Files: `R/label_sim.R` (lines 69-79)
- Cause: Computing `1 - same_labels` creates dense matrix where most entries are 1
- Symptom: Out-of-memory errors for large datasets (n > 10,000)
- Improvement path: Use sparse representation with explicit enumeration of zero entries; compute on-the-fly in downstream operations rather than materializing

**Repeated Matrix Transposition in Spatial Operations:**
- Problem: `spatial_smoother()` and related functions call `t(adj)` and matrix products repeatedly (line 299)
- Files: `R/spatial_weights.R` (line 299), `R/spatial_constraints.R`
- Cause: Inefficient handling of sparse matrix transposes; can dominate runtime for large graphs
- Symptom: Slow performance on graphs with >50,000 nodes
- Improvement path: Cache transposes; use transpose-avoiding formulations for matrix products (e.g., `crossprod` instead of `t(A) %*% B`)

**Full Eigendecomposition for Diffusion Kernel with Large k:**
- Problem: When `k == nrow(A)`, `compute_diffusion_kernel()` performs full eigendecomposition instead of truncated
- Files: `R/diffusion.R` (lines 65-74)
- Cause: Fallback to `eigen()` for full decomposition is slow for large matrices
- Symptom: Exponential slowdown for graphs with >5,000 nodes if k is not specified
- Improvement path: Always use iterative eigensolver (RSpectra); increase `k` adaptively based on convergence

**Inefficient Nested Lapply in Spatial Autocorrelation:**
- Problem: `spatial_autocor()` uses nested `lapply()` with per-sample processing instead of vectorized operations
- Files: `R/spatial_weights.R` (lines 44-58, 67-78)
- Cause: Double loop over samples and neighbors; redundant GAM fitting on small data subsets
- Symptom: O(n²) complexity; very slow for n > 5,000
- Improvement path: Vectorize neighbor processing; fit GAM once on all samples; batch process predictions

## Fragile Areas

**Isolated Node Handling Inconsistency:**
- Files: `R/spatial_weights.R` (lines 274-299), `R/diffusion.R` (lines 47-62), `R/neighbor_graph.R` (lines 114-131)
- Why fragile: Three different strategies for handling isolated nodes (self_loop, keep_zero, drop); inconsistently applied across functions
- Behavior: `spatial_smoother()` adds self-loops by default; `compute_diffusion_kernel()` uses 0 without user control; `laplacian()` uses ifelse guards
- Safe modification: Document isolated node strategy explicitly per function; add parameter to control behavior consistently
- Test coverage: Limited isolated node tests; only basic single-node scenarios covered; missing tests for large isolated components

**Numerical Stability in Kernel Computations:**
- Files: `R/diffusion.R` (lines 76-88), `R/commute_time.R` (line 49), `R/design_similarity_kernel.R` (lines 314-315)
- Why fragile: Multiple sqrt(), division, and matrix operations on potentially ill-conditioned matrices
- Behavior: `pmax(Lt, 0)` in diffusion kernel assumes negative eigenvalues are numerical errors; `sqrt(1 - ev)` in commute time assumes |ev| <= 1
- Safe modification: Add condition number checks; implement stable variants for nearly-singular cases; use `Matrix::nearPD()` for near-PSD matrices
- Test coverage: No tests for ill-conditioned input matrices; edge cases with nearly-singular adjacency matrices untested

**Sparse Matrix Operations Without Drop0:**
- Files: `R/repulsion.R` (lines 114-115 has `drop0()` but others don't), `R/label_sim.R` (line 79), various spatial functions
- Why fragile: Element-wise operations (`*`, `+`, `-`) create structural zeros that accumulate and bloat sparse representation
- Behavior: Memory usage grows unexpectedly after repeated operations; performance degrades
- Safe modification: Call `drop0()` consistently after binary/arithmetic operations; consider using `drop0()` as a utility wrapper
- Test coverage: No tests for sparse matrix memory usage; missing tests for repeated operations on sparse matrices

**Design Kernel Contrast Matrix Validation:**
- Files: `R/design_similarity_kernel.R` (lines 228-231)
- Why fragile: Contrast matrices must have exact dimensions and orthonormality; minimal validation
- Behavior: Wrong contrast dimensions cause cryptic errors in Kronecker products; non-orthonormal contrasts produce invalid kernels
- Safe modification: Add explicit contrast matrix validation; provide utility to validate contrast properties; document requirements in detail
- Test coverage: Basic contrast tests exist but missing edge cases (singular contrasts, wrong dimensions, zero columns)

## Scaling Limits

**KNN Search Scalability:**
- Current capacity: Tested up to ~50,000 nodes with reasonable performance
- Limit: RcppHNSW with default `M=16`, `ef=200` becomes memory-intensive at >100,000 nodes
- Scaling path: Implement parameter auto-tuning based on n; support approximate NN for very large graphs; partition into subgraphs

**Laplacian Matrix Computation:**
- Current capacity: Sparse Laplacian construction fast for ~100,000 nodes
- Limit: Normalized Laplacian with eigenvalue normalization fails for >1,000,000 node graphs due to RSpectra memory usage
- Scaling path: Implement incremental/streaming normalization; support out-of-core sparse matrices; use iterative solvers for spectral operations

**Spatial Constraints with Multiple Blocks:**
- Current capacity: Reasonable for 10-20 spatial blocks with <10,000 points each
- Limit: Block diagonal construction with `Matrix::bdiag()` becomes slow for >100 blocks; memory-intensive
- Scaling path: Use sparse block representations; implement block-wise normalization; support distributed matrix assembly

## Dependencies at Risk

**RcppHNSW Fork Dependency:**
- Risk: Package depends on `RcppHNSW (>= 0.3.0.9001)`, a development version that may not be on CRAN
- Impact: Package installation fails if development version is not available; version pinning is brittle
- Migration plan: Move to stable RcppHNSW release; if dev version needed, maintain backup implementation or vendor code
- Fallback: `nabor` and `FNN` packages are available as alternatives for kNN search

**Recent Migration from rflann to Rnanoflann:**
- Risk: `Rnanoflann` is a relatively new package; less battle-tested than `rflann`
- Impact: Behavioral differences (e.g., handling of edge cases, distance metric implementations) could cause subtle bugs
- Status: Migration completed (commit 3252742) but limited testing of behavioral equivalence
- Recommendations: Maintain comparison tests against rflann; verify on large diverse datasets; document any behavioral differences

**RSpectra Dependency for Eigendecomposition:**
- Risk: RSpectra uses ARPACK which can fail on ill-conditioned matrices
- Impact: Functions like `compute_diffusion_kernel()` and `commute_time_distance()` can crash on near-singular inputs
- Current mitigation: Some checks for isolated nodes but not for condition number
- Recommendations: Add robustness to eigensolve failures; implement fallback dense eigendecomposition; document numerical stability requirements

## Missing Critical Features

**No Adjacency Matrix Validation Utility:**
- Problem: Users can pass invalid adjacency matrices (asymmetric, negative values, disconnected) without warning
- Blocks: Reliable spectral method implementations; reproducible results across platforms
- Solution: Implement `validate_adjacency()` function that checks: symmetry, non-negativity, connectivity, condition number

**No Reproducibility/Randomness Control:**
- Problem: Stochastic operations (e.g., doubly stochastic normalization, sampling in spatial_autocor) use uncontrolled randomness
- Blocks: Reproducible research; deterministic testing modes
- Solution: Add `seed` parameter to functions using randomness; document RNG state requirements

**Incomplete Support for Weighted Graphs:**
- Problem: Some functions assume binary adjacency; others handle weights inconsistently (see `repulsion_graph()` with `norm_fac` parameter)
- Blocks: Applications requiring edge-weighted networks
- Solution: Audit all functions for weight handling; document which operations preserve/destroy weights

**No Parallel Processing Support:**
- Problem: All spatial and KNN operations are single-threaded despite being embarrassingly parallel
- Blocks: Scaling to large datasets (>100K nodes)
- Solution: Add `parallel=TRUE` parameter; support future/furrr backends for distributed computation

## Test Coverage Gaps

**Isolated Node Handling:**
- What's not tested: Behavior with fully isolated nodes; multiple connected components; near-isolated dense subgraphs
- Files: `R/spatial_weights.R`, `R/diffusion.R`, `R/neighbor_graph.R`
- Risk: Silent failures or incorrect results when handling sparse components; no validation of handle_isolates parameter
- Priority: High - affects spectral methods which assume connectivity

**Numerical Edge Cases:**
- What's not tested: Near-singular matrices; very large/small sigma values; zero-variance features; unbalanced class labels with extreme ratios
- Files: `R/diffusion.R`, `R/commute_time.R`, `R/design_similarity_kernel.R`
- Risk: NaN/Inf propagation; incorrect kernel PSD properties; eigenvalue computation failures
- Priority: High - impacts scientific correctness

**Cross-Validation of Different NN Search Backends:**
- What's not tested: Equivalence between Rnanoflann, RcppHNSW, FNN, nabor on same data; round-trip accuracy
- Files: `R/searcher.R`, `R/knn_weights.R`
- Risk: Hidden algorithmic differences; performance regressions in migrations (like rflann → Rnanoflann)
- Priority: Medium - consistency across backends important but not critical

**Label Similarity with Unequal Classes:**
- What's not tested: Extreme class imbalance (e.g., 1 sample in class A, 10K in class B); single-sample classes; empty classes
- Files: `R/label_sim.R`, `R/class_graph.R`
- Risk: Dimension mismatches; inf/nan in similarity calculations; incorrect graph structure
- Priority: Medium - affects supervised learning applications

**Large Matrix Operations:**
- What's not tested: Performance and correctness with n > 50,000 nodes; memory usage validation; sparse matrix memory bloat
- Files: `R/spatial_constraints.R`, `R/spatial_weights.R`
- Risk: Out-of-memory crashes; unexpected slowdowns; performance assumptions violated at scale
- Priority: Medium - important for real-world applications but currently limited to smaller datasets

---

*Concerns audit: 2026-01-28*
