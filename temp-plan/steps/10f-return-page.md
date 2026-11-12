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

## Owner decisions (2026-11-12, do not reopen)
1. Returning **enters the page again**, like any page: its effects (unless `once`), a visit, the every-page rules.
2. A `return` with nothing remembered is **locked**, and the validator warns when that can happen.
3. Calls nest **16 deep** at most; a deeper call forgets the oldest remembered page, so the game never fails.
4. **Undo** restores what is remembered: it is state.
5. `"call": true` goes on a **choice**, and covers whatever target it leads to: `to`, a check's `pass` or `fail`, a table outcome's `to`.
6. `return` goes in place of `to` on a **choice** (`"return": true`), and as a fight's **`win`** and **`flee`** (`{ "return": true }`).

## Files
Spec B10 (choices, steps 3 to 4), B11 (`win`), B14 (saves), B16 (a new warning code), changelog row 8, JSON Schema; `story.dart` (choice and combat targets), gate; `state.dart` (`returnTo` list, saved); `engine.dart` (`choose`, fight win, `stateFits`); `validate.dart` and `graph.dart` (a return has no fixed target: reachability follows calls; draw return edges to every caller, dashed); `simulate.dart`. Cases for each rule above and invalid gate cases. Site: nothing new for the player; tutorial in chapter 2 with the example; README; LLM kit.

## Done when
On the site the pedlar returns the reader to each of the three roads, and the monster returns them where they were, in both languages; checks green.

## Handoff notes
(fill in)
