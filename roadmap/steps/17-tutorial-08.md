# Step 17: Tutorial 8: Check and publish

## Scope
Validator issues and codes, story graph, simulator, translations, `.gamebook` packages, Twine import, LLM kit, authoring fields (title, note, chapter, draft), other engines.

## Files
site/content, site/examples/08-*

## Tests
same

## Done when
same

## Handoff notes
- Chapter 8 covers errors vs warnings (the B16 codes), reading JSON paths, authoring fields (schema 6) with the `tidy-book` example (titles shown, notes, chapters), the CLI tools (validate with `--strict`/`--llm`, graph, simulator), translations, `.gamebook` packages, Twine import, the LLM kit and the conformance suite.
- Examples must stay warning-free, so the chapter has readers *add* the mistakes (an unreachable page, an unset flag, a renamed page) instead of shipping a broken example.
- Two player fixes came out of this step, each its own commit: pages without a title get no heading under `showTitles` (spec B13), and the editor shows warning codes.
- The chapter links to `cookbook.md`, written in step 18.
