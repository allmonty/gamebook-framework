# Step 11: The LLM kit names the newest schema (fix)

Independent of every other step; tiny. Doing it before step 07 saves a second regeneration.

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
(fill in)
