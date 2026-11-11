# Run from the repository root:
#   pixi run --locked Rscript --vanilla sources/framework/visioneval/tests/scripts/test_initializer_dispatch.R
# This is a focused metadata/dispatch regression test; it does not run a model.

local({
if (!requireNamespace("visioneval", quietly = TRUE)) {
  stop("Install or load the visioneval framework package before running this test.")
}

source.env <- new.env(parent = asNamespace("visioneval"))
script.arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (!length(script.arg)) stop("Run this regression test with Rscript --vanilla.")
script.path <- normalizePath(sub("^--file=", "", script.arg[[1]]), mustWork = TRUE)
package.root <- normalizePath(file.path(dirname(script.path), "../.."), mustWork = TRUE)
sys.source(file.path(package.root, "R", "initialization.R"), envir = source.env)
selectInitializer <- source.env$selectPackageInitializer

# The package-specific initializer wins when a stale generic dataset is also
# present, provided its exported function exists.
stopifnot(identical(
  selectInitializer(
    "ExamplePkg",
    c("InitializeSpecifications", "InitializeExamplePkgSpecifications"),
    c("Initialize", "InitializeExamplePkg")
  ),
  "InitializeExamplePkg"
))

# Older packages remain supported when the legacy spec/function pair is valid.
stopifnot(identical(
  selectInitializer("LegacyPkg", "InitializeSpecifications", "Initialize"),
  "Initialize"
))

# A declared initializer dataset without its matching exported function should
# fail with a useful diagnostic instead of generating a doomed module call.
orphan.error <- tryCatch(
  selectInitializer("OrphanPkg", "InitializeOrphanPkgSpecifications", character()),
  error = identity
)
stopifnot(inherits(orphan.error, "error"))
stopifnot(grepl("does not export a matching initializer function", conditionMessage(orphan.error), fixed = TRUE))
stopifnot(grepl("OrphanPkg::InitializeOrphanPkg", conditionMessage(orphan.error), fixed = TRUE))

# Packages with no initializer metadata are unchanged.
stopifnot(is.na(selectInitializer("NoInitPkg", "SomeSpecifications", character())))

# Each affected package must pair its package-specific specification dataset
# with the real exported initializer function and keep the specs retrievable.
affected <- c("VEHouseholdTravel", "VESimLandUse", "VETravelPerformance")
for (package in affected) {
  module <- paste0("Initialize", package)
  dataset <- paste0(module, "Specifications")
  package.data <- utils::data(package = package)$results[, "Item"]
  exported.names <- intersect(
    c("Initialize", module), getNamespaceExports(package)
  )
  exported.functions <- exported.names[vapply(exported.names, function(name) {
    is.function(getExportedValue(package, name))
  }, logical(1))]
  selected <- selectInitializer(package, package.data, exported.functions)
  stopifnot(identical(selected, module))
  stopifnot(is.function(getExportedValue(package, selected)))
  stopifnot(is.list(visioneval::getModuleSpecs(selected, package)))
}

# Keep the parser regression independent of whether stale datasets have already
# been removed from the installed packages: inject the legacy metadata row into
# the data(package=...) listing used by parseModuleCalls.
source.env$data <- function(..., package) {
  result <- utils::data(..., package = package)
  if (package %in% affected &&
      !"InitializeSpecifications" %in% result$results[, "Item"]) {
    legacy.row <- matrix(
      c(package, result$results[1, "LibPath"], "InitializeSpecifications", ""),
      nrow = 1L,
      dimnames = list(NULL, colnames(result$results))
    )
    result$results <- rbind(result$results, legacy.row)
  }
  result
}

# Exercise parseModuleCalls itself against each real installed package. The
# resulting initialize entry must name the exported modern function.
module.calls <- data.frame(
  ModuleName = c("CalculateHouseholdDvmt", "AssignCarSvcAvailability", "CalculateRoadPerformance"),
  PackageName = affected,
  RunFor = "AllYears",
  RunYear = "Year",
  Instance = NA_character_,
  LoopIndex = NA_character_,
  stringsAsFactors = FALSE
)
model.env <- visioneval::modelEnvironment(Clear = "")
model.env$ModelState_ls <- list(
  BaseYear = "2020",
  Years = "2020",
  RunParam_ls = list(BaseYear = "2020")
)
parsed.calls <- source.env$parseModuleCalls(module.calls, Save = FALSE)
for (package in affected) {
  module <- paste0("Initialize", package)
  stopifnot(any(vapply(parsed.calls, function(call) {
    identical(call$PackageName, package) && identical(call$ModuleName, module)
  }, logical(1))))
}
already.initialized <- source.env$parseModuleCalls(
  module.calls, AlreadyInitialized = affected, Save = FALSE
)
stopifnot(!any(vapply(already.initialized, function(call) {
  startsWith(call$ModuleName, "Initialize")
}, logical(1))))

# The regenerated household specs make both fuel rows optional. With no input
# files present, optional entries are skipped, while a missing required input
# remains in the processed input list and is reported by input validation.
input.dir <- tempfile("visioneval-initializer-inputs-")
dir.create(input.dir)
on.exit(unlink(input.dir, recursive = TRUE), add = TRUE)
model.env <- visioneval::modelEnvironment(Clear = "")
model.env$ModelState_ls <- list(RunParam_ls = list(InputPath = input.dir))

household.source <- parse(file.path(
  package.root, "..", "..", "modules", "VEHouseholdTravel", "R",
  "InitializeVEHouseholdTravel.R"
))
spec.assignment <- Filter(function(expr) {
  is.call(expr) && identical(expr[[1]], as.name("<-")) &&
    identical(expr[[2]], as.name("InitializeVEHouseholdTravelSpecifications"))
}, as.list(household.source))
stopifnot(length(spec.assignment) == 1L)
household.source.env <- new.env(parent = asNamespace("visioneval"))
eval(spec.assignment[[1]], envir = household.source.env)
household.specs <- household.source.env$InitializeVEHouseholdTravelSpecifications
fuel.specs <- Filter(function(spec) identical(spec$FILE, "model_fuel_co2.csv"), household.specs$Inp)
stopifnot(length(fuel.specs) == 2L)
stopifnot(all(vapply(fuel.specs, function(spec) isTRUE(spec$OPTIONAL), logical(1))))
stopifnot(length(visioneval::doProcessInpSpec(fuel.specs)) == 0L)

required.spec <- list(list(NAME = "RequiredValue", FILE = "required.csv", OPTIONAL = FALSE))
processed.required <- visioneval::doProcessInpSpec(required.spec)
stopifnot(length(processed.required) == 1L)
stopifnot(is.na(processed.required[[1]]$INPUTDIR))
required.result <- visioneval::processModuleInputs(
  list(Inp = processed.required), "RequiredInputFixture", "FixturePkg"
)
stopifnot(any(grepl("Input file error", required.result$Errors, fixed = TRUE)))
stopifnot(any(grepl("required.csv", required.result$Errors, fixed = TRUE)))

cat("Initializer dispatch and optional input checks passed.\n")
})
