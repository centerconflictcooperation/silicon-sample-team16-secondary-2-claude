# Silicon Sample Benchmark - method registration form

This registration describes the `secondary-2` Tier-3 entry from `team_16`.

## 0. Approach identity and output

- **0.1 Team:** Nalanda Model Consensus (`team_16`). Rémi Thériault
  (Université du Québec à Rimouski and New York University) and Jay Van Bavel
  (New York University). Contact: `remi.theriault@nyu.edu`.
- **0.2 Summary:** Anthropic Claude Opus 4.6 directly forecast the effect of
  every intervention on all 13 outcomes using two fixed prompt formulations.
  The submitted ATE for each cell is the median of the two prompt forecasts.
- **0.3 Tier and family:** Tier 3; single-model direct-effect forecasting;
  zero-shot structured prompting; prompt-median aggregation.
- **0.4 Pipeline:** extract frozen benchmark materials; create 16 intervention
  jobs; apply two fixed prompts; collect 13 structured numeric ATEs per request;
  median-aggregate prompts; reshape and validate the 208-cell prediction file.
- **0.5 Coverage:** 16 interventions x 13 outcomes = 208 complete ATE forecasts.

## A. Scope of LLM use

The LLM generated numerical forecasts. Deterministic R code constructed jobs,
parsed and checkpointed outputs, aggregated prompts, produced diagnostics, and
wrote the submission. Humans selected the design, prompts, model, and aggregation
rule but did not edit or select individual ATEs.

## B. Model and system details

- **Model:** `anthropic.claude-opus-4-6` (Claude Opus 4.6), served through Vertex
  AI and accessed via the NYU AI Gateway with `nalanda` and `ellmer`.
- **Context:** stateless one-turn API calls on August 23, 2026. No context was
  carried between interventions or prompts; web search and tools were prohibited.
- **Configuration:** temperature 0; one completion per intervention-prompt; seed
  42 recorded where accepted; structured response with 13 numeric fields. Other
  sampling and serving settings used route defaults. Hosted replay is not
  guaranteed and the provider did not expose immutable weight hashes.
- **Customization:** no fine-tuning, retrieval, tools, web search, memory,
  automated prompt optimization, or local inference.
- **Ensemble:** none across models. The two prompt forecasts for each cell were
  combined by their median.

## C. Prompts

Exact templates are in `forecast_pipeline/prompts/`. Both define the estimand as
intervention minus control, provide outcome directions and native scales, stress
the base rate of small effects after a brief exposure, and permit null or negative
effects. Placeholders were filled automatically with archived control,
intervention, and outcome material. No separate team-authored system prompt was
used beyond provider defaults.

## D. Persona construction

Not applicable. This Tier-3 approach did not simulate respondents or personas.

## E. Stimulus and survey administration

Intervention and control texts were extracted from frozen organizer materials
without paraphrasing. Each request presented one intervention, the shared control
material, and all 13 outcome definitions together. The structured response
contained one signed ATE in original outcome units for each outcome.

## F. Stochasticity and aggregation

Each of 16 interventions used two fixed prompts and one completion per prompt,
for 32 completion records. The median of the two prompt-level estimates formed
each submitted cell. Repetition count did not create any cross-model weighting.

## G. Validation and post-processing

Humans reviewed prompt previews, technical smoke tests, completeness, and
content-neutral diagnostics. Failed calls were not imputed. The locked file has
208 unique, numeric, nonmissing cells with required labels. No predictions were
manually repaired, excluded, clipped, calibrated, or shrunk.

## H. Learning and conditioning

No team fine-tuning or retrieval corpus was used. Request context contained only
the benchmark study description, control texts, focal intervention, and outcome
definitions. Proprietary pretraining data are not available to the team.

## I. Data inputs, blinding, and interests

- **Competing interests and funding:** none. No project-specific funding. Model
  API access was provided without charge through NYU institutional infrastructure.
- **External human data:** no human results, pilots, meta-analyses, or calibration
  data informed forecasts.
- **Blinding attestation:** We attest that no member of `team_16` accessed,
  solicited, or was shown any human outcome data from this study, including
  pilots, before prediction lock. Signed: **Rémi Thériault; Jay Van Bavel**.
  Date: **August 24, 2026**.
- **Contamination:** provider training corpora and cutoffs are not fully disclosed;
  the team has no known evidence of training on benchmark outcomes.

## J. Internal selection

This entry holds prompts, inputs, outcome coding, and aggregation fixed relative
to the team's primary consensus while varying the model contributor. Several
routes were tested for technical feasibility and descriptive comparison without
human outcomes. Claude Opus 4.6 was preselected as the Anthropic contributor to
the primary model-family roster and is reported separately here to permit a
controlled single-model comparison.

## K. Reproducibility and frozen artifacts

Code, exact prompts, extracted inputs, archived structured responses, derived
outputs, and the report are deposited in this repository. The run used R 4.5.1,
`nalanda` 0.0.2.2, `ellmer` 0.4.0, `dplyr` 1.2.1, and `readr` 2.2.0. Credentials
are excluded. Scripts 03 and 04 rebuild the prediction and report without model
calls; script 02 defaults to preview mode with calls disabled.

The 32 deposited completion records and their row-level prompt, model, task,
configuration, and call-date provenance are retained in
`forecast_pipeline/outputs/raw/model_responses.csv`. Its size, SHA-256 hash, and
UTC modification time are recorded in `forecast_pipeline/outputs/raw_output_sha256.csv`.

The run required 32 locked completion records. The gateway export reports 112,462
input and 3,890 output tokens for these 32 Claude Opus 4.6 requests.

## L. Disclosure class

Intended Class A (open): method, prompts, code, predictions, and structured model
responses will be public. The gateway export reports a nominal provider cost of
approximately US$0.66 for the 32 model requests. This is an API cost estimate,
not labor or institutional overhead, and was not billed to the team. No material
requires escrow or withholding.
