# Requirements: neighborweights CRAN Submission

**Defined:** 2026-01-28
**Core Value:** Pass CRAN checks with 0 errors, 0 warnings, 0 notes and provide quality documentation

## v1 Requirements

### R CMD Check Compliance

- [ ] **CHECK-01**: Add .planning to .Rbuildignore to eliminate hidden directory NOTE
- [ ] **CHECK-02**: Investigate and address compiler WARNING (R header flag noise)
- [ ] **CHECK-03**: Pass R CMD check --as-cran with 0 errors, 0 warnings, 0 notes

### Documentation

- [ ] **DOCS-01**: All exported functions have complete roxygen2 documentation (@title, @description, @param, @return, @examples)
- [ ] **DOCS-02**: Create introductory vignette demonstrating core workflows (spatial adjacency, knn graphs, class graphs)
- [ ] **DOCS-03**: Add NEWS.md file tracking version history

### API Cleanup

- [ ] **API-01**: Remove deprecated label_matrix function and its references
- [ ] **API-02**: Remove deprecated label_matrix2 function and its references
- [ ] **API-03**: Remove deprecated discriminating_simililarity function (typo version)
- [ ] **API-04**: Update any internal code that uses deprecated functions to use new names

### Test Coverage

- [ ] **TEST-01**: Improve test coverage for R/spatial_constraints.R (currently 67%)
- [ ] **TEST-02**: Improve test coverage for R/spatial_weights.R (currently 80%)

## v2 Requirements

### Post-Submission Polish

- **SITE-01**: pkgdown documentation website
- **CI-01**: GitHub Actions for automated testing
- **BADGE-01**: CRAN status badge in README

## Out of Scope

| Feature | Reason |
|---------|--------|
| New functionality | Focus is submission readiness, not capability expansion |
| Performance optimization | Current performance is adequate for CRAN |
| Breaking API changes beyond deprecated removal | Minimize user impact |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CHECK-01 | Phase 1 | Pending |
| CHECK-02 | Phase 1 | Pending |
| CHECK-03 | Phase 3 | Pending |
| DOCS-01 | Phase 2 | Pending |
| DOCS-02 | Phase 2 | Pending |
| DOCS-03 | Phase 2 | Pending |
| API-01 | Phase 1 | Pending |
| API-02 | Phase 1 | Pending |
| API-03 | Phase 1 | Pending |
| API-04 | Phase 1 | Pending |
| TEST-01 | Phase 2 | Pending |
| TEST-02 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-01-28*
*Last updated: 2026-01-28 after initial definition*
