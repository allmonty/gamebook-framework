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

## Owner decisions (2026-11-12, do not reopen)
1. The rules run on **every page entered**: the start page, and a page entered again.
2. A page is **calm** when it has no `combat`, however it was reached.
3. **Pages only**, no fight rounds (counting fight rounds is now a candidate after the plan).
4. A stat may be **hidden** from the stats bar: `"hidden": true` (schema 8). Placeholders and conditions still see it.
5. The rules run **before** the page's own effects: a counter set to 3 on a page lasts the next three pages, a fever caught on a page drains from the next one, and the page that cures it still drains once.

## Files
Spec B4 (rules), B10 step 4 (when the rules run, and that health at 0 stops them as any effect), changelog row 8, JSON Schema; `rules_spec.dart`, gate; `engine.dart` `_enter`; `validate.dart` (conditions and effects of the rules); `simulate.dart` needs nothing. Cases: healing on calm pages only, poison until a flag clears, a countdown with a conditional bonus, a rule that kills, order of several rules, invalid gate cases. Site: nothing new beyond the log lines it already writes; tutorial in chapter 7 with the example; README; LLM kit.

## Done when
On the site the fever drains Stamina page by page until cured, and the hex wears off after 3 pages, in both languages; checks green.

## Handoff notes
- One commit, on the shared branch `steps-10e-10f`, built on the owner's decisions above.
- `PageRule(effects, {condition, calm})` in `rules_spec.dart`, from `rules.everyPage` (`effects` required, `if` and `calm` optional). `GameEngine._enter` applies the rules right after recording the visit and **before** the page's effects. They go through `_applyEffects`, so health at 0 stops them like any effect, and a death on entry leaves the page's own effects unapplied.
- `StatSpec.hidden`/`StatRules.hidden`, merged with the preset like `min`. The site leaves hidden stats out of the stats bar and the creation panel; placeholders and conditions still see them.
- `Story.effectLists()` includes the rules' effects (path `rules.everyPage[i].effects`), so the gate and the validator's B16 summaries count them. The validator checks each rule's `if` and effects.
- The draft example changed in one way: the hex always wore off before the ditch, so it never mattered. Now the stones lead either to the healer (cured, and the hex runs out on the way) or straight to the ditch (jumping hexed). `examples/07-living-world/marsh-fever`: the simulator gives 78% out, 22% in the mud, nothing stuck. A site test checks each page's Stamina and Skill in both languages.
- Cases: `every-page-rule`, `-calm`, `-before-page`, `-countdown` (with a rule bonus), `-order`, `-kills`, and the gate cases for `everyPage` and `hidden`. Stamina is given with a ceiling of 24 there: a plain number would also be its ceiling under Fighting Fantasy.
- Tutorial "Rules on every page" / "Regras em toda página" in chapter 7, and a "Try it" line.
