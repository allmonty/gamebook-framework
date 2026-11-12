# Step 05: Specify stuck pages and undo after death (docs + cases)

Two things the engine does today that the spec does not say. No engine change: write them down and pin them with cases.

## 1. A page with no open choice
A page whose choices are all gone (spent `once` choices, locked ones with `hideIfLocked`) or all locked leaves the player with nothing to tap. Confirmed: `engine.choices` is empty and `engine.ending` is null.

Write in B10: this is an author's mistake that no static check can always see, because it depends on what the player did. The game is **not** ended; the engine offers nothing; undo (if the story allows it) leads out. Tools should look for it: the Dart `simulate_story` tool reports such games as "stuck".

Case `conformance/cases/play/stuck-page.json`: a page whose only choice is `once` and leads back to the same page; after taking it expect `"choices": []` and `"ending": null`.

## 2. Undo after death
Confirmed: with `"undo": 1`, dying and then undoing returns to the page before, alive.

Write in B4 "Undo": going back is also allowed after the game ended (a death or an ending page); the game is then running again.

Case `conformance/cases/play/undo-after-death.json` (model: `undo.json`).

## Files
`spec/framework.md` (B4, B10), `spec/CHANGELOG.md` ("Clarified without a version change"), the two cases, the "Coverage" list in `conformance/README.md`, `spec/llm-kit.md` regenerated.

## Done when
Both cases pass on the unchanged engine; checks green.

## Handoff notes
(fill in)
