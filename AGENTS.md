# AGENTS.md

Guide for any AI (or human) working in this repo. Read it fully before changing anything.

## What this is
The **Gamebook Framework**: an open JSON format for gamebooks whose rules (stats, dice, combat) are data. The repo holds the spec, its JSON Schema, a conformance suite, the Dart reference engine with its tools, and the public website with a bilingual tutorial (`site/`).

The aim: the best gamebook format and engine, in a repository people and AIs can use and cite to build their games. What that means against other engines is in `spec/comparison.md` (section 8).

## Start here
| You want to... | Read |
|---|---|
| Know what to do next | `temp-plan/README.md` (status table), then its first step not done |
| Write or change a **story** for someone (not this repo) | `spec/llm-kit.md` and a starter from `starters/` to copy, then check with `validate_story --llm` until clean |
| Understand the story format | `spec/framework.md` (the spec; Part A plain words, Part B exact) |
| Know what other engines do and why this one exists | `spec/comparison.md` |
| Change the spec, conformance cases or an engine | `CONTRIBUTING.md`, `engines/README.md`, `conformance/README.md` |
| Work on the Dart engine | `engines/dart/README.md` |
| Work on the website or tutorial | `site/README.md` |
| Know why the site is built the way it is | `docs/adr/` |

## Plan protocol
Planned work lives in a plan folder with a `README.md` (why, decisions, status table) and one file per step in `steps/`. The current one is `temp-plan/`; it is deleted when its last step is done. Its README is the authority; in short:
1. Take the lowest-numbered step not marked done (or whatever the owner asks). Do only that step.
2. Set it to `in progress` in the plan's table.
3. Finish it: code, tests, docs listed in the step.
4. In the same commit as the work: fill the step's "Handoff notes" and mark it `done` in the table (the commit hash goes in with the next commit).
5. A step too big for one commit gets several commits; the last one marks it done.
6. Stuck or blocked: mark `blocked`, write why in the handoff notes, ask the owner.

A decision the plan records as the owner's is not reopened. A new idea goes to the owner, not into the step.

## Changing the format
The spec is the source of truth and versions only add. A change to what a story can say or how it plays touches all of these in one commit (details in `CONTRIBUTING.md`): `spec/framework.md` Part B, `spec/CHANGELOG.md`, `spec/story.schema.json`, conformance cases worked out **from the spec**, the Dart engine with its tests, a regenerated `spec/llm-kit.md`, and the feature list in `README.md`. A new feature also needs a `schema` bump and a gate that rejects it in older stories. A feature a player can see also reaches the site: player, strings in both languages, a tutorial section with an example.

## Architecture of `site/` (clean architecture, kept pragmatic)
Dependencies point inward only. A test (`site/test/layers_test.dart`) scans imports and fails on a violation.

| Layer | Folder | Holds | Must not import |
|---|---|---|---|
| Domain | `engines/dart` (`gamebook_engine`) | the format and the rules | anything from `site/` |
| Application | `site/lib/src/play/` | use cases (`PlaySession`, `EditSession`) and immutable view models | `package:web`, `dart:io`, `ui/`, `content/` |
| Presentation | `site/lib/src/ui/` | small DOM renderers that draw view models and forward clicks to use cases | engine internals beyond what the view models expose, `dart:io` |
| Content / build | `site/lib/src/content/` | templates, markdown, strings, example lookup | `package:web`, `ui/` |
| Entry points | `site/web/main.dart`, `site/tool/build.dart` | wiring only (composition root) | logic worth testing |

Why: the play logic is tested fast on the VM without a browser; the DOM code stays thin; the build is plain Dart. See `docs/adr/0003-site-layers.md`.

The engine (`engines/dart/lib/`) is pure: no I/O, no UI, randomness passed in.

## Clean-code rules
- Small, single-purpose functions and files. Names use the spec's vocabulary (node, choice, check, effect, stat, item, ending).
- Randomness and time are injected; tests seed or script the dice. No global mutable state.
- Text a visitor reads lives in `site/strings/{en,pt}.json` or the content Markdown, never hard-coded in Dart. English and Portuguese ship together.
- Abstractions only where there are two implementations or a test seam. No speculative interfaces, options or "for later" code.
- Immutable view models; the UI never mutates game state, it calls a use case and redraws.
- Every bug fix adds the test that fails without it. Comments say why, not what.
- Docs change in the same commit as the code they describe.
- A story file can come from a stranger (`.gamebook` packages): anything it can make the engine do must be bounded and checked when it is loaded.

## Working rules
- Small commits, one change each (feature, fix, refactor, test-only, docs). A bug found on the way gets its own commit.
- Each commit passes on its own: format, analyze (`--fatal-infos`), tests, for every package it touches.
- Commit message: short imperative summary, no prefix, then a body with what changed and why.
- Do not add a dependency for a few lines of code. No code generation (`build_runner`).
- Story text in examples and starters is original: no names or passages from published gamebooks (`spec/comparison.md` section 6).
- Ask the owner before anything outward-facing: pushing, pull requests, publishing, enabling Pages.

## Commands
```
# engine
(cd engines/dart && dart pub get && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test)
(cd engines/dart && dart run gamebook_engine:llm_kit --check)                 # the LLM kit is up to date
(cd engines/dart && dart run gamebook_engine:validate_story <dir|file>... --strict)
(cd engines/dart && dart run gamebook_engine:simulate_story <story.json>)     # no stuck or endless games
python3 tools/check_schema.py [story.json...]       # JSON Schema check; needs jsonschema. Where the system Python refuses pip:
                                                    # python3 -m venv .venv && .venv/bin/pip install jsonschema==4.23.0, then run it with .venv/bin/python

# site
(cd site && dart pub get && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test && dart test -p chrome test/browser)
(cd site && dart run tool/build.dart && python3 -m http.server -d build 8000)
```
