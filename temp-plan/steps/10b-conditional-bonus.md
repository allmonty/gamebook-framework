# Step 10b: A bonus that depends on a condition (feature, schema 8)

Added 2026-11-12 at the owner's request (candidate 4). Needs step 07; easier after 10a.

## Problem
Item bonuses (B5) apply while the item is carried, whatever else holds. Lone Wolf has bonuses that depend on more: +2 Combat Skill with Weaponskill *and* the right weapon, -4 when the hero has no weapon at all. Neither can be written.

## Example story first
Write `site/examples/04-stats-and-hero/unarmed.{en,pt}.json`: a hero who loses their sword to a river and fights the next enemy at -4 Skill, then finds a club and the penalty goes. Use it to check the design below reads well before writing the spec.

## The feature (proposed; confirm with the owner if the example shows a problem)
`rules.bonuses`: a list of `{ "if": <condition>, "bonus": { "skill": -4 } }`. While the condition holds, the bonus applies everywhere, exactly like an item bonus (checks, combat, conditions, `{stat}` text, the stats bar), and adds to item bonuses. A bonus on the `health` stat is not allowed, as for items.
- **No loops:** the conditions of `rules.bonuses` see the stats with item bonuses but **without** the rule bonuses (otherwise "+2 while Skill ≥ 10" could switch itself on and off). Say so in B5.
- The stats bar shows the total bonus, as today.

## Files
Spec B4 (rules table) and B5 ("Item bonuses" becomes "Bonuses"), changelog row 8, JSON Schema; `rules_spec.dart` (parse, path `rules.bonuses[i]`); `engine.dart` `_bonusOf` (item bonuses, then the rule bonuses whose condition holds on the state with item bonuses only); `schema_gate.dart`; `validate.dart` (conditions and stats checked like any other; `flag-never-set` etc. see them). Cases: a bonus on and off with its condition, one that adds to an item bonus, one whose condition reads a stat (shows the no-loop rule), `invalid/rule-bonus-needs-schema-8.json`, `invalid/rule-bonus-on-health.json`. Site: nothing new beyond a test that the stats bar shows it; tutorial in chapter 4 with the example; README; LLM kit.

## Done when
The example's fight shows Skill -4 without a weapon and none with the club, in both languages; checks green.

## Handoff notes
(fill in)
