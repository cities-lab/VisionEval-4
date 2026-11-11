# Pixi sets this profile for interactive R sessions so the legacy VE bootstrap
# does not redirect libraries to ve-lib or trigger online installation.
pixi.root <- Sys.getenv("PIXI_PROJECT_ROOT")
if (nzchar(pixi.root)) {
  pixi.library <- file.path(pixi.root, ".pixi", "ve-library")
  .libPaths(c(pixi.library, .Library), include.site = FALSE)
}
rm(pixi.root)
if (exists("pixi.library", inherits = FALSE)) rm(pixi.library)
