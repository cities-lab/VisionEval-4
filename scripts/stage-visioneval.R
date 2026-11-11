# Copy a local VisionEval package to a disposable build directory. Generated
# package data is rebuilt from source during roxygenisation, so tracked data/
# files are intentionally excluded. A small number of modules carry intentional
# pre-estimated datasets under data-raw/estimated; preserve those in data/.
stageVisionevalPackage <- function(source.path, staged.path) {
  source.path <- normalizePath(source.path, mustWork = TRUE)
  if (dir.exists(staged.path) || file.exists(staged.path)) {
    unlink(staged.path, recursive = TRUE)
  }
  if (!dir.create(staged.path, recursive = TRUE, showWarnings = FALSE)) {
    stop("Could not create staging directory: ", staged.path)
  }

  files <- list.files(
    source.path, recursive = TRUE, all.files = TRUE, full.names = TRUE,
    include.dirs = TRUE, no.. = TRUE
  )
  relative.paths <- substring(files, nchar(source.path) + 2L)
  relative.normalized <- gsub("\\\\", "/", relative.paths)
  keep <- !(relative.normalized == "data" | startsWith(relative.normalized, "data/"))
  files <- files[keep]
  relative.paths <- relative.paths[keep]

  for (i in seq_along(files)) {
    target.path <- file.path(staged.path, relative.paths[i])
    if (isTRUE(file.info(files[i])$isdir)) {
      dir.create(target.path, recursive = TRUE, showWarnings = FALSE)
    } else {
      dir.create(dirname(target.path), recursive = TRUE, showWarnings = FALSE)
      if (!file.copy(files[i], target.path, overwrite = TRUE)) {
        stop("Could not stage source file ", files[i])
      }
    }
  }

  data.path <- file.path(staged.path, "data")
  dir.create(data.path, showWarnings = FALSE)
  estimated.path <- file.path(source.path, "data-raw", "estimated")
  if (dir.exists(estimated.path)) {
    estimated.files <- list.files(
      estimated.path, recursive = TRUE, all.files = TRUE, full.names = TRUE,
      include.dirs = TRUE, no.. = TRUE
    )
    estimated.relative <- substring(estimated.files, nchar(estimated.path) + 2L)
    for (i in seq_along(estimated.files)) {
      target.path <- file.path(data.path, estimated.relative[i])
      if (isTRUE(file.info(estimated.files[i])$isdir)) {
        dir.create(target.path, recursive = TRUE, showWarnings = FALSE)
      } else {
        dir.create(dirname(target.path), recursive = TRUE, showWarnings = FALSE)
        if (!file.copy(estimated.files[i], target.path, overwrite = TRUE)) {
          stop("Could not stage estimated data file ", estimated.files[i])
        }
      }
    }
  }

  invisible(staged.path)
}
