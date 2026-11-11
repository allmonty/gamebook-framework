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
dart test
```

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

Templates use `{{key}}` placeholders, filled from the strings plus `lang`, `root` (relative path to the site root), `path` (the page path, the same in every language) and `otherLang`. A missing value fails the build.

## Adding a playable example to a chapter
1. Write `examples/<chapter>/<name>.en.json` and `<name>.pt.json`.
2. In the chapter's Markdown, on its own lines:
   ````
   ```gamebook
   examples/<chapter>/<name>
   ```
   ````
The build swaps the block for an embed carrying the story JSON of the page's language; the browser turns it into a player with an editor. Tests validate every example.

## Design: Arcane Cyberpunk Codex
Taken from the gamebook app (`../gamebook/docs/design-system.md`, dark "Codex" theme) and the owner's Google Stitch export (Arcane Cyberpunk Codex). Mood: an occult grimoire fused with a cyberware terminal; deep void backgrounds pierced by cyan plasma and molten amber.

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
