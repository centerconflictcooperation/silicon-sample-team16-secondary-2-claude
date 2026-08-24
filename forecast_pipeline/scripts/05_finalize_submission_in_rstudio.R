# Locate the pipeline from this script so the RStudio project can stay at the
# repository root. This works with Source and with Run All in RStudio.
.source_files <- vapply(
  sys.frames(),
  function(frame) {
    value <- frame$ofile
    if (is.null(value) || !length(value)) "" else as.character(value[[1]])
  },
  character(1)
)
.source_files <- .source_files[nzchar(.source_files)]
.script_path <- if (length(.source_files)) {
  normalizePath(tail(.source_files, 1), winslash = "/", mustWork = TRUE)
} else {
  ""
}
rm(.source_files)
if (
  !nzchar(.script_path) &&
    requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()
) {
  .script_path <- rstudioapi::getSourceEditorContext()$path
}
if (nzchar(.script_path)) {
  .pipeline_root <- dirname(dirname(normalizePath(
    .script_path,
    winslash = "/",
    mustWork = TRUE
  )))
  if (
    file.exists(file.path(.pipeline_root, "DECISION_GUIDE_BOOK_TO_SILICON.md"))
  ) {
    setwd(.pipeline_root)
  }
}
rm(.script_path)
if (exists(".pipeline_root", inherits = FALSE)) {
  rm(.pipeline_root)
}

# =============================================================================
# USER SETTING -- change to TRUE only after reading the checks below
# =============================================================================
confirm_finalize <- TRUE
# =============================================================================

if (!isTRUE(confirm_finalize)) {
  stop(
    "Finalization is locked. Complete metadata.json and registration.md, ",
    "remove the template examples, then set `confirm_finalize <- TRUE` and ",
    "click Source again."
  )
}

source_path <- ""
if (
  requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()
) {
  source_path <- tryCatch(
    rstudioapi::getSourceEditorContext()$path,
    error = function(e) ""
  )
}

source_dir <- if (nzchar(source_path)) dirname(source_path) else getwd()
root_candidates <- unique(normalizePath(
  c(
    getwd(),
    source_dir,
    dirname(source_dir),
    dirname(dirname(source_dir))
  ),
  winslash = "/",
  mustWork = FALSE
))
is_repo_root <- vapply(
  root_candidates,
  function(x) {
    file.exists(file.path(x, "metadata.json")) &&
      file.exists(file.path(x, "registration.md")) &&
      file.exists(file.path(x, "scripts", "manifest.R"))
  },
  logical(1)
)

if (!any(is_repo_root)) {
  stop("Could not locate the submission repository root.")
}
repo_root <- root_candidates[which(is_repo_root)[1]]

human_files <- file.path(repo_root, c("metadata.json", "registration.md"))
human_text <- paste(
  vapply(
    human_files,
    function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
    character(1)
  ),
  collapse = "\n"
)
if (grepl("\\[TODO|REPLACE_WITH_", human_text)) {
  stop(
    "Human-only fields remain in metadata.json or registration.md. Search ",
    "for `[TODO` and `REPLACE_WITH_`, complete them, and click Source again."
  )
}

example_predictions <- list.files(
  file.path(repo_root, "predictions"),
  pattern = "^example_.*\\.csv$",
  full.names = TRUE
)
example_raw <- file.path(
  repo_root,
  "raw_data_deposit",
  "example_raw_export.csv"
)
if (length(example_predictions) || file.exists(example_raw)) {
  stop(
    "Template examples remain. Delete every example_*.csv from predictions/ ",
    "and raw_data_deposit/example_raw_export.csv, then click Source again."
  )
}

rscript <- file.path(
  R.home("bin"),
  if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
)
if (!file.exists(rscript)) {
  stop("Could not locate Rscript inside the current R installation.")
}

run_official_helper <- function(script_name) {
  script_path <- file.path(repo_root, "scripts", script_name)
  if (!file.exists(script_path)) {
    stop("Missing organizers' helper: ", script_path)
  }

  old_dir <- setwd(repo_root)
  on.exit(setwd(old_dir), add = TRUE)
  output <- system2(
    command = rscript,
    args = shQuote(script_path),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }

  cat("\n", paste(output, collapse = "\n"), "\n", sep = "")
  if (!identical(as.integer(status), 0L)) {
    stop("The organizers' `", script_name, "` helper reported a failure.")
  }
  invisible(output)
}

cat("Submission repository:\n", repo_root, "\n", sep = "")
run_official_helper("manifest.R")
run_official_helper("zenodo_citation.R")
run_official_helper("check.R")

cat(
  "\nFinalization completed without a failing check.\n",
  "Review metadata.json, .zenodo.json, and metadata_check_report.txt before ",
  "committing or creating a release.\n",
  sep = ""
)
