# Step 10c: A flee that costs a round (feature, schema 8)

Added 2026-11-12 at the owner's request (candidate 2). Needs step 09 (fight events).

## Problem
Fleeing (B11) leaves at once; any penalty is an effect on the flee page. Lone Wolf's evasion works differently: the hero spends the round escaping and only the enemy can hurt them in it, so fleeing can kill.

## Example story first
Write `site/examples/06-combat/the-evasion.{en,pt}.json`: a troll the reader can evade, losing a round of blows as they run; with low Stamina, running can kill. Check it plays well before writing the spec.

## The feature
`combat.fleeCost`: `"free"` (default: today's behaviour) or `"round"`. With `"round"`, fleeing first lets every living enemy strike, exactly as an item that costs the round does (B5: same strikes, same dice, same order of rolls in B8). Then, in this order: health at 0 is **death**; otherwise the flee page is entered. The strike does not lead to `wounded` (the player chose to leave) and does not count towards `rounds`. Only allowed with `flee`.

## Files
Spec B11 (and B8 if the order of rolls needs a line), changelog row 8, JSON Schema; `story.dart` (`Combat.fleeCost`, parse error without `flee`), gate; `engine.dart` `flee` (reuse the strike loop of `useItem`: move it into a helper both call). Cases: a costly flee that wounds and reaches the flee page, one that kills, one in `vs-defense` mode (the enemy rolls), one against several enemies, `invalid/flee-cost-needs-schema-8.json`, `invalid/flee-cost-without-flee.json`. Site: the Flee button is unchanged; log the strike (it already logs `CombatStrike`); maybe a word on the button ("Flee (costs a round)") with strings in both languages; tutorial in chapter 6 next to the poison sting; README; LLM kit.

## Done when
On the site the example's evasion costs a round of blows in both languages, and can kill; checks green.

## Handoff notes
- One commit, on the shared branch `steps-10a-10d`.
- `Combat.fleeCost` reuses the items' `CombatCost` enum. It stays null when the file has no `fleeCost` (the gate needs to know it was written). Parsing rejects it without `flee`, and any value but `round` or `free`.
- The strike loop of `useItem` moved into `GameEngine._strikes`, which both `useItem` and `flee` call: the current enemy, or every enemy still standing against several. `flee` does not call `_afterRound`, so the strike is no wound and no round; if it kills, the flee page is not entered.
- **B8 had no line for the dice of an enemy strike**, not even for items that cost a round. It now has one ("Enemy strikes"), covering both.
- Cases: `flee-costs-round`, `-kills`, `-vs-defense` (the enemy rolls 1d20 then 1d6), `-group`, and two invalid cases.
- Site: `CombatView.fleeCostsRound`, and the button reads "Flee (costs a round)" / "Fugir (custa uma rodada)". A VM test plays the example in both languages.
- Example `examples/06-combat/the-evasion` (a bridge troll; fleeing is a defeat, the troll's free blow can kill): the simulator gives 14% won, 62% fled, 23% dead, nothing stuck. Tutorial "Running costs a round" / "Fugir custa uma rodada" in chapter 6, and a "Try it" line.
