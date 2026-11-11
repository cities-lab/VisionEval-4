# Focused base-R regressions for VEModel's normalizePath helper.
#
# Run from the repository root with:
#   Rscript --vanilla sources/framework/VEModel/tests/test_normalize_path.R
# An alternate environment.R path may be passed as the first argument.
# The helper definitions are evaluated from environment.R itself so these
# checks do not duplicate the implementation or require the full test suite.

script_arg <- grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else ""
package_root <- normalizePath(file.path(dirname(script_path), ".."),
                              winslash="/", mustWork=TRUE)
source_file <- commandArgs(trailingOnly=TRUE)
if (!length(source_file)) source_file <- file.path(package_root, "R", "environment.R")
if (!file.exists(source_file[1])) stop("Cannot find VEModel source file: ", source_file[1])

parsed <- parse(source_file[1])
helper_env <- new.env(parent=baseenv())
load_definition <- function(name) {
  candidates <- Filter(function(expr) {
    is.call(expr) && identical(expr[[1]], as.name("<-")) &&
      identical(expr[[2]], as.name(name))
  }, parsed)
  if (length(candidates) != 1L) {
    stop("Expected one definition of ", name, " in ", source_file[1])
  }
  eval(candidates[[1]], envir=helper_env)
}
load_definition("isAbsolutePath")
load_definition("normalizePath")

run_tests <- function() {
assertion_count <- 0L
check_equal <- function(actual, expected, label) {
  assertion_count <<- assertion_count + 1L
  if (!identical(unname(actual), unname(expected))) {
    stop(label, "\n  actual:   ", paste(actual, collapse=" | "),
         "\n  expected: ", paste(expected, collapse=" | "), call.=FALSE)
  }
}
check <- function(condition, label) {
  assertion_count <<- assertion_count + 1L
  if (!isTRUE(condition)) stop(label, call.=FALSE)
}

normalize <- helper_env$normalizePath
root <- tempfile("vemodel-normalize-")
dir.create(root)
on.exit(unlink(root, recursive=TRUE), add=TRUE)
root <- base::normalizePath(root, winslash="/", mustWork=TRUE)
existing <- file.path(root, "existing")
dir.create(existing)

# Existing and missing absolute paths must remain absolute; RootDir must not
# redirect them. Use base R's platform-specific normalization as the oracle.
missing_absolute <- paste0(root, "/missing/child")
absolute_paths <- c(paste0(root, "//existing"), missing_absolute)
expected_absolute <- base::normalizePath(absolute_paths, winslash="/", mustWork=FALSE)
check_equal(normalize(absolute_paths, RootDir=file.path(root, "ignored"),
                      winslash="/", mustWork=FALSE),
            expected_absolute, "Absolute vector paths were changed or prefixed by RootDir")
check(dir.exists(normalize(absolute_paths[1], mustWork=TRUE)),
      "An existing absolute directory no longer resolves")

# A relative path is prefixed exactly once, and repeated interior separators
# and a trailing separator do not change its location.
relative <- paste0("missing//nested/")
expected_relative <- base::normalizePath(
  file.path(root, "missing/nested"), winslash="/", mustWork=FALSE
)
check_equal(normalize(relative, RootDir=root, winslash="/", mustWork=FALSE),
            expected_relative, "Relative path with repeated/trailing separators normalized incorrectly")

# Root-only paths must stay rooted rather than becoming the current directory.
check_equal(normalize("/", winslash="/", mustWork=FALSE),
            base::normalizePath("/", winslash="/", mustWork=FALSE),
            "A root-only path was changed")

# These forms are recognized as absolute by VEModel's existing path predicate.
# On Windows, avoid passing UNC paths to the OS normalizer: resolving an
# unavailable server can cause a network delay even with mustWork=FALSE.
windows_paths <- c("C:/missing/model", "C:\\missing\\model",
                   "//server/share/missing", "\\\\server\\share\\missing")
for (path in windows_paths) {
  check(helper_env$isAbsolutePath(path), paste("Expected absolute path form:", path))
  if (.Platform$OS.type != "windows") {
    check_equal(normalize(path, RootDir=file.path(root, "ignored"),
                          winslash="/", mustWork=FALSE),
                normalize(path, winslash="/", mustWork=FALSE),
                paste("RootDir was added to an absolute drive/UNC form:", path))
  }
}

cat("normalizePath regressions passed (", assertion_count,
    " assertions; source: ", source_file[1], ")\n", sep="")
}

run_tests()
