# Step 08: A neutral ending (feature, schema 8)

Needs step 07.

## Problem
A page can only end in `victory` or `death`. Many gamebook endings are neither: captured, lost in the woods, gave up and went home. Today they must be written as `death` and the player is told "You died".

## The feature
`"ending": "defeat"`: the adventure is over, the hero is alive and has not won. Everything else about endings is unchanged; health at 0 is still always `death`, whatever the page says.

## Files
- Spec: B6 node table (`ending`), B10 step 6, Part A ("different endings"), CHANGELOG row 8, JSON Schema enum.
- `engines/dart/lib/story.dart`: `Ending.defeat`, parsing, the gate (path `nodes.<id>.ending`).
- `engines/dart/lib/simulate.dart`: `Outcome.defeat` and its share in the report line (line 136 now maps everything that is not victory to death); `bin/simulate_story.dart` if it prints outcomes itself.
- `engines/dart/lib/graph.dart` (near line 193): a style for defeat pages in DOT and Mermaid.
- `engines/dart/lib/validate.dart`: nothing; `no-victory` still asks for a victory.
- The analyzer will point at every `switch` on `Ending` that is no longer exhaustive: fix each.
- Tests: `story_test.dart`, `simulate_test.dart`, `graph_test.dart`.
- Cases: `conformance/cases/play/defeat-ending.json` (expect `"ending": "defeat"`), `invalid/defeat-needs-schema-8.json`. Add `"defeat"` to the `ending` row of the "Expect" table in `conformance/README.md`.
- Site: string `player.ending.defeat` in `site/strings/en.json` and `pt.json` (next to `player.ending.victory`); check the ending heading and `log.dart` handle the new value; VM test.
- Tutorial: a section in `site/content/{en,pt}/07-living-world.md` with the example pair `site/examples/07-living-world/captured.{en,pt}.json`: a short story with one victory and one defeat ending.
- `README.md` feature list ("Multiple endings"); `spec/llm-kit.md` regenerated.

## Done when
The example plays to the defeat ending on the site with its own heading in both languages; checks green.

## Handoff notes
- Two commits: `317c51c` adds the format, engine and tools; the second takes the ending to the site and the tutorial and marks the step done.
- Engine: `Ending { victory, defeat, death }`; the schema 8 check `nodes.<id>.ending` is in `_schema8` (`schema_gate.dart`), after `imageAlt`. The parse error now reads `expected "victory", "defeat" or "death"`.
- Simulator: `Outcome.defeat`. The report line now reads `victory N%, defeat N%, death N%, ...`. Anything that parses that line must expect the new field.
- Graph: DOT fills defeat pages amber (`#ffe0b2`). Mermaid had no colours for endings (all are the same stadium shape), so it needed nothing.
- No `switch` on `Ending` existed outside `simulate.dart`; the site picks the heading by name (`player.ending.<name>`). A site test now requires a heading for every `Ending` value, in both languages.
- Site: `player.ending.defeat` ("Defeat // the end", "Derrota // fim"); `.gb-ending.defeat` in amber. A VM test and a browser test (8 browser tests now).
- Tutorial: "Endings that are not a death" / "Finais que não são morte" in chapter 7 after Undo, with `examples/07-living-world/captured` (title "The Border" / "A Fronteira": one victory, two defeats), and a "Try it" line. The simulator reaches every ending, with nothing stuck.
- `validate.dart` was unchanged: `no-victory` still asks for a reachable victory.
- Done on the branch `step-08-defeat-ending` from `main`.
