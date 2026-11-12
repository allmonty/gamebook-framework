# Step 09: Fight events (feature, schema 8)

Needs step 07.

## Problem
A fight can only end by winning, dying or fleeing. Classic gamebooks constantly write "if the creature wounds you, turn to 55" and "if you have not won after three rounds, turn to 120". Neither can be written today.

Evidence: `spec/comparison.md` section 3 (Fighting Fantasy). Escaping for 2 Stamina needs nothing new: it is the `flee` page with a `stat` effect; say so in the tutorial section.

## The feature (spec B11)
Two optional fields on a node's `combat`:
```json
"combat": {
  "enemies": [ { "name": "Giant scorpion", "attack": 8, "health": 6 } ],
  "win": "past-the-scorpion",
  "wounded": "stung",
  "rounds": { "after": 3, "to": "it-escapes" }
}
```
- `wounded` (node id): the first time the player loses health in this fight and is still alive, the fight ends and that page is entered.
- `rounds`: `after` (integer >= 1) and `to` (node id). When `after` rounds have been played and the fight is not over, it ends and `to` is entered. "Win within 3 rounds" is `after: 3` with `to` the page for being too slow.

Exact rules to write:
- After each round, in this order: health at 0 is **death**; every enemy down is the **win**; then `wounded`; then `rounds`.
- Using an item that costs the round (B5) counts as a round, and the enemy's strike as a wound. A free item counts as neither.
- No luck test is offered after a round that ended the fight (already the rule), so a wound that triggers `wounded` cannot be softened by luck.
- Both work in every mode (`opposed`, `vs-defense`, `table`, duels) and in fights against several enemies at once (the wounds of one round count as one wound).
- The pages are entered normally (B10 step 4). The round count is part of the saved fight.
- No new dice are rolled, so B8 "Order of rolls" is unchanged; say so there.

## Files
- Spec B11, B16 (`unreachable` now also follows `wounded` and `rounds.to`), Part A "Fights", CHANGELOG row 8, JSON Schema.
- `engines/dart/lib/story.dart`: `Combat.wounded`, `Combat.rounds` (a small `RoundLimit` class), parsing, the gate.
- `engines/dart/lib/state.dart`: `CombatState.round` (played so far), in its JSON; a save without it reads as 0.
- `engines/dart/lib/combat.dart`: `fightRound`, `groupRound` and `enemyStrike` return the state with the counter bumped; they already report `damageToPlayer`.
- `engines/dart/lib/engine.dart`: one private helper that, given the outcome and the damage the player took, enters `win`, `wounded` or `rounds.to`; call it from `fight` (both branches) and after the strikes in `useItem`. `testLuck` only needs the win it already has. `stateFits`: `round >= 0`.
- `engines/dart/lib/validate.dart`: `_target` for both in `_combat`; both added to the list in `_reachability` (next to `win` and `flee`).
- `engines/dart/lib/graph.dart`: two more edges, labelled.
- Tests: `combat_test.dart`, `engine_test.dart`, `validate_test.dart`, `graph_test.dart`, `state_fits_test.dart`.
- Cases in `conformance/cases/play/`: `fight-wounded.json`, `fight-rounds.json`, `fight-win-beats-wounded.json` (a round in a group fight that kills the last enemy while another wounds the player: win), `fight-wounded-beats-rounds.json`, `fight-item-counts-as-round.json`. In `invalid/`: `fight-events-need-schema-8.json`, `fight-wounded-unknown-node.json`. In `lint/`: extend or add an `unreachable` case showing a page reached only through `wounded` is reachable.
- Site: no new control. Confirm with a VM test in `site/test/play_combat_test.dart` that the round shows in the log and the new page follows.
- Tutorial: a section in `site/content/{en,pt}/06-combat.md` with the example pair `site/examples/06-combat/poison-sting.{en,pt}.json` using both fields.
- `README.md` "Advanced combat options"; `spec/llm-kit.md` regenerated.

## Done when
The example leaves the fight on the first wound and after the round limit on the site; all cases pass; checks green.

## Handoff notes
(fill in)
