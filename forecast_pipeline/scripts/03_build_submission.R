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

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(jsonlite)
})

metadata <- jsonlite::read_json("../metadata.json", simplifyVector = TRUE)
model_config <- read_csv("config/models.csv", show_col_types = FALSE)
outcomes <- read_csv("inputs/tier3_outcomes.csv", show_col_types = FALSE)

if (nrow(model_config) != 1L) {
  stop("A single-model secondary entry requires exactly one config/models.csv row.")
}
model_id <- model_config$model_id[[1]]
entry <- metadata$entry
expected_prediction <- file.path(
  "..", "predictions", paste0("team_16_T3_", entry, "_v1.csv")
)

raw_path <- if (file.exists("outputs/raw/full_prompt_grid_results.csv")) {
  "outputs/raw/full_prompt_grid_results.csv"
} else {
  "outputs/raw/model_responses.csv"
}
raw <- read_csv(raw_path, show_col_types = FALSE) |>
  filter(model_id == .env$model_id)

if (!nrow(raw)) {
  stop("No archived responses were found for ", model_id, ".")
}
missing_outcomes <- setdiff(outcomes$outcome, names(raw))
if (length(missing_outcomes)) {
  stop("Archived responses lack outcomes: ", paste(missing_outcomes, collapse = ", "))
}

forecast_long <- raw |>
  select(condition, model_id, family, prompt_id, completion, all_of(outcomes$outcome)) |>
  pivot_longer(
    cols = all_of(outcomes$outcome),
    names_to = "outcome",
    values_to = "estimate"
  )

prompt_level <- forecast_long |>
  group_by(condition, model_id, family, prompt_id, outcome) |>
  summarize(
    estimate = median(estimate),
    n_completions = n(),
    .groups = "drop"
  )

model_level <- prompt_level |>
  group_by(condition, model_id, family, outcome) |>
  summarize(
    estimate = median(estimate),
    n_prompts = n(),
    .groups = "drop"
  )

candidate <- model_level |>
  transmute(condition, outcome, ate = estimate) |>
  arrange(condition, outcome)

stopifnot(
  nrow(candidate) == 208L,
  dplyr::n_distinct(candidate$condition) == 16L,
  dplyr::n_distinct(candidate$outcome) == 13L,
  !anyNA(candidate$ate)
)

stages <- bind_rows(
  prompt_level |>
    transmute(
      aggregation_level = "prompt", condition, prompt_id, model_id, family,
      n_contributors = n_completions, outcome, estimate
    ),
  model_level |>
    transmute(
      aggregation_level = "model", condition, prompt_id = NA_character_,
      model_id, family, n_contributors = n_prompts, outcome, estimate
    )
)
write_csv(stages, "outputs/derived/forecast_aggregation_long.csv")
write_csv(
  candidate,
  file.path("outputs/derived", paste0("team_16_T3_", entry, "_v1.csv"))
)

prompt_disagreement <- prompt_level |>
  left_join(
    transmute(outcomes, outcome, scale_width = native_max - native_min),
    by = "outcome"
  ) |>
  group_by(condition, outcome) |>
  summarize(
    n_prompts = n(),
    prompt_min = min(estimate),
    prompt_max = max(estimate),
    prompt_range = prompt_max - prompt_min,
    prompt_range_fraction = prompt_range / first(scale_width),
    .groups = "drop"
  )
write_csv(
  prompt_disagreement,
  "outputs/diagnostics/prompt_disagreement_by_cell.csv"
)

if (!file.exists(expected_prediction)) {
  stop("Missing locked prediction: ", expected_prediction)
}
locked <- read_csv(expected_prediction, show_col_types = FALSE) |>
  arrange(condition, outcome)
same_values <- isTRUE(all.equal(candidate, locked, tolerance = 1e-12,
                                check.attributes = FALSE))
if (!same_values) {
  stop("Rebuilt forecasts differ from the locked repository prediction.")
}

cat("Rebuilt and verified", nrow(candidate), "locked cells for", model_id, ".\n")
cat("No model calls were made. Raw source:", raw_path, "\n")
