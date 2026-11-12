# Step 10d: Item counts in text, and a cap on a counted item (feature, schema 8)

Added 2026-11-12 at the owner's request (two parts of candidate 9). Needs step 10.

## Problem
Since step 10 an item can be held many times, but page text cannot say how many ("You have {meal} meals left" works only for stats), and there is no way to say "a quiver holds at most 12 arrows" except through the pack's room.

## Example story first
Extend `site/examples/03-items/provisions.{en,pt}.json` (or write a small archery story): the camp page says how many meals are left, and a hunter sells arrows up to a quiver's limit. Check the placeholder reads well in both languages before writing the spec.

## The feature
- **Counts in text:** `{meal.count}` in page or choice text (schema 8) is replaced by how many of the item `meal` are held (0 if none). The validator rejects `{x.count}` when `x` is not an item. Proposed syntax: confirm with the owner if a stat and an item may share an id (they may today: the `.count` suffix keeps them apart, since stats only have `.max`).
- **A cap:** item `"max": 12` (only with `stack`): never more than 12 held. A give beyond it adds up to the cap and refuses the rest, told as when the pack is full; an offer takes up to the cap.

## Files
Spec B6 (placeholders), B5 (the cap), B4 (pickup with a cap), changelog row 8, JSON Schema; `text.dart` (placeholders), `story.dart` (`Item.max`; parse error without `stack`), gate (a `.count` placeholder; `items.<id>.max`); `engine.dart` (`_room` also respects the cap); `validate.dart` (unknown item in a placeholder). Cases: the placeholder with 0 and with some, a give stopped by the cap, an offer stopped by the cap, invalid cases for the gate, the cap without `stack`, an unknown item in a placeholder. Site: no new control; tutorial in chapter 3 next to "Things that come in numbers" and the placeholder in chapter 7 "Numbers in text"; README; LLM kit.

## Done when
On the site the example's text shows the meals left as they are eaten, and the hunter cannot sell past the cap, in both languages; checks green.

## Handoff notes
(fill in)
