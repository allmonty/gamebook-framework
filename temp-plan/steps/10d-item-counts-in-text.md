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
- One commit, on the shared branch `steps-10a-10d`; the last step of that pull request.
- **Syntax settled without the owner:** `{meal.count}`. The `.count` suffix keeps it apart from a stat with the same id (stats only have `.max`), which was the open point. `text.dart` accepts the suffix and has `placeholderItems`; `placeholderStats` leaves `.count` out. The engine renders the count (0 if none). The validator reports an unknown item at the text's path. The gate reports the text's path, and only from schema 4 on: before that, braces are plain text.
- **The cap:** item `max`, which needs a `stack` (parse error otherwise). The engine splits room in two: `_packRoom` (slots) and `_capLeft` (the cap), with `_room` the smaller of the two. A new getter, `offerNeedsRoom`, says when an offer asks for a swap: only when the pack is full and the cap still lets some in. `resolveOffer`, the site's offer view and the simulator use it instead of `!canHold`, so an offer stopped by the cap asks for no swap. In `choose` mode a give at the cap is refused at once, without an offer. Creation picks stop at the cap; `stateFits` rejects a count above it.
- Example: `provisions` (chapter 3) got `"max": 6`, a farm where three more meals do not all fit, and `{meal.count}` on the night page. A site test plays the farm in both languages. Tutorial: two bullets and a table row in chapter 3, one paragraph in chapter 7 "Numbers in text".
- Cases: `item-count-in-text`, `-none`, `item-cap-give`, `item-cap-offer`, and four invalid cases (gate, cap without stack, placeholder gate, unknown item).
