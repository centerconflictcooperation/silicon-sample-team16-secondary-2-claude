# From the book model-consensus project to the Silicon Sample Benchmark

## Purpose

This is a plain-language record of the decisions required to adapt our earlier
book-ranking approach to a valid Silicon Sample Benchmark Tier-3 submission.
It distinguishes decisions already made, provisional recommendations, and
questions that still need a quick team decision.

## Bottom line

The book project and the benchmark are not asking the same question.

- **Book project:** simulate partisan readers, estimate pre/post change on one
  outcome, and use several models mainly to rank books and chapters.
- **Tier-3 benchmark:** provide 208 numeric forecasts of actual human effect
  sizes: 16 interventions x 13 outcomes, each relative to control.

The most realistic adaptation is therefore:

1. keep the multi-model consensus principle;
2. change from simulated individual readers to direct effect forecasting;
3. have every model forecast all 13 ATEs in their original units;
4. combine models using a robust, equal-weight rule;
5. submit one consensus entry as the primary submission;
6. retain every model's predictions internally for later comparison, without
   trying to register seven separate benchmark entries.

## Decision summary

| Question | Current recommendation | Status |
|---|---|---|
| Submission tier | Tier 3 only | Decided |
| Primary strategy | Multi-model consensus of direct ATE forecasts | Provisional |
| Number of formal entries | One primary; add secondary entries only if nearly costless | Provisional |
| Number of models inside the consensus | One predeclared representative from each developer family: Google, Anthropic, and OpenAI | Recommended |
| Repeats per model | One per prompt for controllable low-temperature models; five per prompt for fixed-sampling GPT-5-mini | Recommended MVP |
| Aggregation | Equal weight per model; aggregate within model first, then median across models | Provisional |
| Standardize model predictions? | No | Recommended |
| Universal `0.56` correction? | No—not for the primary entry | Recommended |
| Demographic profiles | Not required for Tier 3 | Decided |
| Conversation structure | Stateless direct forecast, one call per intervention returning all 13 outcomes | Provisional |
| Manual adjustment of predictions | None | Decided |

## 1. How many strategies or entries are allowed?

### What the benchmark permits

The benchmark defines one **entry** as one method's complete prediction set at
one tier. Every entry requires its own repository, registration form, Zenodo
deposit, and DOI.

A team may submit at most **three entries per tier** to the main analyses. The
team must designate exactly one entry across all tiers as `primary`. The
template explicitly says that entries can be genuinely different approaches or
structured variations of one approach.

Consequences for us:

- A six-model consensus is **one entry** because the ensemble and its fixed
  aggregation rule jointly constitute one method.
- An individual Gemini prediction set is another entry.
- An individual Claude prediction set is another entry.
- Six individual models plus one consensus would be seven entries, not one.
  That exceeds the ordinary Tier-3 cap. We could ask for an exception, but only
  three entries per tier would enter the main analyses, and seven separate
  repositories/deposits are incompatible with the time constraint.

### Recommended decision

Keep all model-level predictions and logs internally, but formally submit:

1. **Primary:** model consensus.
2. **Optional secondary 1:** one preselected individual model.
3. **Optional secondary 2:** either a second preselected model or a clearly
   different calibration/elicitation variant.

Under the current deadline pressure, one primary consensus entry is enough.
Secondary entries should be added only if generating, documenting, validating,
and depositing them is almost automatic by August 27.

If we do use all three available Tier-3 slots, the cleanest comparison is:

1. **Primary:** equal-weight multi-model consensus.
2. **Secondary 1:** the strongest technically reliable Google model available
   through the gateway (provisionally Gemini 3.1 Pro Preview, with Gemini 2.5
   Pro as the fallback if the preview route is unreliable).
3. **Secondary 2:** the strongest technically reliable Anthropic model
   available through the gateway (currently expected to be Claude Opus 4.6,
   subject to the identical smoke test).

This gives the benchmark one ensemble and two interpretable single-model
baselines from different model families. “Strongest” here means selected in
advance from general capability and gateway reliability—not whichever model
happens to agree most with the benchmark consensus.

### Which models belong in the consensus?

Do **not** include every route in the gateway list. The list contains many
versions and capability tiers from the same developers. A flat median across
all of them would give Google and Anthropic several correlated votes while
OpenAI receives far fewer. It would also let older, cheaper variants dilute the
forecast of the strongest representative from their family.

Use one model per **developer family**, selected before viewing benchmark
outcomes by this fixed rule:

1. general-purpose text-generation models only (no embedding models);
2. highest-capability available model from that developer;
3. prefer a stable route, but permit a preview model if it is the documented
   top reasoning model and the complete smoke test is reliable;
4. require the same schema, safety, and completeness smoke test;
5. use a named fallback from the same family if the preferred model fails.

The provisional family-balanced roster is:

| Developer family | Preferred model | Fallback | Rationale |
|---|---|---|---|
| Google | `gemini-3.1-pro-preview` | `gemini-2.5-pro` | Pro-tier reasoning model rather than adding several Flash/Lite variants |
| Anthropic | `anthropic.claude-opus-4-6` | `anthropic.claude-sonnet-4-6` | Highest available Claude tier in the supplied gateway list |
| OpenAI | `@gpt-5-mini/gpt-5-mini` | `gpt-oss-120b-maas`, only if technically necessary | Strongest available GPT route; the open-weight model is not a fourth family vote |

This is a **three-family consensus**, not a claim that the three models have
identical capability or sampling behavior. Every family contributes exactly
one model-level ATE to the final median. The unused routes can be retained for
post-submission diagnostics but should not enter the locked primary forecast.

### Cost-gated execution order

Do not begin by activating the three preferred models together. Validate the
entire workflow using only `gemini-2.5-flash-lite`:

1. set `run_mode <- "smoke"` in the R script and Source it for one
   intervention across both prompts (two model calls);
2. verify the structured 13-outcome schema and saved raw files;
3. run the complete 16-intervention Flash-Lite validation only if the smoke
   test succeeds (32 calls in total);
4. inspect completeness and build a provisional 208-cell Tier-3 file;
5. only then activate each expensive preferred model for its own two-call smoke
   test before any complete run.

Flash-Lite is a pipeline-validation model, not an additional Google vote in the
locked three-family consensus.

Nalanda now implements the execution grid natively. `run_prompt_grid()` supplies
no-cost pending-call previews, model-specific repetitions, strong task
identities, checkpoints, resume, phased result reuse, provenance, and
continue-on-error execution. `collect_prompt_grid_results()` safely combines
compatible checkpoints across cost-gated phases. `aggregate_model_forecasts()`
implements both the primary robust median hierarchy and the arithmetic-mean
sensitivity hierarchy while preserving equal family weight.

### How to choose any individual-model entries

Choose them before inspecting the complete benchmark predictions. Acceptable
criteria include:

- distinct model families;
- known technical reliability through the NYU gateway;
- successful completion of the same one-intervention smoke test;
- ability to follow the fixed output schema without manual repair;
- relevance to the earlier book project.

Do not select an individual entry because it agrees most closely with the
consensus on these benchmark predictions. That would make the comparison less
informative and introduce an avoidable researcher degree of freedom.

## 2. How should model predictions become effect sizes?

### Why the old ranking solution is insufficient

In the book project, model-specific scale differences mattered less because the
main goal was ranking. For Tier 3, the benchmark also scores Pearson
correlation, RMSE, and calibration. The numerical size of each ATE therefore
matters directly.

### Candidate approaches

#### A. Arithmetic mean of raw model ATEs

Simple, but a model that produces extremely large effects can pull the entire
ensemble toward its scale.

#### B. Median of raw model ATEs

Robust to one or two exaggerated models, preserves original units, and requires
few assumptions. This is the current recommendation.

The aggregation should be hierarchical:

1. combine prompt variants or repeated runs **within each model**;
2. produce one ATE per model for each intervention-outcome cell;
3. take the median across models.

This ensures that every model receives equal weight even if one model produced
more successful calls than another.

#### C. Standardize each model and rescale to an arbitrary target

Not recommended. Z-scoring can preserve rankings but destroys the models'
native magnitude information. Choosing a target spread or multiplier would then
be an unsupported new assumption and could perform badly on RMSE/calibration.

#### D. Calibrate every model to GPT-5-mini's spread

Not recommended. Matching another model's variance does not establish human
calibration. It would force models to share GPT-5-mini's scale, reduce genuine
between-model information, and make the ensemble less meaningfully
multi-model.

#### E. Multiply every forecast by `0.56`

Not recommended for the primary entry. The `0.56` coefficient comes from a
regression of observed human effects on **GPT-4** predictions in the primary
archive of Ashokkumar, Hewitt, Ghezae, and Willer. It was not estimated for
GPT-4o, GPT-5-mini, Gemini 2.5 Flash Lite, Claude Opus 4.6, our exact climate
outcomes, or our direct-effect prompting procedure.

The same paper's Supplementary Figure S2 illustrates the model-specificity of
this problem: the corresponding slopes varied substantially across GPT-3,
GPT-3.5, GPT-4, DeepSeek-v3, GPT-OSS, and Gemma-3. A single universal correction
is therefore difficult to defend.

The original authors used leave-one-study-out regression on a large archive to
calibrate effects. We do not have equivalent external human data for each of
our current models and procedure.

### Recommended decision

Use the **unstandardized median consensus** as the primary prediction:

- each model is explicitly instructed to forecast conservatively in original
  outcome units;
- prompt variants are combined within model;
- models are combined by the median;
- no model-specific or universal post-hoc multiplier is applied;
- physical scale bounds are enforced, but individual cells are not manually
  edited.

A `0.56`-shrunk consensus can be retained as a documented sensitivity analysis
or an optional secondary entry, but it should be labelled as a transfer of a
GPT-4 calibration coefficient—not as a validated correction for our ensemble.

## 3. Do we need demographic profiles and long conversations?

### Important clarification

**Tier 3 does not require demographic profiles or synthetic respondents.** It
requires only direct intervention-by-outcome ATE predictions. Demographic
profiles are central to Tier 1 and Tier 2 approaches, but they are not a Tier-3
file requirement.

We could still use profiles internally to generate Tier-3 effects, but doing so
would recreate much of the expensive Tier-1 workflow while receiving only
Tier-3 scoring. That is outside the minimum viable plan.

### Conversation choices

#### Option A. Simulated respondent conversation

A synthetic respondent receives a demographic profile, control or treatment,
and then answers outcomes over one or more turns. This is closest to the
Ashokkumar/Hewitt participant-simulation method and to our book pre/post
workflow, but it requires decisions about profiles, condition assignment,
survey order, context carryover, and aggregation across thousands of calls.

Not recommended under the deadline.

#### Option B. Independent call for every intervention-outcome pair

Each model sees one intervention and forecasts one outcome. This minimizes
cross-outcome influence but requires 16 x 13 calls per model and prompt variant.
It also makes it easier for forecasts across related outcomes to become
internally inconsistent.

Scientifically defensible, but not the minimum-complexity option.

#### Option C. One direct-forecast call per intervention returning 13 ATEs

Each model sees the target population, all control materials, one intervention,
and all 13 clearly defined outcomes, then returns a structured 13-number effect
vector. Calls are stateless across interventions.

Recommended because it:

- matches the Tier-3 estimand directly;
- requires only 16 calls per model and prompt variant;
- avoids pretending that the model is a human respondent;
- permits coherent differentiation between proximal trust outcomes and distal
  attitudes/behaviors;
- creates simple, auditable raw outputs.

This is a real methodological change from the book project. Nalanda remains the
calling, structured-output, logging, and reproducibility layer, but the
submission should be described as **nalanda-assisted direct effect
forecasting**, not as a synthetic respondent sample.

## 4. How many simulations or repeated calls per model?

### The meaning of “simulation” has changed

In the book project, 50 simulations approximated 50 synthetic readers for each
identity and chapter. In the proposed Tier-3 design, a model call directly
returns 13 population-level ATE forecasts. Repeating that call 50 times does
not create 50 meaningful synthetic respondents; it creates 50 repeated expert
forecasts from the same model.

For that reason, the more useful source of replication here is a small set of
fixed **prompt variants**, not dozens of identical low-temperature calls.

### Should every model receive the same number of calls?

Not necessarily. Equal call counts are attractive, but they do not produce
equal precision when one API exposes low-temperature inference and another has
fixed stochastic sampling. The important constraint is that extra repetitions
stabilize a model's single forecast and do **not** give that model extra weight.

The registered hierarchy should therefore be:

1. median across repeated completions within each model x prompt x cell;
2. median across the fixed prompt variants within each model x cell;
3. median across the three family-representative models.

Under this hierarchy, five GPT-5-mini completions still yield exactly one
OpenAI vote. Google and Anthropic each yield one vote as well. The design is not
an equal-compute model contest; it is a family-balanced ensemble whose noisy
component is estimated with modestly greater precision.

### Recommended minimum viable rule

- Use **one completion per prompt** for the low-temperature Google and
  Anthropic representatives.
- Use **five completions per prompt** for GPT-5-mini because its sampling
  temperature is not controllable through the underlying older GPT-5 API.
- Keep at least the two existing prompt variants.
- This requires 32 Google calls, 32 Anthropic calls, and 160 GPT-5-mini calls:
  **224 calls in total** for the three-model MVP.
- Aggregate repetitions within prompt, prompts within model, and only then
  models within the consensus.
- Do not use 50 GPT-5-mini repetitions by default. Fifty would produce 1,600
  GPT calls (16 interventions x 2 prompts x 50) without evidence that the
  additional precision changes the locked ATEs meaningfully.

One completion is enough **per prompt variant** for the low-temperature models.
Five is a pragmatic, odd-numbered median for GPT-5-mini: enough to reduce the
influence of an unusual draw without recreating a synthetic-respondent study.
This model-specific exception and aggregation order must be disclosed.

If cost and time are comfortable, the next improvement should be a third fixed
prompt variant—not 50 identical repetitions. Three variants would permit a
within-model median and require 48 calls per model. The Nature study similarly
found that averaging across more distinct prompts improved accuracy, although
its much larger prompt ensemble does not establish the optimal number for this
benchmark.

Official OpenAI documentation is more precise than saying GPT-5-mini “supports
only temperature 1”: older GPT-5 models reject the `temperature` parameter, so
sampling temperature is not user-controllable. The gateway-compatible value of
1 remains in the local configuration, but it should be documented as a routing
constraint rather than an experimental temperature choice. This is another
reason to prefer Google and Anthropic for the two formal individual-model
entries.

Extra repetitions may be run later as an internal sensitivity check, but they
should not silently replace the frozen registered predictions.

## 5. What carries over from the book project?

Keep:

- several independent model families;
- fixed prompts and model settings;
- preservation of model-level results;
- equal model weight in the consensus;
- explicit agreement/disagreement diagnostics;
- no reliance on a single model's quirks;
- nalanda and the NYU gateway infrastructure.

Change:

- ranking becomes numeric ATE forecasting;
- one DV becomes 13 DVs;
- pre/post simulated identities become stateless intervention-level forecasts;
- model disagreement becomes a diagnostic, not a reason to remove a model
  after inspecting its benchmark outputs;
- scale correction is not assumed to transfer across models.

## 6. Remaining decisions for a short team review

Only four decisions require human sign-off before the smoke test expands:

1. **Exact consensus model roster.** Confirm the three preferred family
   representatives or activate a named within-family fallback after smoke-test
   failure.
2. **Formal entries.** Submit consensus only, or reserve the two optional
   secondary slots for specified individual models/sensitivity variants?
3. **Primary magnitude rule.** Confirm unscaled median consensus as primary and
   treat `0.56` only as sensitivity, if retained at all.
4. **Prompt/repetition budget.** Confirm two fixed prompts, one completion for
   Google/Anthropic, and five for GPT-5-mini.

Everything else can remain automated.

## Sources

- Silicon Sample Benchmark rules and tier definitions:
  <https://janpfander.github.io/llm_predictions_megastudy/>
- Official submission-template explanation of entries and per-tier limits:
  <https://github.com/janpfander/silicon-sample-submission>
- Ashokkumar, Hewitt, Ghezae, and Willer (2026), Nature article:
  <https://doi.org/10.1038/s41586-026-10742-x>
- Supplementary Information, especially prompting strategy, calibration, and
  Figure S2:
  <https://media.springernature.com/original/springer-static/esm/art%3A10.1038%2Fs41586-026-10742-x/MediaObjects/41586_2026_10742_MOESM1_ESM.pdf>
- Prior Power of Us model-consensus approach:
  <https://www.powerofusnewsletter.com/p/can-ai-help-us-find-the-books-that>
- Official OpenAI parameter-compatibility guidance for older GPT-5 models:
  <https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.2>
- Google Vertex AI release notes describing Gemini 3.1 Pro Preview as its most
  advanced reasoning Gemini model:
  <https://docs.cloud.google.com/vertex-ai/generative-ai/docs/release-notes>
- Google Cloud model card for Claude Opus 4.6:
  <https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/opus-4-6>
