library(testthat)
library(Matrix)
library(igraph)

context("Neighbor graph extended tests")

# ---------- neighbor_graph.matrix (plain matrix constructor) ----------

test_that("neighbor_graph.matrix creates valid object from plain matrix", {
  mat <- matrix(c(0, 1, 0, 1, 0, 1, 0, 1, 0), nrow = 3)
  ng <- neighbor_graph(mat)

  expect_true(inherits(ng, "neighbor_graph"))
  expect_true(inherits(ng$G, "igraph"))
  expect_equal(igraph::vcount(ng$G), 3)
})

test_that("neighbor_graph.matrix handles zero matrix", {
  mat <- matrix(0, nrow = 3, ncol = 3)
  ng <- neighbor_graph(mat)

  expect_true(inherits(ng, "neighbor_graph"))
  expect_equal(igraph::ecount(ng$G), 0)
})

# ---------- neighbor_graph with extra params and classes ----------

test_that("neighbor_graph stores custom params", {
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(3, 3))
  ng <- neighbor_graph(adj, params = list(k = 5, method = "test"))

  expect_equal(ng$params$k, 5)
  expect_equal(ng$params$method, "test")
})

test_that("neighbor_graph stores custom classes", {
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(3, 3))
  ng <- neighbor_graph(adj, classes = "my_custom_graph")

  expect_true(inherits(ng, "my_custom_graph"))
  expect_true(inherits(ng, "neighbor_graph"))
})

# ---------- laplacian normalized ----------

test_that("laplacian normalized=TRUE produces valid normalized Laplacian", {
  adj <- sparseMatrix(i = c(1, 2, 3, 2, 3, 1),
                      j = c(2, 3, 1, 1, 2, 3),
                      x = rep(1, 6), dims = c(3, 3))
  ng <- neighbor_graph(adj)

  L_norm <- laplacian(ng, normalized = TRUE)

  expect_true(inherits(L_norm, "Matrix"))
  expect_equal(dim(L_norm), c(3, 3))
  expect_true(Matrix::isSymmetric(L_norm))

  # Diagonal entries of normalized Laplacian should be 1 for connected nodes
  expect_true(all(abs(diag(as.matrix(L_norm)) - 1) < 1e-10))
})

test_that("laplacian normalized handles isolated nodes", {
  # Node 4 is isolated
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 1), x = c(1, 1), dims = c(4, 4))
  ng <- neighbor_graph(adj)

  L_norm <- laplacian(ng, normalized = TRUE)

  expect_equal(dim(L_norm), c(4, 4))
  # Normalized Laplacian is I - D^{-1/2} A D^{-1/2}
  # For isolated node, D^{-1/2} A D^{-1/2} = 0, so L_norm diagonal = 1 (from I)
  expect_equal(as.matrix(L_norm)[4, 4], 1)
})

# ---------- neighbors.neighbor_graph ----------

test_that("neighbors returns all neighbors when i is missing", {
  adj <- sparseMatrix(i = c(1, 1, 2), j = c(2, 3, 3), x = c(1, 1, 1), dims = c(3, 3))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  all_neighs <- neighbors(ng)

  expect_true(is.list(all_neighs))
  expect_equal(length(all_neighs), 3)
})

test_that("neighbors returns correct neighbors for specific node", {
  adj <- sparseMatrix(i = c(1, 1), j = c(2, 3), x = c(1, 1), dims = c(4, 4))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  neighs <- neighbors(ng, 1)

  expect_true(is.list(neighs))
  # Node 1 is connected to 2 and 3
  expect_true(all(sort(neighs[[1]]) == c(2, 3)))
})

test_that("neighbors for multiple nodes", {
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 3), x = c(1, 1), dims = c(3, 3))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  neighs <- neighbors(ng, c(1, 3))

  expect_true(is.list(neighs))
  expect_equal(length(neighs), 2)
})

# ---------- non_neighbors.neighbor_graph ----------

test_that("non_neighbors returns correct non-neighbor indices", {
  adj <- sparseMatrix(i = c(1), j = c(2), x = c(1), dims = c(4, 4))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  nn <- non_neighbors(ng, 1)

  # Node 1 is connected to 2, so non-neighbors should be 3 and 4
  expect_true(all(sort(nn) == c(3, 4)))
})

test_that("non_neighbors excludes self", {
  adj <- sparseMatrix(i = c(1, 1), j = c(2, 3), x = c(1, 1), dims = c(3, 3))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  nn <- non_neighbors(ng, 1)

  # Node 1 is connected to 2 and 3, and excludes itself
  expect_equal(length(nn), 0)
})

# ---------- node_density.neighbor_graph ----------

test_that("node_density returns correct length", {
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 3), x = c(1, 1), dims = c(3, 3))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  X <- matrix(c(0, 0, 1, 0, 2, 0), ncol = 2, byrow = TRUE)
  densities <- node_density(ng, X)

  expect_equal(length(densities), 3)
  expect_true(all(is.finite(densities)))
  expect_true(all(densities >= 0))
})

test_that("node_density is zero for isolated nodes", {
  adj <- sparseMatrix(i = c(1), j = c(2), x = c(1), dims = c(3, 3))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  X <- matrix(c(0, 0, 1, 0, 5, 5), ncol = 2, byrow = TRUE)
  densities <- node_density(ng, X)

  # Node 3 is isolated, density should be 0
  expect_equal(densities[3], 0)
})

# ---------- edges.neighbor_graph ----------

test_that("edges returns correct edge list", {
  adj <- sparseMatrix(i = c(1, 2), j = c(2, 3), x = c(1, 1), dims = c(3, 3))
  adj <- adj + t(adj)
  ng <- neighbor_graph(adj)

  e <- edges(ng)

  expect_true(is.matrix(e) || is.data.frame(e))
  expect_equal(ncol(e), 2)
  expect_true(nrow(e) >= 2)
})

# ---------- nvertices ----------

test_that("nvertices returns correct count for various sizes", {
  for (n in c(1, 5, 10)) {
    adj <- sparseMatrix(i = integer(0), j = integer(0), dims = c(n, n))
    ng <- neighbor_graph(adj)
    expect_equal(nvertices(ng), n)
  }
})
