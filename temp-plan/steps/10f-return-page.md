# Step 10f: A page that returns to where the player came from (feature, schema 8)

Added 2026-11-12 at the owner's request (candidate 1, the one with the most evidence). Needs step 07.

## Problem
Printed books keep saying "visit the shop, then return to the section you came from" and "if a wandering monster appears, fight it, then turn back". Today every caller needs its own copy of the shop or the monster, because a page cannot lead "back".

## Example story first (before any spec)
Write `site/examples/02-pages-and-choices/the-pedlar.{en,pt}.json`: a pedlar who can be met from three different roads; buying from him and saying goodbye returns the reader to the road they came from. Add a wandering monster reached from a random table that, once beaten, returns the reader to where they were. Play it, then settle the open questions with the owner.

## The feature (proposed)
- A choice may have `"call": true` next to its `to`: entering the target remembers the current page as the place to return to.
- `"return": true` instead of `to` on a choice (and as the target of a fight's `win`, written `"win": { "return": true }`), leads back to the page last remembered, and forgets it.
- Calls nest: a stack saved with the game. Stories come from strangers, so its depth needs a bound (proposed 16); what happens beyond it is question 3.

## Open questions for the owner
1. Returning: is the page **entered again** (its effects apply unless `once`, the visit counts, every-page rules run) or only **shown again** without entering? Proposed: entered again, like any page, so the rules stay simple; authors use `once` for one-time effects.
2. What happens to a `return` with nothing remembered? Proposed: the choice is locked (never shown as usable) and the validator warns when a page with `return` can be reached without a call.
3. The depth limit, and what a call beyond it does: proposed, the oldest remembered page is forgotten, so the game never fails (a static check cannot always see the depth).
4. Does undo restore the stack? Proposed: yes, it is state.

## Files (once the questions are settled)
Spec B10 (choices, steps 3 to 4), B11 (`win`), B14 (saves), B16 (a new warning code), changelog row 8, JSON Schema; `story.dart` (choice and combat targets), gate; `state.dart` (`returnTo` list, saved); `engine.dart` (`choose`, fight win, `stateFits`); `validate.dart` and `graph.dart` (a return has no fixed target: reachability follows calls; draw return edges to every caller, dashed); `simulate.dart`. Cases for each rule above and invalid gate cases. Site: nothing new for the player; tutorial in chapter 2 with the example; README; LLM kit.

## Done when
On the site the pedlar returns the reader to each of the three roads, and the monster returns them where they were, in both languages; checks green.

## Handoff notes
(fill in)
