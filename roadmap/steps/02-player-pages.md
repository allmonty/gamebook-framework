# Step 02: Player: pages, choices, stats, endings

## Scope
`PlaySession` (start with injected Random, rolled stats, choose) and view models (`PageView`, `ChoiceView` with unmet reasons, `HudView`, ending). DOM renderers for page text, choices (`[01] //` chamfered bars; locked ones greyed with their reason), HUD pills, ending card with restart.

## Files
site/lib/src/play/, site/lib/src/ui/, site/web/main.dart

## Tests
VM tests on PlaySession with conformance-style stories and seeded/scripted Random; one browser smoke test (`dart test -p chrome`) that renders a story and clicks a choice.

## Done when
A tiny story plays to an ending in the browser.

## Handoff notes
- `PlaySession` (`site/lib/src/play/play_session.dart`) wraps `GameEngine`: `start`, `restart`, `choose`, and `view` (a fresh `PageView` each call). Add the next use cases (use item, offer, fight...) as methods here, and their data as fields on the view models in `views.dart`.
- Locked choices carry structured `Requirement`s; `ui/wording.dart` words them from `player.*` strings (pure Dart, VM-tested). Put every new player text in `strings/{en,pt}.json` under `player.`.
- `PlayerView` (`ui/player_view.dart`) redraws everything after each action and focuses the page (`aria-live`). Build DOM only with `el()`/`onClick()` from `ui/dom.dart` (text via textContent, never innerHTML).
- `web/main.dart` mounts a player on every `.gb-embed`. The home page has a temporary Rusty Door embed (`examples/home/rusty-door`), to become the "Rules are data" section in step 08.
- Engine events are ignored for now (step 04 shows them). Preset stat labels are English; Portuguese stories must override labels in `rules.stats`.
- Test helpers: `test/support/stories.dart` loads conformance stories or builds one inline.
