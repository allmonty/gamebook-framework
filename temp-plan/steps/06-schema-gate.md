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
(fill in)
