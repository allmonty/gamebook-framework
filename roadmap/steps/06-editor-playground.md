# Step 06: Editor and playground

## Scope
`EditSession`: text -> parse (format errors with JSON path) + `validateStory` issues -> new PlaySession; debounced. Editor renderer: monospace textarea, issue list, Reset. Embed = Play | Edit tabs (side by side on desktop). `play.html` page: blank or `?example=` preloaded, plus Download JSON.

## Files
site/lib/src/play/edit_session.dart, site/lib/src/ui/editor.dart, site/templates/play.html, strings

## Tests
VM tests: broken JSON, broken link, valid edit restarts the session.

## Done when
Editing an example and breaking a link shows the issue; Reset restores it.

## Handoff notes
- `play/edit_session.dart`: `EditSession(original, random)` with `update(text)`, `reset()`, `issues` (`IssueView`: error/warning, JSON path, message) and `play` (a fresh `PlaySession`, null while there are errors).
- `ui/lab_view.dart`: every embed is now a lab with Play and Edit JSON tabs (tabs on every width; the plan's side-by-side layout was dropped to keep content columns readable). Edits are checked after a 400 ms pause (`pause` is injectable for tests); Reset, Download, and on the playground Open file. Tab in the editor inserts two spaces; Shift+Tab leaves.
- `web/main.dart` pretty-prints the embedded JSON and enables Open file for embeds inside `.playground`.
- `build/<lang>/play.html` is the playground (template `templates/play.html`), linked from the header. It starts on The Rusty Door; step 07 may switch it to the showcase.
- Validator messages come from the engine in English, also on Portuguese pages.
- Bug found and fixed before commit: `display: grid` overrode `hidden`; `[hidden] { display: none !important }` is now global.
