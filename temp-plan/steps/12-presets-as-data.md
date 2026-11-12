# Step 12: Presets as data (docs + test)

## Problem
The two presets (`fighting-fantasy`, `d20-lite`) exist in two places: tables in `spec/framework.md` B4 and Dart code in `engines/dart/lib/rules.dart`. Whoever writes an engine in another language, or an AI asked to, has to retype them from prose. Nothing checks that the prose and the code agree, and an author who wants "Fighting Fantasy but with a Gold stat" cannot see the full rules block they are overriding.

## Change
- New `spec/presets/fighting-fantasy.json` and `spec/presets/d20-lite.json`: each is exactly the `rules` object a story would have to write to get the preset without naming it (stats in order with `label`, `roll`, `max`; `health`; `rerolls`; `combat`).
- `spec/framework.md` B4 "Presets": link them and say they are the normative numbers; keep the tables for readers.
- A test in `engines/dart/test/rules_test.dart`: for each file, `Rules.resolve` of that JSON equals `Rules.resolve` of `{ "preset": "<name>" }` (same stats in the same order, same health, rerolls and combat). Reading the files from `../../spec/presets/` is how `conformance_test.dart` already reads the cases.
- Do **not** make the Dart engine load presets from the files at run time: `lib/` does no I/O and the engine must run in a browser. The test is the link.
- `engines/README.md` step 2 ("Implement the spec"): point new engines at the files.
- License: the files are spec data; `LICENSE` should say which license covers them (MIT, like the schema and the cases).

## Done when
Both files exist, the test fails if either side changes alone, checks green.

## Handoff notes
- `spec/presets/fighting-fantasy.json` and `d20-lite.json`: the `rules` block each preset stands for. Defaults are left out (no `"max": false`, no `undo`), as a story would write it.
- The test is in `rules_test.dart`: `describe(Rules)` turns resolved rules into plain values (stats with id, label, roll, max, limit, min and hidden; health, rerolls, undo; combat mode, rolls, stats, defense, luck, table). Each file must resolve to the same as `{ "preset": "<name>" }`. Changing the damage in one file fails it, which I checked by hand and put back.
- As the step said, the engine still builds its presets in code: `lib/` does no I/O. The test is the link.
- Spec B4 "Presets" links the files and calls them normative; the tables stay for readers. The engines README tells new engines to build their presets from the files. LICENSE puts them under MIT with the schema and the cases. The README's map lists them.
