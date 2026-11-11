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
_(fill in when done: what was built, shortcuts taken, anything the next step must know)_
