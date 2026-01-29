# External Integrations

**Analysis Date:** 2026-01-28

## APIs & External Services

**Not detected** - This package does not integrate with external web APIs, cloud services, or network-based endpoints. All processing is local and in-memory.

## Data Storage

**Databases:**
- Not used. Package operates entirely in-memory on data matrices passed as function arguments
- No database connections (DBI, RSQLite, RPostgres, RMariaDB) detected

**File Storage:**
- Local filesystem only for:
  - Package source code in `R/`, `src/`, `man/`
  - Test data in `test_data/`, `data-raw/`
  - Test fixtures in `tests/testthat/`
- No integration with S3, cloud storage, or remote file systems

**Caching:**
- None. All computations are stateless; results are cached only in memory during R session
- igraph objects and nnsearcher objects hold computed state (indices, distance matrices) in memory

## Authentication & Identity

**Auth Provider:**
- Not applicable. No authentication required.
- Package is self-contained with no external service calls
- No API keys, tokens, or credentials needed

**Implementation:**
- N/A

## Monitoring & Observability

**Error Tracking:**
- Not detected. No integration with error tracking services (Sentry, Rollbar, etc.)
- Error handling via R's standard `stop()`, `warning()` functions throughout codebase

**Logs:**
- Console output via base R functions: `message()`, `warning()`, `cat()`
- crayon library provides colored terminal output for readability
- No log aggregation or persistent logging framework

**Example logging approach** (from `R/` files):
- `assertthat::assert_that()` for validation with error messages
- `warning()` for non-fatal issues (e.g., isolated nodes in diffusion kernel)
- Console output for informational messages

## CI/CD & Deployment

**Hosting:**
- GitHub repository: `bbuchsbaum/neighborweights`
- Installation via: `devtools::install_github("bbuchsbaum/neighborweights")`
- Not published to CRAN (development package)

**CI Pipeline:**
- `.github/` directory exists but CI workflow not detailed
- R CMD CHECK for CRAN compliance
- Tests run via `devtools::test()` or `testthat::test_check("neighborweights")`

**Build:**
- No external build service detected (no .travis.yml, appveyor.yml, or GitHub Actions workflows visible)
- Local build via R CMD commands: `R CMD build`, `R CMD check`

## Environment Configuration

**Required env vars:**
- None. Package requires no environment variables.
- All configuration via function parameters (e.g., `k`, `sigma`, `distance` metric in search functions)

**Optional env vars:**
- None detected

**Secrets location:**
- Not applicable. No secrets management needed.
- Package is fully open-source with no authentication credentials

## Webhooks & Callbacks

**Incoming:**
- None. Package does not expose any web endpoints or webhook receivers.

**Outgoing:**
- None. Package does not call external webhooks or make HTTP requests.

## Package Dependencies Network

All external dependencies are R packages from CRAN:

**Direct imports** (from DESCRIPTION):
```
Rcpp, Matrix, RcppHNSW, assertthat, Rnanoflann, chk, FNN,
RSpectra, crayon, igraph, mgcv, corpcor, furrr, proxy,
parallel, stats, methods, utils
```

**Linking dependencies** (C++ libraries):
- RcppArmadillo - Provides Armadillo header-only linear algebra library
- Rcpp - Header-only C++ integration

**No circular dependencies detected** - Package is a leaf node in dependency tree.

---

*Integration audit: 2026-01-28*
