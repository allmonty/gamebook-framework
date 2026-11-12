# Step 10e: Rules on every page: healing, poison, debuffs that run out (feature, schema 8)

Added 2026-11-12 at the owner's request (candidate 5, with the two debuffs the owner asked for). Needs step 07; easier after 10a and 10b.

## Problem
Nothing happens "on every page". Lone Wolf's Healing gives +1 Endurance for each section without a fight; poison that drains 1 Stamina a page until cured cannot be written; and every penalty lasts until the story takes it away, so a curse cannot run out after 3 pages on its own.

## Example story first (before any spec)
Write `site/examples/07-living-world/marsh-fever.{en,pt}.json`: the hero catches a fever (-1 Stamina on every page until a healer cures it), and a hex that weakens them for 3 pages and then wears off on its own. Play it, then settle the open questions below with the owner. Do not write the spec before.

## The feature (proposed)
`rules.everyPage`: a list of `{ "if": <condition>, "effects": [ ... ], "calm": true }`. Each time a page is entered (B10 step 4, after the page's own `effects`), every rule whose condition holds applies its effects, in list order. `"calm": true` skips pages with a fight (Lone Wolf's Healing).

How the three cases are written with it:
- **Healing:** `{ "calm": true, "effects": [ { "stat": "endurance", "add": 1 } ] }`.
- **Poison:** `{ "if": { "flag": "fever" }, "effects": [ { "stat": "stamina", "add": -1 } ] }`; the healer clears the flag.
- **A debuff that runs out:** a counter stat `hex` set to 3; a rule `{ "if": { "stat": "hex", "gte": 1 }, "effects": [ { "stat": "hex", "add": -1 } ] }`; and the penalty as a conditional bonus from step 10b, `{ "if": { "stat": "hex", "gte": 1 }, "bonus": { "skill": -2 } }`. No new state: a counter is a stat.

## Open questions for the owner
1. Do every-page rules run on the start page, and on a page entered again (yes, proposed: "every page entered")?
2. A page entered by a fight's `win`/`flee`/`wounded`: "calm" or not? (Proposed: a page is calm when it has no `combat`, however it was reached.)
3. Should a rule be able to run on fight rounds too ("lasts 2 rounds")? Proposed: no, pages only; a later candidate if a story needs it.
4. A countdown written as a stat shows in the stats bar. Is that wanted, or should a stat be able to be hidden? (Possibly a small field `"hidden": true` on a stat.)

## Files (once the questions are settled)
Spec B4 (rules), B10 step 4 (when the rules run, and that health at 0 stops them as any effect), changelog row 8, JSON Schema; `rules_spec.dart`, gate; `engine.dart` `_enter`; `validate.dart` (conditions and effects of the rules); `simulate.dart` needs nothing. Cases: healing on calm pages only, poison until a flag clears, a countdown with a conditional bonus, a rule that kills, order of several rules, invalid gate cases. Site: nothing new beyond the log lines it already writes; tutorial in chapter 7 with the example; README; LLM kit.

## Done when
On the site the fever drains Stamina page by page until cured, and the hex wears off after 3 pages, in both languages; checks green.

## Handoff notes
(fill in)
