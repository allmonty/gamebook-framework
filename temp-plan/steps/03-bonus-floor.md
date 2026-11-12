# Step 03: A bonus never takes a stat below 0 (fix)

## Problem
Spec B4: "Every stat is clamped at 0 from below." An item with `"bonus": { "luck": -20 }` held at Luck 8 gives an effective Luck of -12: the page text `{luck}` shows "-12" and checks use it.

## Rule to write (spec B5, "Item bonuses")
The effective value (stat plus bonuses) is never below 0. The stat itself is untouched, so losing the item still takes the bonus away cleanly.

## Files
- `spec/framework.md` B5; `spec/CHANGELOG.md` ("Clarified without a version change").
- `engines/dart/lib/state.dart`: `GameState.stat()` returns `max(0, value + bonus)`. Every reader (checks, combat, conditions, placeholders) already goes through it.
- `engines/dart/test/bonus_test.dart`: failing-first test.
- `conformance/cases/play/item-bonus-floor.json` (model: `item-bonus.json`): expect the stat at 0 and the paragraph showing 0.
- `spec/llm-kit.md`: regenerate.

## Done when
Case and test pass, checks green.

## Handoff notes
- As planned: `GameState.stat()` returns `max(0, value + bonus)`; no other reader needed a change. `bonusOf` is untouched, so the site's stats bar shows "Luck 0 (-20)": the real bonus next to the floored value.
- Test in `bonus_test.dart` (a -20 Luck bonus at Luck 8: 0, base still 8, text "Luck 0.", back to 8 when dropped) and case `item-bonus-floor.json`; both fail without the fix.
- Done on the branch `step-03-bonus-floor` from `main`.
