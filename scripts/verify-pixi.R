#!/usr/bin/env Rscript

local({
repo.root <- normalizePath(Sys.getenv("PIXI_PROJECT_ROOT", getwd()), mustWork = TRUE)
library.path <- file.path(repo.root, ".pixi", "ve-library")
.libPaths(c(library.path, .Library), include.site = FALSE)

description.files <- list.files(file.path(repo.root, "sources"), "^DESCRIPTION$", recursive = TRUE, full.names = TRUE)
packages <- vapply(description.files, function(path) read.dcf(path, fields = "Package")[1, 1], character(1))
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing local VisionEval packages: ", paste(missing, collapse = ", "))
if (requireNamespace("rhdf5", quietly = TRUE)) stop("Optional rhdf5 is installed in the default Pixi environment.")
if (!identical(as.character(utils::packageVersion("visioneval")), unname(read.dcf(file.path(repo.root, "sources/framework/visioneval/DESCRIPTION"), fields = "Version")[1, 1]))) {
  stop("Installed visioneval version does not match the source tree.")
}

library(VEModel)
stopifnot(identical(as.character(visioneval::defaultVERunParameters()$DatastoreType), "RD"))
survey.data <- new.env(parent = emptyenv())
utils::data(list = "Hh_df", package = "VE2001NHTS", envir = survey.data)
stopifnot(is.data.frame(survey.data$Hh_df))

# Exercise GDAL/PROJ-backed sf operations and a real GeoPackage roundtrip.
point <- sf::st_sfc(sf::st_point(c(-122.67, 45.52)), crs = 4326)
projected <- sf::st_transform(point, 3857)
gpkg <- tempfile(fileext = ".gpkg")
on.exit(unlink(gpkg), add = TRUE)
sf::st_write(sf::st_sf(id = 1L, geometry = projected), gpkg, quiet = TRUE)
reloaded <- sf::st_read(gpkg, quiet = TRUE)
stopifnot(nrow(reloaded) == 1L, sf::st_crs(reloaded) == sf::st_crs(projected))

# Exercise the installed RD backend independently of the source-level tests.
rd.path <- tempfile("ve-pixi-rd-")
dir.create(rd.path)
on.exit(unlink(rd.path, recursive = TRUE), add = TRUE)
state <- new.env(parent = asNamespace("visioneval"))
state$ModelStateFile <- file.path(rd.path, "ModelState.Rda")
state$ModelState_ls <- list(
  DatastoreName = "Datastore",
  ModelStatePath = rd.path,
  DatastorePath = rd.path,
  BaseYear = "2020",
  Years = "2020",
  Datastore = NULL
)
save("ModelState_ls", file = state$ModelStateFile, envir = state)
visioneval::assignDatastoreFunctions("RD", envir = state)
visioneval::initDatastore(envir = state)
visioneval::initTable("Metrics", "2020", 3, envir = state)
spec <- list(NAME = "value", TABLE = "Metrics", TYPE = "double", MODULE = "test", NAVALUE = -999, UNITS = "n", SIZE = 0)
visioneval::writeToTable(c(1, 2, 3), spec, "2020", envir = state)
values <- visioneval::readFromTable("value", "Metrics", "2020", envir = state)
stopifnot(identical(as.numeric(values), c(1, 2, 3)))

message("All ", length(packages), " local packages are installed; Pixi R startup, RD roundtrip, and GDAL/PROJ smoke checks passed; rhdf5 is absent.")
})
