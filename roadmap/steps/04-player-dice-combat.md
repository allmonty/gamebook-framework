# Step 04: Player: dice, combat, journal, undo, achievements

## Scope
Event log lines (rolls with dice shown, stat changes, items gained/lost, journal, achievements), checks and outcome tables, combat panel (enemies with health, target pick for several enemies, attack, flee, Test your Luck), journal list, undo button, music/sound events played through `<audio>` when files exist (ignored otherwise).

## Files
site/lib/src/play/, site/lib/src/ui/

## Tests
VM tests for event formatting and combat views with scripted dice.

## Done when
A two-enemy fight with flee and luck works in the browser.

## Handoff notes
- `play/log.dart` maps every engine event to a `LogLine(key, args, tone)`; the UI words it from `player.log.<key>`. The switch over `GameEvent` is exhaustive, so a new engine event fails analysis here until it is handled.
- `PlaySession` gained `fight({target})`, `testLuck`, `flee`, `undo`; the view gained `log` (last action only), `journal` (newest first), `achievements` (kept across restarts for the session), `audio` (`AudioCue`: music carried over pages, sounds of the last action), `canUndo`, `combat` (`CombatView` with `EnemyView`s). Choices are hidden during a fight.
- UI: `combat_panel.dart` (enemy rows with health meters; one Attack button, or one per living enemy when `pickTarget`; luck in amber; flee in crimson), `log_panel.dart` (telemetry list and the folding journal), `audio.dart` (`AudioOutput`, swallows missing files and blocked autoplay), Undo/Restart controls under the page.
- Usable items in a fight are used from the pack panel (it shows Use when `canUse` allows it in combat).
- Bug found and fixed before commit: a dangling `else` hid the Attack button in one-enemy fights; the browser test covers it.
