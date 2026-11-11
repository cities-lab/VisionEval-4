local({
  repo.root <- normalizePath(Sys.getenv("PIXI_PROJECT_ROOT", getwd()), mustWork = TRUE)
  sys.source(file.path(repo.root, "scripts", "stage-visioneval.R"), envir = environment())

  test.root <- tempfile("ve-stage-test-")
  dir.create(test.root)
  on.exit(unlink(test.root, recursive = TRUE), add = TRUE)
  source.path <- file.path(test.root, "source")
  dir.create(file.path(source.path, "R"), recursive = TRUE)
  dir.create(file.path(source.path, "data"), recursive = TRUE)
  dir.create(file.path(source.path, "data-raw", "estimated", "nested"), recursive = TRUE)
  writeLines("Package: Example", file.path(source.path, "DESCRIPTION"))
  writeLines("source", file.path(source.path, "R", "example.R"))
  writeLines("obsolete generated dataset", file.path(source.path, "data", "InitializeSpecifications.rda"))
  writeLines("other stale generated dataset", file.path(source.path, "data", "obsolete.rda"))
  writeLines("intentional estimate", file.path(source.path, "data-raw", "estimated", "Estimate.rda"))
  writeLines("nested intentional estimate", file.path(source.path, "data-raw", "estimated", "nested", "Nested.rda"))

  staged.path <- file.path(test.root, "stage")
  dir.create(file.path(staged.path, "data"), recursive = TRUE)
  writeLines("leftover from prior build", file.path(staged.path, "old-stage-file"))
  writeLines("old generated data", file.path(staged.path, "data", "stale.rda"))
  stageVisionevalPackage(source.path, staged.path)

  stopifnot(
    !file.exists(file.path(staged.path, "old-stage-file")),
    !file.exists(file.path(staged.path, "data", "stale.rda")),
    !file.exists(file.path(staged.path, "data", "InitializeSpecifications.rda")),
    !file.exists(file.path(staged.path, "data", "obsolete.rda")),
    file.exists(file.path(staged.path, "DESCRIPTION")),
    file.exists(file.path(staged.path, "R", "example.R")),
    identical(readLines(file.path(source.path, "data", "InitializeSpecifications.rda")), "obsolete generated dataset"),
    file.exists(file.path(staged.path, "data", "Estimate.rda")),
    file.exists(file.path(staged.path, "data", "nested", "Nested.rda")),
    identical(readLines(file.path(staged.path, "data", "Estimate.rda")), "intentional estimate"),
    identical(readLines(file.path(staged.path, "data", "nested", "Nested.rda")), "nested intentional estimate"),
    file.exists(file.path(source.path, "data-raw", "estimated", "Estimate.rda"))
  )

  # Ordinary packages without a pre-estimated data folder receive an empty
  # generated-data directory even if stale tracked data exists in their source.
  ordinary.source <- file.path(test.root, "ordinary")
  dir.create(file.path(ordinary.source, "data"), recursive = TRUE)
  writeLines("old generated dataset", file.path(ordinary.source, "data", "InitializeSpecifications.rda"))
  ordinary.stage <- file.path(test.root, "ordinary-stage")
  stageVisionevalPackage(ordinary.source, ordinary.stage)
  stopifnot(
    dir.exists(file.path(ordinary.stage, "data")),
    length(list.files(file.path(ordinary.stage, "data"), all.files = TRUE, no.. = TRUE)) == 0L,
    identical(readLines(file.path(ordinary.source, "data", "InitializeSpecifications.rda")), "old generated dataset")
  )

  # Exercise the repository's actual pre-estimated model data without running
  # module estimation or rebuilding packages.
  mm.source <- file.path(repo.root, "sources", "optional", "VETravelDemandMM")
  mm.estimated <- file.path(mm.source, "data-raw", "estimated")
  mm.expected <- sort(list.files(mm.estimated, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  mm.expected <- mm.expected[!dir.exists(file.path(mm.estimated, mm.expected))]
  mm.stage <- file.path(test.root, "VETravelDemandMM")
  stageVisionevalPackage(mm.source, mm.stage)
  mm.staged <- list.files(file.path(mm.stage, "data"), recursive = TRUE, all.files = TRUE, no.. = TRUE)
  mm.staged <- mm.staged[!dir.exists(file.path(mm.stage, "data", mm.staged))]
  stopifnot(
    length(mm.expected) > 0L,
    setequal(mm.expected, mm.staged),
    identical(
      unname(tools::md5sum(file.path(mm.estimated, mm.expected))),
      unname(tools::md5sum(file.path(mm.stage, "data", mm.expected)))
    ),
    !file.exists(file.path(mm.stage, "data", "InitializeSpecifications.rda"))
  )

  cat("Package staging checks passed, including VETravelDemandMM estimated assets.\n")
})
