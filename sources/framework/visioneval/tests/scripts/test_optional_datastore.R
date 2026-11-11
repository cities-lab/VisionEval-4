# Run from sources/framework/visioneval with:
#   Rscript --vanilla tests/scripts/test_optional_datastore.R
# This source-level regression test does not need the full VisionEval library.

local({
sys.source("R/datastore.R", envir = environment())
sys.source("R/query.R", envir = environment())

test.env <- new.env(parent = environment())
getModelState <- function(envir) envir$ModelState_ls
setModelState <- function(ChangeState_ls = list(), envir) {
  envir$ModelState_ls[names(ChangeState_ls)] <- ChangeState_ls
  invisible(TRUE)
}
getYears <- function(envir) envir$ModelState_ls$Years
writeLog <- function(..., Level = "info") paste(...)
Types <- function() list(
  double = list(mode = "double"),
  integer = list(mode = "integer"),
  character = list(mode = "character"),
  logical = list(mode = "logical")
)
checkDataset <- function(Name, Table, Group, DstoreListing_df, envir = NULL) {
  paste(Group, Table, Name, sep = "/") %in% DstoreListing_df$groupname
}

expect_h5_dependency_error <- function(expr) {
  result <- tryCatch(force(expr), error = identity)
  stopifnot(inherits(result, "error"))
  stopifnot(grepl("requires the optional package 'rhdf5'", conditionMessage(result), fixed = TRUE))
}

test.dir <- tempfile("visioneval-datastore-")
dir.create(test.dir)
on.exit(unlink(test.dir, recursive = TRUE), add = TRUE)

test.env$ModelState_ls <- list(
  DatastoreName = "Datastore",
  ModelStatePath = test.dir,
  DatastorePath = test.dir,
  BaseYear = "2020",
  Years = "2020",
  Datastore = NULL
)

# The default RD backend must support a real write/read roundtrip without rhdf5.
assignDatastoreFunctions("RD", envir = test.env)
initDatastore(envir = test.env)
initTable("Metrics", "2020", 3, envir = test.env)
spec <- list(
  NAME = "value", TABLE = "Metrics", TYPE = "double", MODULE = "test",
  NAVALUE = -999, UNITS = "n", SIZE = 0
)
writeToTable(c(1, 2, 3), spec, "2020", envir = test.env)
values <- readFromTable("value", "Metrics", "2020", envir = test.env)
stopifnot(identical(as.numeric(values), c(1, 2, 3)))

if (!requireNamespace("rhdf5", quietly = TRUE)) {
  expect_h5_dependency_error(assignDatastoreFunctions("H5", envir = test.env))
  expect_h5_dependency_error(listDatastoreH5(envir = test.env))
  expect_h5_dependency_error(initDatastoreH5(envir = test.env))
  expect_h5_dependency_error(initTableH5("Metrics", "2020", 3, envir = test.env))
  expect_h5_dependency_error(initDatasetH5(spec, "2020", envir = test.env))
  expect_h5_dependency_error(readFromTableH5("value", "Metrics", "2020", envir = test.env))
  expect_h5_dependency_error(writeToTableH5(c(1, 2, 3), spec, "2020", envir = test.env))
  expect_h5_dependency_error(prepareForDatastoreQuery("missing", "H5"))

  copy.target <- tempfile("h5-copy-target-")
  dir.create(copy.target)
  expect_h5_dependency_error(copyDatastore(copy.target, DatastoreType = "H5", envir = test.env))
  stopifnot(length(list.files(copy.target, all.files = TRUE, no.. = TRUE)) == 0L)
  unlink(copy.target, recursive = TRUE)
} else {
  # Exercise the H5 backend when the optional Bioconductor package is present.
  h5.dir <- file.path(test.dir, "H5")
  dir.create(h5.dir)
  test.env$ModelState_ls$DatastoreName <- "Datastore.h5"
  test.env$ModelState_ls$ModelStatePath <- h5.dir
  assignDatastoreFunctions("H5", envir = test.env)
  initDatastore(envir = test.env)
  initTable("Metrics", "2020", 3, envir = test.env)
  writeToTable(c(1, 2, 3), spec, "2020", envir = test.env)
  h5.values <- readFromTable("value", "Metrics", "2020", envir = test.env)
  stopifnot(identical(as.numeric(h5.values), c(1, 2, 3)))
}

cat("Optional datastore dependency checks passed.\n")
})
