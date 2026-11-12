# Step 10: Counted items (feature, schema 8)

Needs step 07. The largest step: two commits are fine (A: spec, cases, engine; B: site and tutorial). Commit B marks the step done.

## Problem
The pack is a set: an item is held or not (spec B5, "Items are unique"). Fighting Fantasy's ten Provisions, a quiver of arrows or three healing herbs cannot be usable items; authors must fake them with a stat, which cannot be "used" from the pack or in a fight.

Evidence: `spec/comparison.md` section 3. Fighting Fantasy: Provisions, eaten outside fights. Lone Wolf: Meals; "told to eat" means tick one off or lose 3 Endurance, which with this feature is two choices on the page: "Eat a Meal" (`if: has meal`, `take: meal`) and "Go hungry" (`if: not has meal`, `stat endurance -3`). Use that pattern in the tutorial example.

Known difference from Lone Wolf: there every Meal fills a Backpack slot; here a stack fills one. Kept simple on purpose; it is candidate 1 in the plan's README. Say it in the spec text so nobody takes it for a bug.

## The feature
```json
"items": { "provisions": { "name": "Provisions", "stack": 10,
    "use": { "effects": [ { "stat": "stamina", "add": 4 } ], "when": ["story"] } } }
```
- Item `stack` (integer >= 2): the player can hold up to that many. An item without `stack` stays unique, exactly as today.
- `{ "give": "provisions", "count": 3 }` and `{ "take": "provisions", "count": 2 }`: `count` is an integer >= 1, default 1. A give stops at `stack` (the rest is lost, silently, like a stat at its limit); a take stops at 0. `count` above 1 on an item without `stack` is a validator **error**.
- `{ "has": "arrow", "count": 2 }`: holds at least 2 (default 1).
- **Using** a stacked item spends one; it leaves the pack when the last one is spent.
- **Pack room**: a stack fills one slot whatever its count. Its `bonus` applies once, while at least one is held.
- **Losing**: pack overflow (a container gone) and `takeAll` lose the whole stack.
- **`pickup: "auto"`**: more of a stack already carried is always added (it needs no room); a stack not carried needs a free slot or is refused whole.
- **`pickup: "choose"`**: more of a stack already carried is added directly, no offer. Otherwise the give is one offer for the whole count; a further give while it is on offer adds to that offer. Taking it (or swapping for it) takes all of it.
- Creation picks: a `give` with a count adds directly, as they do today.
- Translations: `stack` and every `count` must match; it is structure, not text. Add them to what `compareTranslations` checks only if cheap; otherwise say in the handoff notes that it is not checked.

## Engine design (keep existing code and saves working)
- `GameState.inventory` stays the ordered `Set<String>`. Add `GameState.counts`, a `Map<String, int>` holding the amount of each **stacked** item that is in the pack **or on offer** (an item is never both), and `int count(String item)`: 0 if not held, else `counts[item] ?? 1`. In the save JSON as `counts`; a save without it reads as empty.
- `effect.dart`: `GiveItem.count`, `TakeItem.count`; `applyEffect` for both; `TakeAll` clears counts of held items.
- `condition.dart`: `HasItem.count`; `evaluate`; `explain` (the `Unmet` it returns already carries the condition, so the count travels with it).
- `engine.dart`: `_give` (the rules above), `useItem` (spend one), `resolveOffer`, `_enforceCapacity` and `_applyCreation` (drop the count with the item), a new event `ItemCountChanged(item, from, to)` from `_changes` for an item held before and after with a different count, `stateFits` (every key of `counts` is an item with `stack`, held or offered, amount within `1..stack`).
- `validate.dart`: the count error above; the `*-never-given` warnings are unaffected.
- `story.dart` / `schema_gate.dart`: `Item.stack`, parsing, gate paths (`items.<id>.stack`, the effect's or condition's `count`).

## Conformance
- New `expect` key `counts`: for each item listed, how many are held (0 if none). Document it in the "Expect" table of `conformance/README.md`, add counted items to its "Coverage" list, and read it in `engines/dart/test/conformance_test.dart`.
- Cases in `play/`: `stack-give-and-ceiling.json`, `stack-take-to-zero.json`, `stack-has-count.json`, `stack-use-spends-one.json`, `stack-one-slot.json`, `stack-refused-when-full.json`, `stack-offer-whole-count.json`, `stack-more-while-carried-no-offer.json`, `stack-lost-with-container.json`, `stack-take-all.json`.
- Cases in `invalid/`: `stack-needs-schema-8.json`, `count-on-unique-item.json`.

## Spec
B5 (replace "Items are unique: the inventory is a set" with the two kinds), B4 "Inventory rules" (the pickup rules above), B7 (`has`), B9 (`give`, `take`, `takeAll`), B14 (a save fits), Part A "The five ingredients" / "Carrying limits", CHANGELOG row 8, JSON Schema.

## Site (commit B)
- `views.dart`: a `count` on the item view (and on the offer view); filled in `play_session.dart` where it builds items (line 129) and offers.
- `pack_panel.dart`: show "×3" next to the name when the count is above 1.
- `play_session.dart` `_requirement` (line 168): the locked reason for `has` with a count ("Needs: 2 × Arrow"); wording in `site/strings/{en,pt}.json`.
- `log.dart`: a line for `ItemCountChanged` ("Provisions: 5 → 4"), strings in both languages.
- Tests: `site/test/play_items_test.dart`, `wording_test.dart`.
- Tutorial: a section in `site/content/{en,pt}/03-items.md` with the example pair `site/examples/03-items/provisions.{en,pt}.json` (start with five meals, eat one to heal, a choice that needs two). If it fits in a page, a cookbook recipe with arrows in `cookbook.md` and `site/examples/cookbook/`.
- `README.md` "Items" feature list; `spec/llm-kit.md` regenerated (in commit A).

## Done when
On the site the provisions example shows the count going down as meals are eaten and the item leaving the pack at 0, in both languages; every case passes; checks green. Then delete `temp-plan/` if the owner agrees (ask).

## Handoff notes
(fill in)
