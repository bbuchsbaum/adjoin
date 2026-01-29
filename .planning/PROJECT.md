# neighborweights CRAN Submission

## What This Is

Preparing the `neighborweights` R package for CRAN submission. The package provides methods for constructing adjacency matrices based on spatial and feature similarity between data points, with applications in graph-based machine learning, spatial statistics, and dimensionality reduction.

## Core Value

Pass CRAN checks with 0 errors, 0 warnings, 0 notes and provide quality documentation that helps users understand the package's capabilities.

## Requirements

### Validated

- ✓ Spatial adjacency matrix construction — existing
- ✓ K-nearest neighbor graph construction — existing
- ✓ Class-based graph construction — existing
- ✓ Heat kernel and diffusion methods — existing
- ✓ Normalized and stochastic graph transformations — existing
- ✓ C++ performance optimizations via Rcpp/RcppArmadillo — existing
- ✓ S3 generic interface for extensibility — existing
- ✓ Basic test coverage (90% overall) — existing

### Active

- [ ] Clean R CMD check (0 errors, 0 warnings, 0 notes)
- [ ] Add .planning to .Rbuildignore to fix NOTE
- [ ] Remove deprecated function aliases (label_matrix, label_matrix2, discriminating_simililarity)
- [ ] Consistent function naming across API
- [ ] Introductory vignette demonstrating core workflows
- [ ] Polish roxygen2 documentation (@description, @details, @examples)
- [ ] Fill test coverage gaps (spatial_constraints, spatial_weights)
- [ ] NEWS.md file for CRAN

### Out of Scope

- New features — focus is submission readiness, not capability expansion
- Performance optimization — current performance is adequate
- pkgdown website — can be added post-submission
- GitHub Actions CI — nice-to-have but not required for CRAN

## Context

The package currently passes R CMD check with:
- 0 errors
- 1 warning (compiler flag noise from R headers, not package code)
- 1 note (.planning directory detected as hidden file)

Test coverage is at 90% overall. Two files have lower coverage:
- `R/spatial_constraints.R` (67%) — uses furrr::future_map making unit testing complex
- `R/spatial_weights.R` (80%) — spatial_autocor uses mgcv::gam

The package has 15 exported functions across graph construction, nearest neighbor search, weight computation, and spectral methods.

Codebase was recently migrated from deprecated `rflann` to `Rnanoflann` for nearest neighbor search.

## Constraints

- **R version**: >= 3.3.2 (already specified in DESCRIPTION)
- **Dependencies**: All must be available on CRAN
- **Documentation**: Must pass R CMD check --as-cran

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep existing API | Avoid breaking changes for current users | — Pending |
| Remove deprecated aliases | Clean API surface for new CRAN users | — Pending |
| Single introductory vignette | Sufficient for initial submission | — Pending |

---
*Last updated: 2026-01-28 after initialization*
