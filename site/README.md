# Gamebook Framework website

The public site: a home page that sells the framework, a bilingual (EN / PT-BR) tutorial whose examples you can edit and play, and a playground. It is a plain Dart package that plays stories with the reference engine (`../engines/dart`) compiled to JavaScript. Why Dart and how it is layered: `../docs/adr/`, `../AGENTS.md`.

## Build and preview
```
dart pub get
dart run tool/build.dart            # writes build/ (add --no-js to skip compiling the player)
python3 -m http.server -d build 8000
```
Open http://localhost:8000. `build/` is ignored by git.

Checks (all must pass before a commit):
```
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test                           # VM tests (application, content, wording)
dart test -p chrome test/browser    # DOM smoke tests (needs Chrome)
```
Headless Chrome cannot go below 500px wide, so check phone layouts in a real browser's device mode.

## Layout
| Path | What |
|---|---|
| `lib/src/play/` | application layer: play and edit sessions, view models (pure Dart) |
| `lib/src/ui/` | presentation layer: DOM renderers (`package:web`) |
| `lib/src/content/` | build-time content: templates, Markdown, example embeds, the site builder |
| `web/main.dart` | browser entry point (wiring only) |
| `tool/build.dart` | build entry point (wiring only) |
| `templates/` | `layout.html` wraps every page; one template per page; `root.html` picks the language |
| `strings/{en,pt}.json` | every visitor-facing text of templates; both files must have the same keys (tested) |
| `content/{en,pt}/` | tutorial chapters in Markdown |
| `examples/` | example stories, one file per language |
| `css/site.css`, `assets/` | copied as they are |

Strings whose key starts with `player.` are also sent to the browser (a JSON script `#gb-strings` in the layout) for the player's own text.

Templates use `{{key}}` placeholders, filled from the strings plus `lang`, `root` (relative path to the site root), `path` (the page path, the same in every language) and `otherLang`. A missing value fails the build.

## Adding a playable example to a chapter
1. Write `examples/<chapter>/<name>.en.json` and `<name>.pt.json`.
2. In the chapter's Markdown, on its own lines:
   ````
   ```gamebook
   examples/<chapter>/<name>
   ```
   ````
The same block works inside an HTML template. The build swaps the block for an embed carrying the story JSON of the page's language; the browser turns it into a player with an editor. Tests validate every example.

## How the player is put together
What you need to know before adding a feature to the player (collected from the handoff notes of the steps that built the site; the history is in git, pull request #2).
- **Use cases** live on `PlaySession` (`lib/src/play/play_session.dart`), which wraps the engine: `start`, `restart`, `choose`, `useItem`, `takeOffer`, `leaveOffer`, `fight`, `testLuck`, `flee`, `undo`. `view` returns a fresh immutable `PageView` each call; new data goes on the view models in `views.dart`.
- **Engine events** become log lines in `play/log.dart`: a `LogLine(key, args, tone)` worded from the string `player.log.<key>`. The `switch` over `GameEvent` is exhaustive, so a new engine event fails analysis there until it is handled.
- **Locked choices** carry structured `Requirement`s; `ui/wording.dart` words them from `player.*` strings (pure Dart, tested on the VM).
- **Character creation** is `HeroDraft` (`play/hero_draft.dart`). The creation screen shows only when the story has `rules.creation` or sets `rules.rerolls` itself; a story that only names a preset starts on its first page.
- **The editor** is `EditSession` (`play/edit_session.dart`); every embed is a lab with Play and Edit JSON tabs (`ui/lab_view.dart`). Edits are checked after a 400 ms pause, injectable in tests.
- **DOM**: build it only with `el()` and `onClick()` from `ui/dom.dart` (text through `textContent`, never `innerHTML`). `PlayerView` redraws everything after each action.
- **Pages**: `SiteBuilder` (`lib/src/content/site_builder.dart`) writes one page per template and one per chapter in `content/<lang>/*.md`, sorted by file name; chapters use the same file name in every language (tested). Add a page in `_buildLanguage`.
- **Examples** stay one folder deep (`examples/<chapter>/<name>.<lang>.json`): the schema check in CI globs that depth. Every one must be free of errors **and warnings**, so a chapter that teaches a mistake has the reader add it.
- **Portuguese examples** override the preset's stat labels (`rules.stats.<id>.label`): preset labels are English.
- **Checking examples by hand**: `validate_story` scans folders only for `story.<lang>.json`, so pass the files: `dart run gamebook_engine:validate_story ../../site/examples/*/*.json --strict` (from `engines/dart`).
- The site uses relative links only, so it works under the project path on GitHub Pages. `.github/workflows/pages.yml` deploys `build/` on a push to `main`, once the owner sets Settings > Pages > Source to "GitHub Actions".

## Known shortcuts
None blocks anything.
- No image or audio files ship with the examples, so the player's image and audio support is untested in the browser (the CLI validator requires media files to exist). If wanted: ship media under `examples/<chapter>/`, copy them in the build and resolve paths against the example's folder.
- The player marks checks in amber but does not show the roll and target before the tap (spec B10 "should"); chapter texts write it into the choice instead.
- Validator messages are the engine's English wording, also on Portuguese pages.
- Dropped on purpose: side-by-side play and edit on desktop (tabs everywhere instead), a light theme, editor syntax highlighting.
- On phones the header nav wraps under the brand.
- `"mode": "table"` for a whole story has no example of its own (the duel example shows the same table).

## Design: Arcane Cyberpunk Codex
Taken from the gamebook app's dark "Codex" theme and the owner's design export, which is not in the repository; what was decided is recorded here. Mood: an occult grimoire fused with a cyberware terminal; deep void backgrounds pierced by cyan plasma and molten amber.

Tokens (on `:root` in `css/site.css`):
| Token | Value | Use |
|---|---|---|
| `--canvas` | `#0B0E15` | page background |
| `--surface` / `--card` / `--elevated` | `#10131B` / `#181B23` / `#1E2330` | panels, cards, hover |
| `--line` / `--line-cyan` | `#1F2D45` / `#143B44` | hairline borders |
| `--cyan` | `#00F0FF` | primary: links, active states, dice values, focus |
| `--amber` | `#FFB300` | secondary: checks, items, warnings, card brackets |
| `--teal` | `#00E5A3` | success, item bonuses |
| `--crimson` | `#FF2A5F` | danger: combat, flee, death |
| `--text` / `--muted` | `#E0E2ED` / `#94A3B8` | body / secondary text |

Type: **Space Grotesk** headings (700, tight tracking), **Plus Jakarta Sans** prose (line-height 1.6), **JetBrains Mono** for labels, stats and dice (uppercase, wide tracking; class `.label`).

Signature pieces:
- Chamfered corners (`--chamfer` clip-path) on buttons and choice bars; choices prefixed with a cyan mono index `[01] //`.
- Cards with amber corner brackets (`.card`).
- Cyan bloom on focus and hover (`--glow`), soft ambient glow on active panels (`--glow-soft`).
- Faint full-page scanlines and a blurred, translucent sticky header.
- HUD stat pills: mono label in muted silver, value in cyan (amber when low, teal for bonuses).
- Checks and risky choices bordered amber; combat and flee bordered crimson.

Accessibility: dark only, contrast kept at AA for text, 44px touch targets, visible focus, `prefers-reduced-motion` turns animation off, mobile-first with 16px gutters and no horizontal scroll.
