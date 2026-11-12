# Step 06: Extract the schema gate (refactor)

## Problem
`engines/dart/lib/story.dart` is 929 lines. Lines 645 to 902 are the schema-version gate: `_firstSchema3Feature` to `_firstSchema7Feature`, each finding the first place a story uses something newer than its `schema`. Three of them walk every effect list by hand (`_takeAllIn`, the `newEffect` loops, `_findEffect`) although `Story.effectLists()` already yields every effect list with its JSON path.

## Change
Pure refactor, no behavior change.
- New `engines/dart/lib/schema_gate.dart` with one function, for example `(int, String)? firstNewerFeature(Story story, {required bool usesShowTitles})` returning the lowest version needed above `story.schema` and the JSON path. Move the five `_firstSchemaN` bodies and `_comparesStat`, `_usesVisits` into it.
- Replace the hand-written effect walks with `story.effectLists()`.
- `Story.fromJson` keeps one call and the exact error wording `needs "schema": N`.
- Keep `_checkTemplates` and the chapter check where they are (they are not gates).
- While here: move the two misplaced doc comments in `engine.dart` (the one above `TableRolled` belongs to `ItemUsed`; the one above `MusicChanged` belongs to `CombatStrike`), and make `StatValue.adjusted` call `clampedTo` in `state.dart`.
- `engines/dart/README.md`: add the file to the library table.

## Watch out
The order of the checks decides **which path** is reported first, and the `conformance/cases/invalid/*-needs-schema-N.json` cases compare that path. `effectLists()` yields item uses, then creation picks, then nodes; the old walks had their own order. If a case now reports a different path, keep the old order for that version rather than changing the case.

## Tests
No new ones: the invalid cases and `test/story_test.dart` are the safety net and must pass unchanged.

## Done when
`story.dart` no longer holds gate code, the gate has one effect walk, checks green with no test edited.

## Handoff notes
- `lib/schema_gate.dart` holds `firstNewerFeature(story, usesShowTitles:)`: a list of `(version, finder)` pairs, checked from 2 to 7, returning the first version above `story.schema` that finds something. `story.dart` went from 929 to 739 lines and calls it once; the wording `needs "schema": N` is unchanged.
- One effect walk, `_firstEffect`, over `story.effectLists()`, used by versions 3, 5 and 7. The schema 2 check (`items.*.use`), which was inline in `fromJson`, moved in too.
- `_checkTemplates` now runs just before the gate for schema 4 and up. That is the old order: the gates for 2 to 4 never ran for those stories.
- Not a single test or case changed. The report differs only when a story has **several** too-new things at once, and only in which comes first. Schema 3 now looks at every item's `capacity` before any `takeAll`. Schema 5 checks every page's fights and conditions before any effect. `takeAll` inside a table outcome or a creation pick is now found (needs 3) where the old walk skipped those lists and reported the table (4) or `rules.creation` (5). The cases with one feature each all report the same path.
- Also done: the two misplaced doc comments in `engine.dart` (`ItemUsed`, `CombatStrike`), `StatValue.adjusted` calls `clampedTo`, and `engines/dart/README.md` lists the new file.
- Steps 07 to 10 add their schema 8 check as one more `(8, _schema8)` pair in `firstNewerFeature`, plus `8` in `supportedSchemas` in `story.dart`.
- Done on the branch `step-06-schema-gate` from `main`.
