# Step 10g: One schema version (format)

Added 2026-11-12 at the owner's request.

## Problem
The format grew to eight schema versions while it was being built, but it was never released: no story or engine outside this repo depends on them. Keeping them costs every author (which number does a feature need?), every engine writer (eight version gates to implement), the tutorial ("(schema 5)" notes everywhere) and the LLM kit, and it tells a history that never shipped.

## Owner's decision (2026-11-12, do not reopen)
Merge all eight into **version 1**, before release. Keep the versioning machinery for the future: `"schema"` stays required, an engine still rejects versions it does not know, and the gate stays ready for version 2. The site keeps a versions page: version 1 and its features, and how versioning works (step 15).

## Change
- **Spec:** `framework.md` says there is one version, 1, with everything; every "(schema N)" note goes; B2 keeps the rule for future versions (a story that uses something newer than its `schema` is an error, and versions only add). `CHANGELOG.md`: one row, version 1, plus how later versions will be added. JSON Schema: `"schema": 1` only, no "Schema N." in descriptions.
- **Engine:** `supportedSchemas = {1}`; `schema_gate.dart` keeps `firstNewerFeature` with an empty list of gates (version 2 adds the first); the "braces are text before schema 4" rule goes (placeholders always work). `twine.dart` writes 1. The LLM kit says `"schema": 1` (this does step 11).
- **Stories:** every story in the repo (conformance cases, examples, fixtures, tests) says `"schema": 1`.
- **Cases:** the `invalid/*-needs-schema-N.json` gate cases go, and so does `needs-newer-schema.json`; a new `invalid/unsupported-schema.json` (`"schema": 2`) pins what is left. `conformance/README.md` says so.
- **Tests:** gate tests go; the rest use schema 1. The unsupported-schema test uses 2.
- **Site and tutorial:** every "(schema N)" note goes, in both languages.
- **READMEs:** "schema version 1".

One commit: once the engine accepts only 1, every story has to change with it.

## Done when
No story, test, spec text or tutorial page in the repo names a schema other than 1, except to say an unknown version is rejected; checks green.

## Handoff notes
- Two commits: the plan change, then the merge itself in one commit (once the engine accepts only 1, every story has to change with it). Done on the branch `step-10g-one-schema`.
- Engine: `supportedSchemas = {1}`. `schema_gate.dart` keeps `firstNewerFeature`, now with an empty const `_gates` list: version 2 adds the first entry. Its `usesShowTitles` parameter went with the schema 6 gate. Placeholders are always on: the "before schema 4 braces are text" rule is gone from `story.dart`, `engine.dart` and `validate.dart`. `twine.dart` writes 1. Library comments lost their "(schema N)" notes; three save comments now say "older saves".
- **The kit** writes the newest supported version, read from `supportedSchemas`, so it cannot fall behind again. That was what remained of step 11, now marked done.
- Stories: every JSON story in the repo (about 200) says `"schema": 1`. The 23 gate cases are gone; `invalid/unsupported-schema.json` (`"schema": 2`) is new. Engine and site tests: gate assertions removed by a script (every `expect` with `needs "schema"`, then tests and loops left empty), plus a few by hand; the "braces before schema 4" tests went; test names lost "schema N".
- Spec: one version; B2 says how later versions will be added; the changelog has one row for version 1, and a line that eight working versions were merged before release. JSON Schema: `"schema": 1` only, no "Schema N." in descriptions. Tutorial (both languages), READMEs and `comparison.md` (its "planned" and four "open" rows are now "done") have no version notes left.
- Not checked: stories outside this repo (the owner's app). Any with `"schema"` above 1 needs it changed to 1.
