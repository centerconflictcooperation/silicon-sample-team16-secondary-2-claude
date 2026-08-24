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
  library(nalanda)
  library(dplyr)
  library(readr)
  library(tidyr)
})

if (utils::packageVersion("nalanda") < numeric_version("0.0.2.2")) {
  stop(
    "This pipeline requires nalanda 0.0.2.2 or later. Install it, restart R, ",
    "and click Source again."
  )
}

# =============================================================================
# USER SETTINGS -- edit only these three settings, then click Source in RStudio
# =============================================================================
# Select model IDs from config/models.csv. The CSV is a roster; you do not need
# to edit it. For a cost-gated run, select exactly one new model at a time.
# Available IDs:
# - gemini-3.1-pro-preview
# - gemini-2.5-pro
# - claude-opus-4-6
# - claude-haiku-4-5
# - gpt-5-mini
# - gpt-4o-mini
# - gpt-oss-120b
# - gemini-2.5-flash-lite
# - gemini-3.1-flash-lite
active_model_ids <- c("claude-opus-4-6")

# "preview" = inspect prompts and call counts without contacting any model
# "smoke"   = run one intervention through every selected model and prompt
# "full"    = run all interventions through every selected model and prompt
run_mode <- "preview"

# Paid calls are blocked unless this is deliberately changed to TRUE.
confirm_model_calls <- FALSE
# =============================================================================

allowed_run_modes <- c("preview", "smoke", "full")
if (
  !is.character(run_mode) ||
    length(run_mode) != 1L ||
    !run_mode %in% allowed_run_modes
) {
  stop(
    "`run_mode` must be exactly one of: ",
    paste(allowed_run_modes, collapse = ", "),
    "."
  )
}

required_inputs <- c(
  "inputs/tier3_interventions.csv",
  "inputs/tier3_outcomes.csv",
  "inputs/control_text_for_prompt.txt",
  "inputs/outcome_definitions_for_prompt.txt",
  "config/models.csv"
)

if (any(!file.exists(required_inputs))) {
  stop("Run scripts/01_prepare_inputs.R before this script.")
}

prompt_files <- sort(list.files(
  "prompts",
  pattern = "^tier3_direct_forecast_v[0-9]+\\.txt$",
  full.names = TRUE
))
if (!length(prompt_files)) {
  stop("No Tier-3 prompt variants found.")
}

prompt_variants <- setNames(
  lapply(
    prompt_files,
    function(path) {
      paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    }
  ) |>
    unlist(use.names = FALSE),
  tools::file_path_sans_ext(basename(prompt_files))
)

model_config <- read_csv("config/models.csv", show_col_types = FALSE)
if (
  !is.character(active_model_ids) ||
    !length(active_model_ids) ||
    anyNA(active_model_ids) ||
    any(!nzchar(active_model_ids)) ||
    anyDuplicated(active_model_ids)
) {
  stop("`active_model_ids` must contain one or more unique model IDs.")
}
unknown_model_ids <- setdiff(active_model_ids, model_config$model_id)
if (length(unknown_model_ids)) {
  stop(
    "Unknown `active_model_ids`: ",
    paste(unknown_model_ids, collapse = ", "),
    ". Choose IDs listed in config/models.csv."
  )
}
model_config <- model_config |>
  mutate(active = model_id %in% active_model_ids)

interventions <- read_csv(
  "inputs/tier3_interventions.csv",
  show_col_types = FALSE
)
outcomes <- read_csv("inputs/tier3_outcomes.csv", show_col_types = FALSE)
control_text <- paste(
  readLines(
    "inputs/control_text_for_prompt.txt",
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
outcome_definitions <- paste(
  readLines(
    "inputs/outcome_definitions_for_prompt.txt",
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)

jobs <- interventions |>
  mutate(
    control_text = control_text,
    outcome_definitions = outcome_definitions
  )

response_fields <- setNames(
  replicate(nrow(outcomes), ellmer::type_number(), simplify = FALSE),
  outcomes$outcome
)
response_type <- do.call(ellmer::type_object, response_fields)

smoke_n <- if (run_mode == "smoke") 1L else NULL
master_results_path <- "outputs/raw/full_prompt_grid_results.csv"
checkpoint_dir <- file.path(
  "outputs/checkpoints",
  if (run_mode == "smoke") "smoke" else "full"
)

# Smoke tests use their own checkpoints but never treat the completed full run
# as a substitute. Full runs and previews reuse the canonical master plus every
# compatible checkpoint, including models inactive in the current phase.
prior_results <- NULL
trust_legacy_results <- FALSE
if (run_mode != "smoke" && file.exists(master_results_path)) {
  master_columns <- names(read_csv(
    master_results_path,
    n_max = 0,
    show_col_types = FALSE
  ))
  trust_legacy_results <- !all(c("task_hash", "input_row") %in% master_columns)
  # The canonical master contains every finalized phase. Passing it directly
  # avoids metadata conflicts with duplicate checkpoint rows; resume still
  # recovers genuinely pending active checkpoints during the real run.
  prior_results <- master_results_path
} else if (run_mode != "smoke" && dir.exists(checkpoint_dir)) {
  prior_results <- collect_prompt_grid_results(checkpoint_dir)
}

# Nalanda's dry run uses the same strong task identities as the real run, so
# the displayed cost is the number of pending responses, not the configured
# total before completed work is subtracted.
plan <- run_prompt_grid(
  data = jobs,
  content_col = "intervention_text",
  prompt_variants = prompt_variants,
  response_type = response_type,
  model_config = model_config,
  id_col = "condition",
  smoke_n = smoke_n,
  dry_run = TRUE,
  existing_results = prior_results,
  trust_legacy_results = trust_legacy_results,
  base_url = "https://ai-gateway.apps.cloud.rt.nyu.edu/v1/",
  excerpt_chars = 50000,
  max_active = 4,
  rpm = 60
)
pending_calls <- attr(plan, "total_pending_calls")

cat("Silicon Benchmark forecast plan\n")
cat("-------------------------------\n")
cat("Run mode:", run_mode, "\n")
if (!is.null(prior_results)) {
  cat(
    "Compatible prior results and checkpoints will be reused when found.\n"
  )
}
if (trust_legacy_results) {
  cat("The existing master will be migrated once to strong task hashes.\n")
}
print(plan)
cat(
  "Pending model responses:",
  pending_calls,
  "\n"
)

make_prompt_preview <- function(template, data_row) {
  out <- template
  for (field in c(
    "condition",
    "intervention_text",
    "control_text",
    "outcome_definitions"
  )) {
    out <- gsub(
      paste0("{", field, "}"),
      data_row[[field]][[1L]],
      out,
      fixed = TRUE
    )
  }
  out
}

cat("\nFirst concrete prompt preview:\n")
cat("--------------------------------\n")
cat(make_prompt_preview(prompt_variants[[1L]], jobs[1, , drop = FALSE]), "\n")

if (run_mode == "preview") {
  cat(
    "\nPreview only: no model calls were made.\n",
    "To continue, edit USER SETTINGS at the top of this file and click ",
    "Source in RStudio.\n"
  )
} else if (pending_calls > 0L && !isTRUE(confirm_model_calls)) {
  cat(
    "\nPlan only: model calls remain blocked. Review the pending responses ",
    "above, then set `confirm_model_calls <- TRUE` and click Source again ",
    "only when you are ready.\n"
  )
} else {
  options(
    nalanda.base_url = "https://ai-gateway.apps.cloud.rt.nyu.edu/v1/",
    ellmer_timeout_s = 600,
    ellmer_max_tries = 3
  )

  dir.create("outputs/raw", recursive = TRUE, showWarnings = FALSE)
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)

  workflow <- run_prompt_grid(
    data = jobs,
    content_col = "intervention_text",
    prompt_variants = prompt_variants,
    response_type = response_type,
    model_config = model_config,
    id_col = "condition",
    smoke_n = smoke_n,
    dry_run = FALSE,
    output_dir = checkpoint_dir,
    existing_results = prior_results,
    trust_legacy_results = trust_legacy_results,
    resume = TRUE,
    on_error = "continue",
    progress = TRUE,
    base_url = "https://ai-gateway.apps.cloud.rt.nyu.edu/v1/",
    excerpt_chars = 50000,
    max_active = 4,
    rpm = 60
  )

  raw_results <- workflow$results
  if (!"call_date" %in% names(raw_results)) {
    raw_results$call_date <- NA_character_
  }
  raw_results <- raw_results |>
    mutate(
      call_date = coalesce(as.character(call_date), as.character(Sys.Date()))
    )

  output_stem <- if (run_mode == "full") {
    "full_prompt_grid"
  } else {
    "smoke_prompt_grid"
  }
  results_csv <- file.path(
    "outputs/raw",
    paste0(output_stem, "_results.csv")
  )
  results_rds <- file.path(
    "outputs/raw",
    paste0(output_stem, "_results.rds")
  )

  write_csv(
    raw_results,
    results_csv
  )
  saveRDS(
    raw_results,
    results_rds
  )
  saveRDS(
    workflow,
    file.path("outputs/raw", paste0(output_stem, "_bundle.rds"))
  )
  write_csv(
    workflow$plan,
    file.path("outputs/raw", paste0(output_stem, "_plan.csv"))
  )
  write_csv(
    workflow$tasks,
    file.path("outputs/raw", paste0(output_stem, "_tasks.csv"))
  )
  write_csv(
    workflow$errors,
    file.path("outputs/raw", paste0(output_stem, "_errors.csv"))
  )

  if (nrow(workflow$errors)) {
    stop(
      nrow(workflow$errors),
      " workflow unit(s) failed. Successful units were checkpointed. ",
      "Review the saved error file and click Source again to resume safely."
    )
  }

  cat(
    "\nCompleted successfully. Raw combined results, plan, task log, and ",
    "checkpoints are saved under outputs/.\n"
  )
}
