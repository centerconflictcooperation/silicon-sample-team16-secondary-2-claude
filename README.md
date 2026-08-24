# Silicon Sample Benchmark: Team 16 secondary 2

This repository contains team 16's Tier-3 **Claude Opus 4.6** submission to the
[Silicon Sample Benchmark](https://janpfander.github.io/llm_predictions_megastudy/).
It is a controlled single-model comparison with the team's primary three-family
consensus: benchmark inputs, two prompts, and median prompt aggregation are held
fixed, while only the contributing model differs.

The locked submission is
`predictions/team_16_T3_secondary-2_v1.csv` (208 intervention-outcome ATEs).
The exact method and blinding declaration are in `registration.md`.

## Repository map

- `predictions/`: locked organizer-format prediction file
- `forecast_pipeline/inputs/` and `prompts/`: frozen model inputs
- `forecast_pipeline/outputs/raw/model_responses.csv`: 32 archived completions
- `forecast_pipeline/scripts/`: preparation, generation, aggregation, reporting,
  and finalization scripts
- `forecast_pipeline/reports/`: source and rendered model-specific report
- `docs/index.html`: GitHub Pages copy of the report

Scripts 03 and 04 rebuild the derived forecast and report without making API
calls. Script 02 is retained for transparency and defaults to preview mode with
model calls disabled. The organizers' `make check` or `Rscript scripts/check.R`
validates the deposited submission.

GitHub Pages report (after publication):
<https://centerconflictcooperation.github.io/silicon-sample-team16-secondary-2-claude/>
