# Locate the pipeline from this script so the RStudio project can stay at the
# repository root.
.source_files <- vapply(
  sys.frames(),
  function(frame) {
    value <- frame$ofile
    if (is.null(value) || !length(value)) "" else as.character(value[[1]])
  },
  character(1)
)
.source_files <- .source_files[nzchar(.source_files)]
.command_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
if (!length(.source_files) && length(.command_file)) .source_files <- .command_file[[1]]
rm(.command_file)
.script_path <- if (length(.source_files)) {
  normalizePath(tail(.source_files, 1), winslash = "/", mustWork = TRUE)
} else {
  ""
}
rm(.source_files)
if (!nzchar(.script_path) && requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
  .script_path <- rstudioapi::getSourceEditorContext()$path
}
if (nzchar(.script_path)) {
  .pipeline_root <- dirname(dirname(normalizePath(
    .script_path, winslash = "/", mustWork = TRUE
  )))
  if (file.exists(file.path(.pipeline_root, "DECISION_GUIDE_BOOK_TO_SILICON.md"))) {
    setwd(.pipeline_root)
  }
}
rm(.script_path)
if (exists(".pipeline_root", inherits = FALSE)) rm(.pipeline_root)

suppressPackageStartupMessages(library(rmarkdown))

required_files <- c(
  "reports/model_submission_report.Rmd",
  "outputs/derived/forecast_aggregation_long.csv",
  "outputs/diagnostics/prompt_disagreement_by_cell.csv",
  "inputs/tier3_outcomes.csv", "inputs/tier3_interventions.csv",
  "config/models.csv"
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop("Cannot render. Missing files:\n- ", paste(missing_files, collapse = "\n- "))
}

output_path <- rmarkdown::render(
  "reports/model_submission_report.Rmd",
  output_file = "model_submission_report.html",
  output_dir = normalizePath("reports", winslash = "/"),
  envir = new.env(parent = globalenv()),
  quiet = FALSE
)

pages_dir <- file.path(normalizePath("..", winslash = "/"), "docs")
dir.create(pages_dir, recursive = TRUE, showWarnings = FALSE)
pages_path <- file.path(pages_dir, "index.html")
if (!file.copy(output_path, pages_path, overwrite = TRUE)) {
  stop("Report rendered but could not be copied to docs/index.html.")
}
nojekyll <- file.path(pages_dir, ".nojekyll")
if (!file.exists(nojekyll)) file.create(nojekyll)

cat("Report created:", normalizePath(output_path, winslash = "/"), "\n")
cat("GitHub Pages copy:", normalizePath(pages_path, winslash = "/"), "\n")
