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

required_packages <- c(
  "dplyr", "readr", "tidyr", "jsonlite", "digest", "rmarkdown", "ggplot2",
  "scales", "nalanda", "ellmer"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
required_files <- c(
  "../metadata.json", "../registration.md", "../codebook.csv",
  "../survey/questionnaire.txt", "../scripts/check.R",
  "config/models.csv", "inputs/tier3_interventions.csv",
  "inputs/tier3_outcomes.csv", "prompts/tier3_direct_forecast_v1.txt",
  "prompts/tier3_direct_forecast_v2.txt",
  "outputs/raw/model_responses.csv", "reports/model_submission_report.Rmd"
)
missing_files <- required_files[!file.exists(required_files)]
cat("Secondary Tier-3 environment check\n----------------------------------\n")
cat("Working directory:", normalizePath(".", winslash = "/"), "\n")
if (length(missing_packages)) {
  cat("Missing R packages:", paste(missing_packages, collapse = ", "), "\n")
}
if (length(missing_files)) {
  cat("Missing files:\n- ", paste(missing_files, collapse = "\n- "), "\n", sep = "")
}
if (length(missing_packages) || length(missing_files)) {
  stop("Environment check incomplete. Resolve the listed items and click Source again.")
}
cat("Environment check complete. No model calls are required to rebuild this entry.\n")

