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
_(fill in when done: what was built, shortcuts taken, anything the next step must know)_
