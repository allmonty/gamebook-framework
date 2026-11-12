# Step 10: Counted items (feature, schema 8)

Needs step 07. The largest step: two commits are fine (A: spec, cases, engine; B: site and tutorial). Commit B marks the step done.

## Problem
The pack is a set: an item is held or not (spec B5, "Items are unique"). Fighting Fantasy's ten Provisions, a quiver of arrows or three healing herbs cannot be usable items; authors must fake them with a stat, which cannot be "used" from the pack or in a fight.

Evidence: `spec/comparison.md` section 3. Fighting Fantasy: Provisions, eaten outside fights. Lone Wolf: Meals; "told to eat" means tick one off or lose 3 Endurance, which with this feature is two choices on the page: "Eat a Meal" (`if: has meal`, `take: meal`) and "Go hungry" (`if: not has meal`, `stat endurance -3`). Use that pattern in the tutorial example.

## The feature
Owner's decision (2026-11-11): `stack` is how many of the item fit in **one pack slot**, not how many can be held.
```json
"items": { "meal": { "name": "Meal", "stack": 5,
    "use": { "effects": [ { "stat": "stamina", "add": 4 } ], "when": ["story"] } } }
```
- Item `stack` (integer >= 1) makes the item **countable**: the player can hold several. An item without `stack` stays unique, exactly as today.
- **Pack room**: a countable item fills `ceil(count / stack)` slots. With `"stack": 5`, 5 Meals fill one slot and 6 fill two (a stack of 5 and a single one). `"stack": 1` means every unit fills its own slot (Lone Wolf's Meals). Without `rules.inventory.capacity` the pack is unlimited, so the count is too.
- `{ "give": "meal", "count": 3 }` and `{ "take": "meal", "count": 2 }`: `count` is an integer >= 1, default 1. A take stops at 0. `count` above 1 on an item without `stack` is a validator **error**.
- `{ "has": "meal", "count": 2 }`: holds at least 2 (default 1).
- **Using** a countable item spends one; it leaves the pack when the last one is spent.
- Its `bonus` applies once, while at least one is held.
- **`pickup: "auto"`**: as many units as fit are added (first the room left in a part-filled slot, then free slots); the rest are refused and the player is told how many were left behind.
- **`pickup: "choose"`**: if the whole count fits without a new slot (room left in a part-filled slot), it is added directly. Otherwise the give is **one offer for the whole count**; a further give while it is on offer adds to that offer. Taking it adds as many units as fit and leaves the rest (the player is told); with a full pack the player may first leave one carried item behind to free a slot, as for any offer.
- **Losing room** (a container goes): the newest items go first, as today; from a countable item, units are lost only until what is left fits.
- `takeAll` removes every unit. Creation picks: a `give` with a count adds directly, then the usual overflow rule applies.
- Translations: `stack` and every `count` must match; it is structure, not text. Add them to what `compareTranslations` checks only if cheap; otherwise say in the handoff notes that it is not checked.

## Engine design (keep existing code and saves working)
- `GameState.inventory` stays the ordered `Set<String>`. Add `GameState.counts`, a `Map<String, int>` holding the amount of each **stacked** item that is in the pack **or on offer** (an item is never both), and `int count(String item)`: 0 if not held, else `counts[item] ?? 1`. In the save JSON as `counts`; a save without it reads as empty.
- `effect.dart`: `GiveItem.count`, `TakeItem.count`; `applyEffect` for both; `TakeAll` clears counts of held items.
- `condition.dart`: `HasItem.count`; `evaluate`; `explain` (the `Unmet` it returns already carries the condition, so the count travels with it).
- `engine.dart`: `_give` (the rules above), `useItem` (spend one), `resolveOffer`, `slotsUsed` and `canHold` (slots are `ceil(count / stack)`), `_enforceCapacity` (lose units, not the whole item), `_applyCreation`, an `ItemRefused` that can carry how many were left, a new event `ItemCountChanged(item, from, to)` from `_changes` for an item held before and after with a different count, `stateFits` (every key of `counts` is an item with `stack`, held or offered, amount >= 1, and the slots used do not exceed the capacity).
- `validate.dart`: the count error above; the `*-never-given` warnings are unaffected.
- `story.dart` / `schema_gate.dart`: `Item.stack`, parsing, gate paths (`items.<id>.stack`, the effect's or condition's `count`).

## Conformance
- New `expect` key `counts`: for each item listed, how many are held (0 if none). Document it in the "Expect" table of `conformance/README.md`, add counted items to its "Coverage" list, and read it in `engines/dart/test/conformance_test.dart`.
- Cases in `play/`: `stack-fills-slots.json` (stack 5: 5 units one slot, the 6th a second), `stack-of-one.json` (every unit a slot), `stack-take-to-zero.json`, `stack-has-count.json`, `stack-use-spends-one.json`, `stack-partly-refused.json` (auto: what fits is added, the rest refused), `stack-offer-whole-count.json`, `stack-offer-takes-what-fits.json`, `stack-fits-in-slot-no-offer.json`, `stack-loses-units-with-container.json`, `stack-take-all.json`.
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
- Two commits: `248705e` adds the spec, engine, cases and the site's log line for a count change (the site's log covers every engine event, so it would not compile without it); the second takes counts to the rest of the site and the tutorial and marks the step done.
- **The state differs from the design above.** `counts` holds the count of an item held more than once (an item held once has no entry, so `count()` is `counts[item] ?? 1` when held); offers have their own `offerCounts`. The step's "an item is never both held and offered" is false for countable items: with `pickup: "choose"`, a give that needs a new slot is offered even when some are already carried. Both maps are in the save; a save without them holds one of each.
- `GiveItem`, `TakeItem` and `HasItem` keep `count` as written (null when absent), with `amount` defaulting to 1. The gate needs this: a `"count": 1` in a schema 7 story must be rejected, since a schema 7 engine does not know the key.
- `applyEffect` stays free of the story: its `take` and `takeAll` handle counts, but its `give` only adds the item. Every give in the engine goes through `_give` (or creation), which knows the stack and the pack.
- Engine pieces: `_slots`, `_slotRoom`, `_room`, `_give`, `_add`, `_offer`; `offerCount`; events `ItemCountChanged` (new) and a `count` on `ItemGained`, `ItemRefused`, `ItemOverflow`. A count change caused by overflow is not reported twice. Leaving a carried item behind for an offer leaves all of it.
- Parsing also rejects a container with a `stack` ("a container cannot be counted"); spec B5 says so and the JSON Schema has the `not`.
- **Translations:** `compareTranslations` compares ids, not effects, so `stack` and `count` are not compared. Spec B5 says so.
- Conformance: expect key `counts` (in the runner and the README table); 11 play cases and 2 invalid cases, as listed above.
- Site: one string `player.items` ("{count} × {item}") for the pack, an offer and a locked choice ("Needs: 2 × Meal"); log keys `gainedMany`, `lostMany`, `refusedMany` and `count` ("Meal: 5 → 4"). VM tests, and a browser test (9 browser tests now).
- Tutorial: "Things that come in numbers" / "Coisas que vêm em quantidade" in chapter 3, with `examples/03-items/provisions` (five meals, a ferryman who wants two, a night where you eat one or go hungry, the Lone Wolf pattern), and two rows in the chapter's table. **Not done:** the optional cookbook recipe with arrows.
- The step's "delete `temp-plan/`" is out of date: steps 11 to 15 and the owner's checkpoint come next.
- Done on the branch `step-10-counted-items` from `main`.
