# Sources and relevance to the Tier-3 plan

## Official benchmark materials

- Benchmark call, rules, tiers, and scoring:
  <https://janpfander.github.io/llm_predictions_megastudy/>
- Official submission template:
  <https://github.com/janpfander/silicon-sample-submission>
- nalanda documentation:
  <https://centerconflictcooperation.github.io/nalanda/>
- Zenodo GitHub-release instructions:
  <https://help.zenodo.org/docs/github/archive-software/github-upload/>

This forecast pipeline is embedded inside a complete clone of the organizers'
submission-template repository. The repository-root intervention labels,
outcome labels, survey, metadata schema, and helper scripts are therefore kept
as one coordinated versioned set.

## Prior Power of Us approach

- Rémi Thériault, Dominic Packer, and Jay Van Bavel (July 21, 2026), “Can AI
  Help Us Find the Books That Bridge Political Divides?”:
  <https://www.powerofusnewsletter.com/p/can-ai-help-us-find-the-books-that>

Useful transferable principles:

1. Treat LLM results as predictive signals rather than literal human effect
   estimates.
2. Preserve results from each model separately before pooling.
3. Use model consensus to reduce dependence on one model's idiosyncrasies.
4. Inspect disagreement as a diagnostic, but fix exclusion criteria before
   inspecting the benchmark forecasts.
5. Use deterministic or low-temperature calls where supported and record
   model-specific exceptions.
6. Expect safety refusals, route retirement, and interrupted jobs; run a small
   smoke test before committing to a model set.

Important difference: the book project primarily ranked interventions. This
benchmark scores absolute ATE calibration as well as directions and rankings.
The Tier-3 pipeline therefore retains a transparent consensus ATE and a
separate, globally shrunk ATE rather than silently interpreting raw model
effects as calibrated human effects.

## Existing local resources

- `simulations_GPT.R` is useful for the working NYU gateway configuration,
  candidate model names, temperature conventions, error behavior, and nalanda
  usage patterns.
- `model correlations.R` contains the earlier temperature sensitivity,
  inter-model agreement, pairwise-correlation, and rank-consistency analyses.
  Its most useful transferable code is the model-level aggregation and
  disagreement diagnostics. In the book project, agreement was much stronger
  across temperatures than across model families and weakened at finer units
  of analysis. That supports retaining model-level forecasts and reporting
  disagreement here. However, benchmark-model inclusion must be fixed from
  route availability and a content-neutral smoke-test rule before inspecting
  the benchmark forecasts; models must not be removed merely because their
  benchmark predictions disagree with the others.
