# Step 09: CI for the site

## Scope
A `site` job in `.github/workflows/ci.yml`: pub get, format, analyze --fatal-infos, test (VM + chrome), build; extend the schema job to check `site/examples/**/*.json`.

## Files
.github/workflows/ci.yml, tools/check_schema.py (only if globbing needs it)

## Tests
CI green on the PR.

## Done when
Job runs and passes.

## Handoff notes
- `.github/workflows/ci.yml` has a `site` job (pub get, format, analyze --fatal-infos, VM tests, Chrome tests, build) and the schema job also checks `site/examples/*/*.json`.
- Every step in the job was run locally and passes; the workflow itself has not run on GitHub yet (nothing pushed). Check it on the first pull request.
- Examples must stay one folder deep (`examples/<chapter>/<name>.<lang>.json`) for the schema glob.
