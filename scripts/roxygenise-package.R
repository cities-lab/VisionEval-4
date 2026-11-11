#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || length(args) > 2L) stop("Usage: roxygenise-package.R <staged-package-directory> [pkgload|source]")
repo.root <- normalizePath(Sys.getenv("PIXI_PROJECT_ROOT", getwd()), mustWork = TRUE)
staged.path <- normalizePath(args[[1]], mustWork = TRUE)
setwd(staged.path)
.libPaths(c(file.path(repo.root, ".pixi", "ve-library"), .Library), include.site = FALSE)
fields <- read.dcf("DESCRIPTION", fields = "Roxygen")
roxygen.config <- if (nrow(fields) && !is.na(fields[1, 1])) fields[1, 1] else ""
load.method <- if (length(args) == 2L) args[[2]] else if (
  grepl("load[[:space:]]*=[[:space:]]*['\"]source", roxygen.config)
) "source" else "pkgload"
roxygen2::update_collate(staged.path)
roxygen2::roxygenise(".", roclets = "namespace", load_code = load.method)
