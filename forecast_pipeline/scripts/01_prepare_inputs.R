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
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

dir.create("inputs", recursive = TRUE, showWarnings = FALSE)

questionnaire_path <- "../survey/questionnaire.txt"
codebook_path <- "../codebook.csv"

if (!file.exists(questionnaire_path) || !file.exists(codebook_path)) {
  stop("The repository survey/questionnaire.txt or codebook.csv file is missing.")
}

questionnaire <- readLines(questionnaire_path, warn = FALSE, encoding = "UTF-8")

intervention_names <- c(
  "Corporate reliance",
  "Social justice",
  "Interview Prof. Maraun",
  "Funding",
  "Oil industry misinformation",
  "Measurement & modeling (1)",
  "Former skeptics",
  "High public trust",
  "Measurement & modeling (2)",
  "Peer-review",
  "Scientist community helpers",
  "Consensus",
  "Portrait Prof. Cherry",
  "Model accuracy",
  "Interview Prof. Sebille",
  "Extreme weather predictions"
)

intervention_starts <- match(paste0("### ", intervention_names), questionnaire)
post_treatment_start <- match(
  "POST-TREATMENT OUTCOMES  (measured AFTER the condition)",
  questionnaire
)

if (anyNA(intervention_starts) || is.na(post_treatment_start)) {
  stop("Could not find the authoritative intervention sections in questionnaire.txt.")
}

extract_section <- function(start, end) {
  lines <- questionnaire[(start + 1L):end]
  str_trim(paste(lines, collapse = "\n"))
}

intervention_ends <- c(intervention_starts[-1L] - 1L, post_treatment_start - 2L)

interventions <- tibble(
  condition = intervention_names,
  intervention_text = purrr::map2_chr(
    intervention_starts,
    intervention_ends,
    extract_section
  ),
  presentation_note = if_else(
    condition == "Extreme weather predictions",
    paste(
      "State-adaptive arm. The source section contains the state-to-case mapping",
      "and all possible texts so an effect-level forecaster can average over the",
      "target population; a participant would see only one applicable version."
    ),
    "Verbatim condition section from questionnaire.txt"
  )
)

control_starts <- grep(
  "^### control .* filler text [123] of 3:",
  questionnaire
)

if (length(control_starts) != 3L) {
  stop("Could not find all three control filler texts.")
}

control_ends <- c(control_starts[-1L] - 1L, intervention_starts[[1L]] - 1L)
control_texts <- tibble(
  control_version = c("neckties", "baseball", "dances"),
  control_text = purrr::map2_chr(control_starts, control_ends, extract_section)
)

control_for_prompt <- paste(
  paste0(
    "CONTROL VERSION ", seq_len(nrow(control_texts)), " (",
    control_texts$control_version, "):\n", control_texts$control_text
  ),
  collapse = "\n\n"
)

outcome_names <- c(
  "behavior_mean",
  "belief_post",
  "concern_mean",
  "distrust_post",
  "donation_ams",
  "funding_perceptions",
  "inst_trust_mean",
  "newsletter_signup",
  "policy_general",
  "policy_role_mean",
  "policy_specific_mean",
  "trust_multidimensional",
  "trust_post"
)

codebook <- read_csv(codebook_path, show_col_types = FALSE)
missing_codebook_outcomes <- setdiff(outcome_names, unique(codebook$target_label))
if (length(missing_codebook_outcomes)) {
  stop(
    "Outcomes missing from the official codebook: ",
    paste(missing_codebook_outcomes, collapse = ", ")
  )
}

# Concise forecasting definitions are manually composed from the official
# codebook so reverse-coding and composite direction remain unambiguous.
outcomes <- tribble(
  ~outcome, ~native_min, ~native_max, ~definition, ~response_scale,
  "behavior_mean", 0, 100,
  "Mean intended likelihood of eating less meat, using lower-carbon transport, installing solar, flying less, discussing climate change, and donating to an environmental NGO.",
  "0 = not likely at all; 100 = extremely likely; higher means stronger pro-climate behavioral intentions.",
  "belief_post", 0, 100,
  "Perceived accuracy of the statement: Human activities are causing climate change.",
  "0 = not at all accurate; 100 = extremely accurate.",
  "concern_mean", 0, 100,
  "Mean climate-change concern, perceived seriousness, and importance relative to other U.S. issues.",
  "0 = low concern/seriousness/importance; 100 = high concern/seriousness/importance.",
  "distrust_post", 0, 100,
  "How much the respondent distrusts climate scientists.",
  "0 = not at all; 100 = very strongly; higher means more distrust.",
  "donation_ams", 0, 10,
  "Dollars donated from a $10 bonus to the American Meteorological Society.",
  "$0 to $10.",
  "funding_perceptions", 0, 100,
  "Reverse-coded perception of federal spending on climate-change research.",
  "0 = perceives far too much funding; 50 = about right; 100 = perceives far too little funding. Higher means stronger perceived need for more funding.",
  "inst_trust_mean", 0, 100,
  "Mean trust in the EPA, NASA, NOAA, universities and colleges, and the federal government.",
  "0 = not at all; 100 = very strongly.",
  "newsletter_signup", 0, 1,
  "Proportion subscribing to the Talking Climate newsletter.",
  "0 = no signup; 1 = signup. The ATE is a probability difference.",
  "policy_general", 0, 100,
  "Support for the U.S. government doing more to reduce global warming.",
  "0 = strongly oppose; 100 = strongly support.",
  "policy_role_mean", 0, 100,
  "Mean agreement that climate scientists should communicate with policymakers, work with them, advocate for policies, and be involved in policymaking.",
  "0 = strongly disagree; 100 = strongly agree.",
  "policy_specific_mean", 0, 100,
  "Mean support for seven specific mitigation policies covering fossil-fuel taxes, public transport, sustainable energy, land protection, carbon-intensive food taxes, green jobs, and clean waterways.",
  "0 = strongly oppose; 100 = strongly support.",
  "trust_multidimensional", 0, 100,
  "Primary outcome: mean of climate-scientist competence, integrity, benevolence, and openness subscales.",
  "0 = very low multidimensional trust; 100 = very high multidimensional trust.",
  "trust_post", 0, 100,
  "How much the respondent trusts climate scientists.",
  "0 = not at all; 100 = very strongly."
)

if (!identical(outcomes$outcome, outcome_names)) {
  stop("Internal outcome ordering does not match the official Tier-3 ordering.")
}

outcome_definitions <- outcomes |>
  mutate(
    prompt_line = paste0(
      "- ", outcome, " [", native_min, " to ", native_max, "]: ",
      definition, ". Scale/details: ", response_scale
    )
  ) |>
  pull(prompt_line) |>
  paste(collapse = "\n")

write_csv(interventions, "inputs/tier3_interventions.csv")
write_csv(control_texts, "inputs/tier3_control_texts.csv")
write_csv(outcomes, "inputs/tier3_outcomes.csv")
writeLines(control_for_prompt, "inputs/control_text_for_prompt.txt", useBytes = TRUE)
writeLines(outcome_definitions, "inputs/outcome_definitions_for_prompt.txt", useBytes = TRUE)

cat("Prepared authoritative Tier-3 inputs:\n")
cat("-", nrow(interventions), "interventions\n")
cat("-", nrow(control_texts), "control texts\n")
cat("-", nrow(outcomes), "outcomes\n")
