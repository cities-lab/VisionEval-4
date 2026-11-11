#!/usr/bin/env Rscript

local({

repo.root <- normalizePath(Sys.getenv("PIXI_PROJECT_ROOT", getwd()), mustWork = TRUE)
sources.root <- file.path(repo.root, "sources")
library.path <- file.path(repo.root, ".pixi", "ve-library")
dir.create(library.path, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(library.path, .Library), include.site = FALSE)
Sys.setenv(
  R_LIBS_USER = library.path,
  R_LIBS_SITE = .Library,
  R_PROFILE_USER = file.path(repo.root, "scripts", "pixi-profile.R")
)

if (getRversion() < "4.5.0" || getRversion() >= "4.6.0") {
  stop("This Pixi environment is pinned to R 4.5.x; found R ", getRversion())
}

if (!requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("openssl", quietly = TRUE) ||
    !requireNamespace("roxygen2", quietly = TRUE)) {
  stop("Pixi R dependencies are incomplete. Run `pixi install` first.")
}

cran.lock <- jsonlite::fromJSON(
  file.path(repo.root, "pixi", "cran-sources.lock"),
  simplifyVector = FALSE
)
platform <- Sys.getenv("PIXI_PLATFORM", unset = "")
if (!nzchar(platform)) {
  platform <- switch(
    Sys.info()[["sysname"]],
    Linux = "linux-64",
    Darwin = if (R.version$arch %in% c("aarch64", "arm64")) "osx-arm64" else "osx-64",
    "unsupported"
  )
}
if (!platform %in% c("linux-64", "osx-64", "osx-arm64")) {
  stop("Unsupported Pixi platform: ", platform)
}

cran.cache <- file.path(repo.root, ".pixi", "downloads")
dir.create(cran.cache, recursive = TRUE, showWarnings = FALSE)
for (entry in cran.lock$packages) {
  if (!platform %in% entry$platforms) next
  if (requireNamespace(entry$name, quietly = TRUE) &&
      identical(as.character(utils::packageVersion(entry$name)), entry$version)) next
  archive <- file.path(cran.cache, basename(entry$url))
  if (!file.exists(archive)) {
    download.error <- tryCatch({
      utils::download.file(entry$url, archive, mode = "wb", quiet = FALSE)
      NULL
    }, error = identity)
    if (!is.null(download.error)) {
      unlink(archive)
      utils::download.file(entry$archive_url, archive, mode = "wb", quiet = FALSE)
    }
  }
  bytes <- readBin(archive, what = "raw", n = file.info(archive)$size)
  sha <- paste(sprintf("%02x", as.integer(openssl::sha256(bytes))), collapse = "")
  if (!identical(tolower(sha), tolower(entry$sha256))) {
    unlink(archive)
    stop("SHA-256 mismatch for pinned CRAN source package ", entry$name)
  }
  message("Installing pinned CRAN source package ", entry$name, " ", entry$version)
  status <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", paste0("--library=", shQuote(library.path)), shQuote(archive))
  )
  if (status != 0L) stop("Failed installing pinned CRAN package ", entry$name)
  if (as.character(utils::packageVersion(entry$name)) != entry$version) {
    stop("Installed wrong version of pinned package ", entry$name)
  }
}

description.files <- list.files(sources.root, "^DESCRIPTION$", recursive = TRUE, full.names = TRUE)
packages <- lapply(description.files, function(path) {
  fields <- read.dcf(path, fields = c("Package", "Depends", "Imports", "LinkingTo", "Suggests"))[1, ]
  # Local Suggests can be source-build dependencies (for example VEHouseholdTravel
  # loads data estimated by VE2001NHTS). External Suggests are not installed.
  dep.fields <- fields[intersect(c("Depends", "Imports", "LinkingTo", "Suggests"), names(fields))]
  dep.fields <- dep.fields[!is.na(dep.fields)]
  deps <- unlist(strsplit(paste(dep.fields, collapse = ","), ",", fixed = TRUE))
  deps <- trimws(sub("[[:space:]]*[(].*$", "", deps))
  deps <- setdiff(deps[nzchar(deps)], "R")
  list(name = fields[["Package"]], path = dirname(path), deps = unique(deps))
})
names(packages) <- vapply(packages, `[[`, character(1), "name")
if (anyDuplicated(names(packages))) stop("Duplicate local package names in sources/")

pending <- names(packages)
order <- character()
while (length(pending)) {
  ready <- pending[vapply(pending, function(name) {
    all(intersect(packages[[name]]$deps, names(packages)) %in% order)
  }, logical(1))]
  if (!length(ready)) {
    stop("Cyclic local package dependency graph: ", paste(pending, collapse = ", "))
  }
  order <- c(order, ready)
  pending <- setdiff(pending, ready)
}

# Suppress source-side package loading hooks while roxygen generates namespaces.
# Use a full copy: module loading can write data files, and a hard-linked stage
# would allow those writes to alter the user's checkout.
Sys.setenv(VE_BUILD_RUNNING = "Yes")
on.exit(Sys.unsetenv("VE_BUILD_RUNNING"), add = TRUE)
run.with.build.phase <- function(phase, code) {
  previous <- Sys.getenv("VE_BUILD_PHASE", unset = NA_character_)
  on.exit(if (is.na(previous)) Sys.unsetenv("VE_BUILD_PHASE") else Sys.setenv(VE_BUILD_PHASE = previous))
  Sys.setenv(VE_BUILD_PHASE = phase)
  force(code)
}
for (name in order) {
  package <- packages[[name]]
  installed <- tryCatch(as.character(utils::packageVersion(name)), error = function(e) NA_character_)
  source.version <- unname(read.dcf(file.path(package$path, "DESCRIPTION"), fields = "Version")[1, 1])
  if (identical(installed, source.version) && !identical(Sys.getenv("PIXI_FORCE_REINSTALL"), "1")) {
    message("Already installed: ", name, " ", installed)
    next
  }

  staged.path <- file.path(repo.root, ".pixi", "build", name)
  if (dir.exists(staged.path)) unlink(staged.path, recursive = TRUE)
  dir.create(staged.path, recursive = TRUE)
  staged.files <- list.files(package$path, recursive = TRUE, all.files = TRUE,
                             full.names = TRUE, include.dirs = TRUE, no.. = TRUE)
  relative.paths <- substring(staged.files, nchar(package$path) + 2L)
  for (i in seq_along(staged.files)) {
    source.path <- staged.files[i]
    target.path <- file.path(staged.path, relative.paths[i])
    info <- file.info(source.path)
    if (isTRUE(info$isdir)) {
      dir.create(target.path, recursive = TRUE, showWarnings = FALSE)
      next
    }
    dir.create(dirname(target.path), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(source.path, target.path, overwrite = TRUE)) {
      stop("Could not stage source file ", source.path)
    }
  }
  # Some module source files generate package data while loading; keep that
  # generated output confined to the disposable staging copy.
  data.path <- file.path(staged.path, "data")
  dir.create(data.path, showWarnings = FALSE)
  estimated.path <- file.path(staged.path, "data-raw", "estimated")
  if (dir.exists(estimated.path)) {
    estimated.files <- list.files(estimated.path, full.names = TRUE)
    if (length(estimated.files)) file.copy(estimated.files, data.path, overwrite = TRUE)
  }
  message("Generating NAMESPACE and installing ", name, " ", source.version)
  tryCatch({
    status <- run.with.build.phase("SAVE", system2(
      file.path(R.home("bin"), "Rscript"),
      c("--vanilla", shQuote(file.path(repo.root, "scripts", "roxygenise-package.R")), shQuote(staged.path))
    ))
    if (status != 0L) stop("roxygen2 namespace generation failed for ", name)
    # R CMD INSTALL uses the source directory directly, so emulate R CMD build's
    # exclusion of data-raw after generated datasets have been saved.
    raw.data <- file.path(staged.path, "data-raw")
    if (dir.exists(raw.data)) unlink(raw.data, recursive = TRUE)
    status <- run.with.build.phase("BUILD", system2(
      file.path(R.home("bin"), "R"),
      c("CMD", "INSTALL", paste0("--library=", shQuote(library.path)), shQuote(staged.path))
    ))
    if (status != 0L) stop("R CMD INSTALL failed for ", name)
    installed <- as.character(utils::packageVersion(name))
    if (!identical(installed, source.version)) {
      stop("Installed wrong version of local package ", name, ": ", installed,
           " (source is ", source.version, ")")
    }
  }, finally = unlink(staged.path, recursive = TRUE))
}

missing <- names(packages)[!vapply(names(packages), requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Local package installation incomplete: ", paste(missing, collapse = ", "))
if (requireNamespace("rhdf5", quietly = TRUE)) {
  stop("The default Pixi environment unexpectedly installed optional rhdf5.")
}

message("Installed ", length(packages), " VisionEval packages to ", library.path)
})
