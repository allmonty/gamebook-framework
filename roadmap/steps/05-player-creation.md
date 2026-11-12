# Step 05: Player: character creation

## Scope
Before the first page: name the hero (if the story asks), show rolled stats with reroll (limit from rules), creation choices (pick N of a list).

## Files
site/lib/src/play/, site/lib/src/ui/

## Tests
VM tests: reroll limit, pick-N validation, creation effects reach the engine.

## Done when
The conformance creation stories start correctly.

## Handoff notes
- `play/hero_draft.dart`: `HeroDraft` (roll, `reroll`, `name`, `toggle(group, option)`, `ready`, `effects` in file order, `view` -> `CreationView`).
- `PlaySession.creation` is non-null while creating; `beginAdventure()` starts the game; `view` throws until then. `restart()` goes back through creation.
- Decision: the creation screen shows only when the story has `rules.creation` or sets `rules.rerolls` itself. Preset-only stories (most tutorial examples) start straight on the first page, though the presets allow 2 rerolls. Tutorial chapter 4 must set `rerolls` (or `creation`) to demonstrate rolling again.
- UI: `ui/creation_panel.dart`; typing the name updates the Begin button without redrawing (keeps focus).
