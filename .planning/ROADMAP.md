# Roadmap: neighborweights CRAN Submission

## Overview

Transform neighborweights from a working R package into a CRAN-ready submission by cleaning deprecated code, polishing documentation, improving test coverage, and passing all CRAN checks. The journey progresses from removing technical debt, through documentation completeness, to final validation.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Package Cleanup** - Remove deprecated code and fix immediate check issues
- [ ] **Phase 2: Documentation & Testing** - Complete docs, add vignette, improve test coverage
- [ ] **Phase 3: CRAN Validation** - Final check and submission readiness

## Phase Details

### Phase 1: Package Cleanup
**Goal**: Package has clean API surface with no deprecated functions and immediate check issues resolved
**Depends on**: Nothing (first phase)
**Requirements**: API-01, API-02, API-03, API-04, CHECK-01, CHECK-02
**Success Criteria** (what must be TRUE):
  1. All deprecated function aliases (label_matrix, label_matrix2, discriminating_simililarity) are removed from the codebase
  2. Internal code uses only current function names (diagonal_label_matrix, discriminating_similarity)
  3. .planning directory is ignored by R CMD check (added to .Rbuildignore)
  4. Compiler warning investigation is complete with resolution documented
**Plans:** 3 plans

Plans:
- [ ] 01-01-PLAN.md — Update internal code to use current function names, add .Rbuildignore entry
- [ ] 01-02-PLAN.md — Remove deprecated function definitions and their tests
- [ ] 01-03-PLAN.md — Investigate compiler warning and document findings

### Phase 2: Documentation & Testing
**Goal**: Package has complete documentation with introductory vignette and improved test coverage
**Depends on**: Phase 1
**Requirements**: DOCS-01, DOCS-02, DOCS-03, TEST-01, TEST-02
**Success Criteria** (what must be TRUE):
  1. All exported functions have complete roxygen2 documentation with examples that run without error
  2. Introductory vignette demonstrates core workflows (spatial adjacency, knn graphs, class graphs)
  3. NEWS.md file exists with version history
  4. Test coverage for R/spatial_constraints.R improved from 67% to at least 75%
  5. Test coverage for R/spatial_weights.R improved from 80% to at least 85%
**Plans**: TBD

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD
- [ ] 02-03: TBD

### Phase 3: CRAN Validation
**Goal**: Package passes R CMD check --as-cran with 0 errors, 0 warnings, 0 notes
**Depends on**: Phase 2
**Requirements**: CHECK-03
**Success Criteria** (what must be TRUE):
  1. R CMD check --as-cran completes with 0 errors
  2. R CMD check --as-cran completes with 0 warnings
  3. R CMD check --as-cran completes with 0 notes
  4. Package is ready for CRAN submission
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Package Cleanup | 0/3 | Ready to execute | - |
| 2. Documentation & Testing | 0/TBD | Not started | - |
| 3. CRAN Validation | 0/TBD | Not started | - |
