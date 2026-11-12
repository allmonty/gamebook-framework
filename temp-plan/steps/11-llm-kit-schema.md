# Step 11: The LLM kit names the newest schema (fix)

Independent of every other step; tiny. Doing it before step 07 saves a second regeneration.

## Note (2026-11-12)
Step 10g merges every version into 1, and makes the kit say `"schema": 1`. What is left here is the guard: a test that the kit's version is the newest the engine supports, so it cannot fall behind when version 2 comes.

## Problem
`spec/llm-kit.md` is the file people give a chatbot to write stories. Its instruction 2 says: Use `"schema": 6`. A story valid in an older version is valid in 6. The format is at 7 (achievements), so a chatbot following the kit cannot use them, and the number will be wrong again at 8. The text is hard-coded in `engines/dart/bin/llm_kit.dart` (line 19). `engines/dart/lib/twine.dart` (line 99) also writes `'schema': 6`, which is correct for what the importer emits: leave it.

## Change
- `engines/dart/bin/llm_kit.dart`: build the number from `supportedSchemas` (the newest), so it can never go stale.
- Regenerate `spec/llm-kit.md`.
- `engines/dart/test/llm_kit_test.dart`: the failing-first test: the kit names the newest supported schema.
- While reading the kit's "Mistakes that most often make a story invalid" list, check each line against the spec as it is now; fix only what is wrong.

## Done when
The kit says schema 7 now, and will say 8 after step 07 with no hand edit; checks green.

## Handoff notes
- Done inside step 10g: `bin/llm_kit.dart` writes `"schema"` from `supportedSchemas` (the newest version), so the kit names version 1 now and follows when version 2 is added. The existing `llm_kit_test` keeps the generated file up to date.
