# Step 04: A save with impossible numbers does not fit (fix)

## Problem
Spec B2: an engine "must never fail on a save it does not understand (it reads as 'no save')". `stateFits` (end of `engines/dart/lib/engine.dart`) checks that ids exist but not that numbers are possible. Confirmed: a save with `"combat": { "enemy": -1, "health": [-3] }`, `"taken": ["a#-2"]` and a stat at -5 fits, and `fight()` then throws `RangeError`.

## Change
In `stateFits`, also require:
- every stat value `>= 0`, and `<= max` when it has one;
- `combat.enemy` within the enemy list (`>= 0`); each enemy health within `0..enemy.health`; `combat.luck.enemy` within the list and its `dealt` and `taken` `>= 0`;
- the index of every `taken` entry `>= 0`;
- every visit count `>= 1`.

No spec change: B2 and B14 already say it. No conformance case (saves are not part of the format).

## Files
- `engines/dart/lib/engine.dart` (`stateFits`).
- `engines/dart/test/state_fits_test.dart`: one failing-first test per check above.

## Done when
Each bad save reads as "does not fit"; a save written by `GameState.toJson()` mid-fight with an open luck test still fits; checks green.

## Handoff notes
- As planned, all in `stateFits`: stats in `0..max`, visit counts at least 1, `taken` indexes at least 0, and for a fight the enemy index, each enemy's health in `0..` its start, and the luck test's enemy, `dealt` and `taken`.
- An enemy's health can't go above its start, since luck never heals a side past its maximum (B11), so the check is safe. Both places in `combat.dart` that create a `LuckChance` pass a living enemy's index and wounds of 0 or more, so a real save always fits.
- Tests in `state_fits_test.dart`: 11 bad saves, all failing without the fix, plus a mid-fight save with an open luck test, round-tripped through JSON, that fits.
- Done on the branch `step-04-save-fits` from `main`.
