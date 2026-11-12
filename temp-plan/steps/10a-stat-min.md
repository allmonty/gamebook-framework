# Step 10a: A lower limit per stat (feature, schema 8)

Added 2026-11-12 at the owner's request (candidate 10). Needs step 07.

## Problem
Every stat is clamped at 0 from below (B4), and since step 03 so is a stat with item bonuses. So a stat cannot be a signed modifier as in tabletop RPGs ("Might -1"): a cursed item at -5 Might held at Might 2 gives 0, and in `1d20 + might` the last 3 points of penalty are lost.

## Example story first
Write `site/examples/04-stats-and-hero/cursed-gauntlet.{en,pt}.json` (d20-lite) before the spec: Might with `"min": -3`, a cursed gauntlet with `bonus: { might: -4 }`, and a check `1d20 + might` the reader can see fail more often while wearing it. Show it to the owner if anything in it feels off.

## The feature
- `rules.stats.<id>.min`: an integer, may be negative, default 0. Effects clamp a stat to `min..max` (or `limit`); a stat with item bonuses is never below `min` (B5, replacing "below 0").
- The `health` stat cannot have a `min` other than 0 (health at 0 is death): a parse error.
- A creation roll below `min` is raised to `min` (dice may have a negative `K`).
- `stateFits` (B14): every stat at least its `min`.

## Files
Spec B4 (stats table, "clamped at 0" becomes "clamped at `min`, 0 by default"), B5 (bonuses), B9 (stat effect row), B14; changelog row 8; JSON Schema; `story.dart` / `rules_spec.dart` / `rules.dart` (where `limit` lives); `state.dart` `StatValue` (it carries `max`; add `min`, in its JSON, default 0) and `GameState.stat()`; `schema_gate.dart` (`rules.stats.<id>.min`); `engine.dart` `stateFits`. Cases: a negative value, an effect stopping at `min`, a bonus stopping at `min`, `invalid/stat-min-needs-schema-8.json`, `invalid/health-min.json`. Site: the stats bar shows negative values (check the low-stat styling); tutorial section in chapter 4 with the example; README; LLM kit.

## Done when
The example shows Might -2 with the gauntlet on the site in both languages; checks green.

## Handoff notes
- One commit, on the shared branch `steps-10a-10d`.
- `StatValue(value, [max, min = 0])`: the floor travels with the stat, like `max`, set from the rules at creation. `clampedTo`, `adjusted` and `GameState.stat()` use it, so every effect, bonus and combat change already respects it. JSON writes `min` only when it is not 0, and an old save reads 0.
- `StatRules.min` (default 0) comes from `StatSpec.min`, merged with the preset like `limit`. `Rules.resolve` rejects a `min` on the health stat ("the health stat cannot have a min"), and `_checkedMin` rejects a `min` at or above the `limit`.
- `stateFits` now checks each stat against its rule: the saved floor must equal the story's `min`, and the value must lie between the floor and the ceiling. A story that changes a `min` drops old saves.
- The conformance runner turns given start values into stats the way the creation roll would, so it also raises a value below the `min` (README updated).
- Example `examples/04-stats-and-hero/cursed-gauntlet` (d20-lite: a cursed gauntlet at -4 Might, a door to force at `1d20 + might` ≥ 12, a defeat if it holds); the simulator wins about half and gets stuck nowhere. Tutorial "Below zero" / "Abaixo de zero" in chapter 4, plus a "Try it" line; the chapter has no summary table. A site test plays it in both languages.
- The site needed no change: the stats bar shows negative values as they are (the "low" style only applies to stats with a ceiling).
