#' Construct a Sparse Matrix of Spatial Constraints for Data Blocks
#'
#' This function creates a sparse matrix of spatial constraints for a set of data blocks. The spatial constraints matrix is useful in applications like image segmentation, where spatial information is crucial for identifying different regions in the image.
#'
#' @section Details:
#' The function computes within-block and between-block constraints based on the provided coordinates, bandwidths, and other input parameters. It then balances the within-block and between-block constraints using a shrinkage factor, and normalizes the resulting matrix by the first eigenvalue.
#'
#' @param coords The spatial coordinates as a matrix with rows as objects and columns as dimensions; or as a list of matrices where each element of the list contains the coordinates for a block.
#' @param nblocks The number of coordinate blocks. Default is 1. If `coords` is
#'   a list and `nblocks` is omitted, it is inferred from `length(coords)`.
#' @param sigma_within The bandwidth of the within-block smoother. Default is 5.
#' @param sigma_between The bandwidth of the between-block smoother. Default is 1.
#' @param shrinkage_factor The amount of shrinkage towards the spatial block average. Default is 0.1.
#' @param nnk_within The maximum number of nearest neighbors for within-block smoother. Default is 27.
#' @param nnk_between The maximum number of nearest neighbors for between-block smoother. Default is 1.
#' @param weight_mode_within The within-block nearest neighbor weight mode ("heat" or "binary"). Default is "heat".
#' @param weight_mode_between The between-block nearest neighbor weight mode ("heat" or "binary"). Default is "binary".
#' @param variable_weights A vector of per-variable weights. Default is 1.
#' @param verbose A boolean indicating whether to print progress messages. Default is FALSE.
#'
#' @return A sparse matrix representing the spatial constraints for the provided data blocks.
#'
#' @examples
#' coords <- as.matrix(expand.grid(1:2, 1:2))
#' S <- spatial_constraints(coords, nblocks=1, sigma_within=1, nnk_within=3)
#' dim(S)
#'
#' @importFrom utils head
#' @export
spatial_constraints <- function(coords, nblocks=1,
                                sigma_within=5,
                                sigma_between=1,
                                shrinkage_factor=.1,
                                nnk_within=27,
                                nnk_between=1,
                                weight_mode_within="heat",
                                weight_mode_between="binary",
                                variable_weights=1, verbose=FALSE) {

  normalize_by_leading_eigen <- function(S) {
    if (!inherits(S, "Matrix")) {
      S <- Matrix::Matrix(S, sparse = TRUE)
    }
    if (!length(S@x)) {
      return(S)
    }

    use_symmetric_solver <- isTRUE(Matrix::isSymmetric(S))
    leading <- tryCatch({
      if (use_symmetric_solver) {
        RSpectra::eigs_sym(
          S, k = 1, which = "LA", opts = list(retvec = FALSE)
        )$values[1]
      } else {
        Mod(RSpectra::eigs(
          S, k = 1, which = "LM", opts = list(retvec = FALSE)
        )$values[1])
      }
    }, error = function(e) {
      vals <- eigen(as.matrix(S), symmetric = use_symmetric_solver, only.values = TRUE)$values
      if (use_symmetric_solver) max(Re(vals)) else max(Mod(vals))
    })

    leading <- as.numeric(Re(leading))
    if (!is.finite(leading) || leading <= 0) {
      stop("Failed to compute a positive leading eigenvalue for constraint normalization.")
    }
    S / leading
  }

  nblocks_missing <- missing(nblocks)

  assertthat::assert_that(
    length(nblocks) == 1,
    is.finite(nblocks),
    nblocks >= 1,
    abs(nblocks - round(nblocks)) < .Machine$double.eps^0.5,
    msg = "`nblocks` must be a positive integer."
  )
  nblocks <- as.integer(nblocks)

  assertthat::assert_that(
    length(shrinkage_factor) == 1,
    is.finite(shrinkage_factor),
    shrinkage_factor > 0 && shrinkage_factor <= 1,
    msg = "`shrinkage_factor` must be in (0, 1]."
  )
  assertthat::assert_that(
    is.finite(sigma_within) && sigma_within > 0,
    is.finite(sigma_between) && sigma_between > 0,
    msg = "`sigma_within` and `sigma_between` must be positive."
  )
  assertthat::assert_that(
    length(nnk_within) == 1 && is.finite(nnk_within) && nnk_within >= 1 &&
      abs(nnk_within - round(nnk_within)) < .Machine$double.eps^0.5,
    length(nnk_between) == 1 && is.finite(nnk_between) && nnk_between >= 1 &&
      abs(nnk_between - round(nnk_between)) < .Machine$double.eps^0.5,
    msg = "`nnk_within` and `nnk_between` must be positive integers."
  )

  valid_modes <- c("heat", "binary")
  assertthat::assert_that(
    weight_mode_within %in% valid_modes,
    weight_mode_between %in% valid_modes,
    msg = "`weight_mode_within` and `weight_mode_between` must be one of: 'heat', 'binary'."
  )

  coords_is_list <- is.list(coords)
  if (coords_is_list) {
    coords_list <- lapply(coords, as.matrix)
    inferred_nblocks <- length(coords_list)
    if (nblocks_missing) {
      nblocks <- inferred_nblocks
    }
    assertthat::assert_that(
      inferred_nblocks == nblocks,
      msg = "`nblocks` must match `length(coords)` when `coords` is a list."
    )
  } else {
    coords_mat <- as.matrix(coords)
    coords_list <- replicate(nblocks, coords_mat, simplify = FALSE)
  }

  block_sizes <- vapply(coords_list, nrow, integer(1))
  block_dims <- vapply(coords_list, ncol, integer(1))
  assertthat::assert_that(all(block_sizes > 0), msg = "Each coordinate block must contain at least one row.")
  assertthat::assert_that(length(unique(block_dims)) == 1, msg = "All coordinate blocks must have the same number of columns.")
  assertthat::assert_that(
    all(vapply(coords_list, function(x) is.numeric(x) && all(is.finite(x)), logical(1))),
    msg = "`coords` must contain only finite numeric values."
  )

  nvars <- sum(block_sizes)
  if (length(variable_weights) == 1L) {
    assertthat::assert_that(
      is.finite(variable_weights) && variable_weights >= 0,
      msg = "`variable_weights` must be non-negative."
    )
    variable_weights <- rep(variable_weights, nvars)
  } else {
    assertthat::assert_that(
      length(variable_weights) == nvars,
      msg = sprintf(
        "`variable_weights` must have length 1 or length %d (total rows across blocks).",
        nvars
      )
    )
    assertthat::assert_that(
      all(is.finite(variable_weights)),
      all(variable_weights >= 0),
      msg = "`variable_weights` entries must be finite and non-negative."
    )
  }

  if (verbose) {
    message("spatial_constraints: computing within-block adjacency")
  }
  Sw_blocks <- lapply(coords_list, function(block_coords) {
    spatial_adjacency(
      block_coords,
      sigma = sigma_within,
      weight_mode = weight_mode_within,
      nnk = nnk_within,
      normalized = FALSE,
      stochastic = TRUE,
      handle_isolates = "self_loop"
    )
  })
  Swithin <- if (nblocks == 1L) Sw_blocks[[1L]] else Matrix::bdiag(Sw_blocks)

  if (any(variable_weights[1L] != variable_weights)) {
    Wg <- Matrix::Diagonal(x = sqrt(variable_weights))
    Swithin <- Wg %*% Swithin %*% Wg
  }

  if (nblocks == 1L) {
    return(normalize_by_leading_eigen(Swithin))
  }

  if (verbose) {
    message("spatial_constraints: computing between-block adjacency")
  }

  if (!coords_is_list) {
    Sb_one <- spatial_adjacency(
      coords_list[[1L]],
      sigma = sigma_between,
      weight_mode = weight_mode_between,
      normalized = FALSE,
      nnk = nnk_between,
      stochastic = TRUE,
      handle_isolates = "self_loop"
    )
    block_links <- Matrix::Matrix(1, nblocks, nblocks, sparse = TRUE)
    Matrix::diag(block_links) <- 0
    Sbfin <- Matrix::kronecker(block_links, Sb_one)
  } else {
    all_coords <- do.call(rbind, coords_list)
    Sbfin <- spatial_adjacency(
      all_coords,
      sigma = sigma_between,
      weight_mode = weight_mode_between,
      normalized = FALSE,
      nnk = nnk_between,
      stochastic = TRUE,
      handle_isolates = "self_loop"
    )
    offsets <- cumsum(c(0L, head(block_sizes, -1L)))
    for (i in seq_len(nblocks)) {
      idx <- seq.int(offsets[i] + 1L, offsets[i] + block_sizes[i])
      Sbfin[idx, idx] <- 0
    }
  }

  if (length(Sbfin@x)) {
    if (verbose) {
      message("spatial_constraints: making between-block adjacency doubly stochastic")
    }
    Sbfin <- make_doubly_stochastic(Sbfin)
  } else {
    Sbfin <- Matrix::Matrix(
      0,
      nrow = nrow(Swithin),
      ncol = ncol(Swithin),
      sparse = TRUE
    )
  }

  total_within <- sum(Swithin)
  total_between <- sum(Sbfin)

  if (total_within <= 0 || !is.finite(total_within)) {
    warning("Within-block weights sum to zero; returning between-block constraints only.")
    return(normalize_by_leading_eigen(Sbfin))
  }
  if (total_between <= 0 || !is.finite(total_between)) {
    warning("Between-block weights sum to zero; returning within-block constraints only.")
    return(normalize_by_leading_eigen(Swithin))
  }

  ratio_within_to_between <- total_within / total_between
  Stot <- (1 - shrinkage_factor) * (Swithin / ratio_within_to_between) +
    shrinkage_factor * Sbfin

  if (verbose) {
    message("spatial_constraints: normalizing by dominant eigenvalue")
  }
  normalize_by_leading_eigen(Stot)

}

#' Construct Feature-Weighted Spatial Constraints for Data Blocks
#'
#' This function creates a sparse matrix of feature-weighted spatial constraints for a set of data blocks. The feature-weighted spatial constraints matrix is useful in applications like image segmentation and analysis, where both spatial and feature information are crucial for identifying different regions in the image.
#'
#' @section Details:
#' The function computes within-block and between-block constraints based on the provided coordinates, feature matrices, and other input parameters. It balances the within-block and between-block constraints using a shrinkage factor, and normalizes the resulting matrix by the first eigenvalue. The function also takes into account the weights of the variables in the provided feature matrices.
#'
#' @param coords The spatial coordinates as a matrix with rows as objects and columns as dimensions.
#' @param feature_mats A list of feature matrices, one for each data block.
#' @param sigma_within The bandwidth of the within-block smoother. Default is 5.
#' @param sigma_between The bandwidth of the between-block smoother. Default is 3.
#' @param wsigma_within The bandwidth of the within-block feature weights. Default is 0.73.
#' @param wsigma_between The bandwidth of the between-block feature weights. Default is 0.73.
#' @param alpha_within The scaling factor for within-block feature weights. Default is 0.5.
#' @param alpha_between The scaling factor for between-block feature weights. Default is 0.5.
#' @param shrinkage_factor The amount of shrinkage towards the spatial block average. Default is 0.1.
#' @param nnk_within The maximum number of nearest neighbors for within-block smoother. Default is 27.
#' @param nnk_between The maximum number of nearest neighbors for between-block smoother. Default is 27.
#' @param maxk_within The maximum number of nearest neighbors for within-block computation. Default is `nnk_within`.
#' @param maxk_between The maximum number of nearest neighbors for between-block computation. Default is `nnk_between`.
#' @param weight_mode_within The within-block nearest neighbor weight mode ("heat" or "binary"). Default is "heat".
#' @param weight_mode_between The between-block nearest neighbor weight mode ("heat" or "binary"). Default is "binary".
#' @param variable_weights A vector of per-variable weights. Default is a vector of ones with length equal to the product of the number of columns in the `coords` matrix and the length of `feature_mats`.
#' @param verbose A boolean indicating whether to print progress messages. Default is FALSE.
#'
#' @return A sparse matrix representing the feature-weighted spatial constraints for the provided data blocks.
#'
#' @examples
#' set.seed(123)
#' coords <- as.matrix(expand.grid(1:4, 1:4))
#' fmats <- replicate(3, matrix(rnorm(16 * 4), 4, 16), simplify = FALSE)
#' conmat <- feature_weighted_spatial_constraints(
#'   coords, fmats,
#'   sigma_within = 1.5, sigma_between = 1.5,
#'   nnk_within = 4, nnk_between = 4,
#'   maxk_within = 3, maxk_between = 2
#' )
#'
#' conmat <- feature_weighted_spatial_constraints(
#'   coords, fmats,
#'   alpha_within = 0.3, alpha_between = 0.7,
#'   maxk_between = 2, maxk_within = 2,
#'   sigma_between = 2, nnk_between = 4
#' )
#'
#' @export
feature_weighted_spatial_constraints <- function(coords,
                                                 feature_mats,
                                                 sigma_within=5,
                                                 sigma_between=3,
                                                 wsigma_within=.73,
                                                 wsigma_between=.73,
                                                 alpha_within=.5,
                                                 alpha_between=.5,
                                                 shrinkage_factor=.1,
                                                 nnk_within=27,
                                                 nnk_between=27,
                                                 maxk_within=nnk_within,
                                                 maxk_between=nnk_between,
                                                 weight_mode_within="heat",
                                                 weight_mode_between="binary",
                                                 variable_weights=rep(1, ncol(coords)*length(feature_mats)), verbose=FALSE) {

  assert_that(shrinkage_factor > 0 & shrinkage_factor <= 1)

  coords <- as.matrix(coords)
  nvox <- nrow(coords)
  nblocks <- length(feature_mats)

  if (requireNamespace("furrr", quietly = TRUE)) {
    Swl <- furrr::future_map(seq_along(feature_mats), function(i) {
      sw <- weighted_spatial_adjacency(coords, t(feature_mats[[i]]),
                                                        alpha=alpha_within,
                                                        wsigma=wsigma_within,
                                                        sigma=sigma_within,
                                                        weight_mode=weight_mode_within,
                                                        nnk=nnk_within, normalized=TRUE, stochastic=FALSE)
      make_doubly_stochastic(sw)
    })
  } else {
    Swl <- lapply(seq_along(feature_mats), function(i) {
      sw <- weighted_spatial_adjacency(coords, t(feature_mats[[i]]),
                                                        alpha=alpha_within,
                                                        wsigma=wsigma_within,
                                                        sigma=sigma_within,
                                                        weight_mode=weight_mode_within,
                                                        nnk=nnk_within, normalized=TRUE, stochastic=FALSE)
      make_doubly_stochastic(sw)
    })
  }


  Swithin <- Matrix::bdiag(Swl)

  assertthat::assert_that(length(feature_mats) >= 2,
    msg = "'feature_mats' must contain at least 2 feature blocks")
  cmb <- t(combn(seq_along(feature_mats), 2))

  offsets <- cumsum(c(0, rep(nvox, nblocks-1)))


  .between_fn <- function(i) {
    a <- cmb[i,1]
    b <- cmb[i,2]
    sm <- cross_weighted_spatial_adjacency(
      coords, coords, t(feature_mats[[a]]), t(feature_mats[[b]]),
      wsigma=wsigma_between, weight_mode=weight_mode_between,
      alpha=alpha_between,
      nnk=nnk_between, maxk=maxk_between,
      sigma=sigma_between, normalized=FALSE)
    if (length(sm@x)) sm <- make_doubly_stochastic(sm)

    sm_nc <- as (sm, "dgTMatrix")
    r1 <- cbind (i = sm_nc@i + 1 + offsets[a], j = sm_nc@j + 1 + offsets[b], x = sm_nc@x)
    r2 <- cbind (i = sm_nc@j + 1 + offsets[b], j = sm_nc@i + 1 + offsets[a], x = sm_nc@x)
    rbind(r1,r2)
  }
  if (requireNamespace("furrr", quietly = TRUE)) {
    bet <- do.call(rbind, furrr::future_map(seq_len(nrow(cmb)), .between_fn))
  } else {
    bet <- do.call(rbind, lapply(seq_len(nrow(cmb)), .between_fn))
  }


  Sbfin <- sparseMatrix(i=bet[,1], j=bet[,2], x=bet[,3], dims=c(nvox*nblocks, nvox*nblocks))

  Sbfin <- make_doubly_stochastic(Sbfin)


  ## scale within matrix by variable weights
  if (any(variable_weights[1] != variable_weights)) {
    Wg <- Diagonal(x=sqrt(variable_weights))
    Swithin <- Wg %*% Swithin %*% Wg
  }

  ## compute ratio of within to between weights
  rat <- sum(Swithin)/sum(Sbfin)
  ## balance within and between weights
  Stot <- (1-shrinkage_factor)*(1/rat)*Swithin + shrinkage_factor*Sbfin

  eval <- tryCatch(RSpectra::eigs_sym(Stot, k=1, which="LA")$values[1], error = function(e) NA_real_)
  if (is.na(eval) || eval <= 0) {
    warning("Could not normalize by leading eigenvalue; returning unnormalized matrix")
    S <- Stot
  } else {
    S <- Stot / eval
  }
  S

}
