# Plan: Gamebook Framework website + hands-on tutorial (built in Dart)

> Approved plan, copied verbatim on 2026-11-11. The step files in `steps/` are authoritative for scope and order; where they differ from this file, the step files win. Since approval: the engine on `main` supports schema 1-7 (achievements added), and the draft `TUTORIAL_AND_SITE_PLAN.md` never reached this branch, so step 20 only links the site.

## Context
The framework (spec + Dart reference engine + tools) has no public face. We want a static site that:
- **sells it**: features, why it beats Twine / Ink / ChoiceScript, and a **short but complete showcase gamebook** on the home page you can play and edit;
- **teaches every feature** of the spec to non-technical writers, EN + PT-BR, each lesson embedding **tiny gamebooks the reader can edit and replay on the spot**;
- runs stories with the **real engine and validator**; every example is validated in CI.

Look: "Arcane Cyberpunk Codex" from the gamebook app and the Stitch export in `temp-theme/stitch_cyberpunk_fantasy_gamebook_platform/`. Deployed by a GitHub Pages workflow.

Work style (owner's request): small steps, each with tests, short commits, docs updated as we go, and a **roadmap any AI can resume from**, plus `AGENTS.md` and `CLAUDE.md` for this repo — same conventions as `../gamebook` (`roadmap/README.md` status table + `roadmap/steps/NN-*.md` with handoff notes; `CLAUDE.md` is just `@AGENTS.md`; commit messages: short imperative summary, no prefix, body says what and why).

## Branch (found while exploring)
Local `main` is 7 commits ahead of this branch (pack_game, llm_kit…), and the app's framework submodule shows even newer engine tools (simulate_story, import_twine). Step 00: `git fetch`, branch `site` from up-to-date `origin/main`, cherry-pick the README features commit `3f3ee91`, drop the draft-plan commit (its content is superseded by `roadmap/`). The tutorial covers every schema version the engine on that `main` supports (check `spec/CHANGELOG.md` there; schema 6 authoring fields included if the engine parses them, else marked "coming").

## Why Dart
- The site imports `gamebook_engine` directly (`Story.parse`, `validateStory`, `GameEngine`, `Rules`): no JS bridge, no second engine, and the CI test that validates examples is the same code that plays them.
- Not Flutter web (multi-MB canvas, no real HTML text: bad SEO/accessibility on a selling page). Not Jaspr (a framework + build_runner for a few static pages and one widget; the app's AGENTS.md also bans code generation).
- So: a Dart package `site/`. A small build script renders templates + Markdown (`package:markdown`) into static pages; the player/editor is Dart on `package:web`, compiled with `dart compile js`.

## Design (Stitch `arcane_cyberpunk_codex/DESIGN.md` + `../gamebook/docs/design-system.md`)
- Tokens on `:root`: canvas `#0B0E15`, surface `#10131B`, card `#181B23`, elevated `#1E2330`, borders `#143B44` / `#1F2D45`, cyan `#00F0FF`, amber `#FFB300`, teal `#00E5A3`, crimson `#FF2A5F`, text `#E0E2ED`, muted `#94A3B8`.
- Fonts (Google Fonts): Space Grotesk (headings), Plus Jakarta Sans (prose), JetBrains Mono (labels, stats, code; uppercase tracked).
- Signature pieces: chamfered clip-path choice bars with `[01] //` index; HUD stat pills; amber `┌ ┐ └ ┘` card brackets; cyan bloom glow; faint scanlines; blurred sticky header; checks amber-bordered, combat/flee crimson. Player modelled on Stitch `interactive_story_reader_1` and `combat_encounter_1`.
- Plain CSS, dark only, mobile-first (16px gutters, no horizontal scroll), `prefers-reduced-motion`. Logo copied from `../gamebook/assets/icon.jpeg`. Design notes recorded in `site/README.md` so `temp-theme/` (never committed) can be deleted.

## Architecture
```
AGENTS.md, CLAUDE.md                  repo guide for AIs (CLAUDE.md = "@AGENTS.md")
roadmap/README.md                     status table + "what is left"
roadmap/00-site-plan.md               this plan, verbatim
roadmap/steps/NN-name.md              scope, files, tests, done-when, handoff notes
site/
  README.md                           how to build/preview, design tokens, how to add an example/chapter
  pubspec.yaml                        gamebook_engine (path: ../engines/dart), web, markdown; dev: test, lints
  lib/player.dart                     GameEngine → DOM: pages, choices + unmet reasons, stats HUD, pack + use,
                                      offers/swap, combat (targets, flee, luck), dice/event log, journal, undo,
                                      character creation (name, roll/reroll, creation choices)
  lib/editor.dart                     JSON textarea + live validateStory issues (debounced) + Reset → restarts player
  web/main.dart                       mounts editor+player on every `.gb-embed` and on the playground
  tool/build.dart                     templates + markdown → build/; inlines example JSON; compiles JS
  templates/, strings/{en,pt}.json, css/site.css, content/{en,pt}/*.md
  examples/<chapter>/<name>.{en,pt}.json
  test/
.github/workflows/pages.yml
```
### Layers (clean architecture, kept pragmatic)
Dependencies point inward only; checked by a test that scans imports.
| Layer | Folder | Knows | Never imports |
|---|---|---|---|
| Domain | `engines/dart` (`gamebook_engine`) | the format and rules | anything site |
| Application | `site/lib/src/play/` | use cases: `PlaySession` (start, choose, fight, flee, use, luck, offer, undo, create hero), `EditSession` (text → parse + issues → session); immutable view models (`PageView`, `ChoiceView`, `HudView`, `EventLine`) | `package:web`, `dart:io` |
| Presentation | `site/lib/src/ui/` | renders view models to DOM, forwards clicks to the use cases; one small renderer per component (choices, HUD, pack, combat, log, editor) | engine internals (only view models + session) |
| Content / build | `site/lib/src/content/` + `tool/build.dart` | templates, markdown, i18n strings, example lookup, writing `build/` | `package:web` |
| Entry points | `web/main.dart`, `tool/build.dart` | wiring only (composition root) | logic |

Clean-code rules (go into `AGENTS.md`): small single-purpose functions and files; names from the spec's vocabulary; randomness and clock injected (seeded in tests); no global mutable state; text shown to players lives in `strings/{en,pt}.json`, never in code; abstractions only where there are two implementations or a test seam (no speculative interfaces); `analysis_options.yaml` mirrors the engine's strict lints plus `--fatal-infos`; every bug fix adds its failing test.
Testing pyramid: application and content layers fully unit-tested on the VM; presentation smoke-tested with `dart test -p chrome` (render a story, click a choice, see the next page); examples and showcase as data tests; manual browser pass per step.
Decisions recorded as short ADRs in `docs/adr/` (Dart over Flutter web/Jaspr; build-time markdown; layering) and linked from `AGENTS.md`.

Output: `build/{en,pt}/index.html`, `build/{en,pt}/tutorial/<nn>.html`, `build/{en,pt}/play.html`, `build/index.html` (language picker by `navigator.language`).

Embedding a playable example in a chapter:
````
```gamebook
examples/03-items/locked-door
```
````
The build swaps it for a `.gb-embed` with the story JSON inline (page's language). In the browser: **Play | Edit** (tabs on phone, side by side on desktop); edits re-validate and restart; issues show with their JSON path; Reset restores the original.

## Home page
1. Hero — "Write gamebooks. Play anywhere." + phone mockup running the showcase.
2. **Showcase "Escape from the Rune Vault"** (~15–20 pages): hero naming, creation choices, Fighting Fantasy preset, item with a stat bonus, usable potion, pack limit with swap offer, greyed choice with reason, skill check, Test your Luck, outcome table, two-enemy fight (armor, flee, luck in fights), once-only search, revisit text, flag, `{gold}` in text, journal, undo, victory and death. "Edit the source" toggle.
3. "Rules are data" — JSON ↔ what the player sees.
4. Feature grid linking to each tutorial chapter.
5. Comparison vs Ink / Twine / ChoiceScript from `spec/comparison.md` §4 (keep its honest wording).
6. Tooling — validator, graph, simulator, packages, Twine import, LLM kit, JSON Schema, conformance suite, other engines (whatever exists on main).
7. Footer — licenses (MIT code, CC-BY content), GitHub.

## Tutorial — every feature, tiny editable gamebooks (2–5 pages each)
| # | Chapter | Covers | Examples |
|---|---|---|---|
| 1 | Getting started | story file, JSON in 4 rules, required fields, the playground | hello-world |
| 2 | Pages & choices | text, images, endings, hidden vs greyed choices | two-doors, the-pit |
| 3 | Items | give/take/takeAll, `has`, usable items, bonuses, pack limit, offers & swaps, containers | locked-door, healing-potion, lucky-charm, full-pack, satchel, thief |
| 4 | Stats & your hero | custom stats, presets & overrides, max & quantities, creation (roll/reroll, name, choices) | custom-stats, d20-hero, pick-your-kit, merchant-price |
| 5 | Dice | notation, checks, vs a stat, effects after roll, Test your Luck, outcome tables | jump-the-gap, test-your-luck, search-the-rubble |
| 6 | Combat | opposed, vs-defense, flee, several enemies, armor, damage, luck in fights, results table & duel | goblin-guard, d20-duel, two-rats, armored-golem, results-table |
| 7 | A living world | `once`, visits, flags, all/any/not, conditional text, `{stat}`, journal, audio, undo | search-once, the-innkeeper, gold-counter, journal-clues, undo-the-trap |
| 8 | Check & publish | validator, graph, simulator, translations, `.gamebook` packages, Twine import, authoring fields, other engines | broken-on-purpose |
| — | Cookbook | locked chest, merchant, hidden passage, poison trap, boss fight | one each |
Field names come from `spec/framework.md` when writing each example. Audio is explained without an embed unless we ship small CC0 sounds.

## Steps (one roadmap file + one or a few commits each; every commit green)
| # | Step | Tests / checks |
|---|---|---|
| 00 | Branch from up-to-date main; `AGENTS.md` (incl. architecture + clean-code rules), `CLAUDE.md`, `roadmap/` (README, 00-site-plan, all step files), `docs/adr/` | — (docs) |
| 01 | Scaffold `site/` package with the layer folders, lints, build script, layout + css, empty home; `site/README.md` | build script test (renders a template, inlines a `gamebook` block); layer-import test |
| 02 | Player: pages, choices, stats, endings | pure-Dart view/formatting tests |
| 03 | Player: items, use, offers, containers | same |
| 04 | Player: dice, combat, journal, undo | same |
| 05 | Player: character creation | same |
| 06 | Editor + playground page | issue-formatting tests |
| 07 | Showcase story (EN + PT) | validates strict; seeded scripted playthrough reaches victory |
| 08 | Home page EN + PT | strings test: every key in both languages |
| 09 | CI job for `site/` (format, analyze, test, schema check on examples) | CI green |
| 10–17 | Tutorial chapters 1–8, one step each (EN + PT + examples) | examples test: parse, no errors/warnings, EN↔PT twins, every `gamebook` block resolves |
| 18 | Cookbook | same |
| 19 | Pages deploy workflow | workflow builds locally via `dart run tool/build.dart` |
| 20 | README links to the site; delete `TUTORIAL_AND_SITE_PLAN.md` | — |
Each step's commit also fills its handoff notes and marks it `done` in `roadmap/README.md`.

## Verification
- `cd site && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test`; engine checks stay green.
- `dart run tool/build.dart && python3 -m http.server -d build 8000`; in the browser at 390px and 1280px: play the showcase to victory and death; name a hero, pick a kit; fight two enemies, flee; use a potion; swap on a full pack; undo; edit an example (rename an item, break a link → issue shown, Reset); switch EN/PT; console clean.

Skipped: light/parchment theme, editor syntax highlighting (plain monospace textarea), hosting other than GitHub Pages.
