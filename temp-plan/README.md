# Plan: harden the framework, add schema 8, open the front door

Temporary working plan, written 2026-11-11 after a review of the whole repo and a survey of other gamebook engines (recorded in `../spec/comparison.md`, sections 2, 3 and 8). Delete this folder when every step is done. Read `../AGENTS.md` first; it still rules.

## Why
The review found the framework solid (spec, JSON Schema, 112 conformance cases and the Dart engine agree; 575 engine tests green; the repo layout needs no moving) but not complete:

- **Five holes**, each confirmed by running the engine (steps 01 to 05).
- **One structural outlier**: `engines/dart/lib/story.dart`, 929 lines, a third of it the schema-version gate (step 06).
- **Four gaps against real gamebooks**, chosen by the owner, added together as **schema 8** (steps 07 to 10).
- **The repo is hard to pick up from outside** (steps 11 to 14): the kit for chatbots tells them to write schema 6 while the format is at 7; the presets exist only as Dart code and spec tables; every example lives under `site/`; nothing tells a person or an AI that arrives cold which of three jobs (write a story, build an app, write an engine) starts where.

## The goal
The owner's aim: **the better gamebook engine and format, in a repository that people and AIs can use and cite to build their games.**

The survey found no other project with a written spec, a conformance suite, rules as data and a strict validator (`../spec/comparison.md` section 8). That is the lead to keep. So the order of work is: first make what exists unbreakable (01 to 06), then close the gaps real books expose (07 to 10), then make it easy to start from (11 to 14).

## Owner decisions (do not reopen)
- Fix all five holes.
- Health at 0 is final: no later effect can save the hero (step 02).
- Extract and dedupe the schema gate (step 06).
- Add image alt text, a neutral ending, fight events and counted items, all as schema 8.
- Every new feature shows up in the site tutorial, English and Portuguese, with a playable example.

## How to work
1. Take the lowest-numbered step below that is not `done`. Do only that step. Set it to `in progress` here.
2. Work on the branch `schema-8` (create it from `main` if missing). Never push, never open a pull request: ask the owner.
3. One step is one commit unless the step says otherwise. Each commit passes on its own (see "Checks").
4. In the same commit: set the step to `done` here and fill its "Handoff notes" (what you did differently, what the next step should know). The commit hash goes into the table with the next commit.
5. Stuck: set `blocked`, write why in the handoff notes, ask the owner.
6. Commit message: short imperative summary, no prefix, then a body saying what changed and why.

| # | Step | Kind | Status | Commit |
|---|---|---|---|---|
| 01 | [Limit dice size](steps/01-dice-limits.md) | fix | todo | |
| 02 | [Health at 0 is final](steps/02-death-is-final.md) | fix | todo | |
| 03 | [A bonus never takes a stat below 0](steps/03-bonus-floor.md) | fix | todo | |
| 04 | [A save with impossible numbers does not fit](steps/04-save-fits.md) | fix | todo | |
| 05 | [Specify stuck pages and undo after death](steps/05-spec-open-points.md) | docs + cases | todo | |
| 06 | [Extract the schema gate](steps/06-schema-gate.md) | refactor | todo | |
| 07 | [Schema 8 and image alt text](steps/07-image-alt.md) | feature | todo | |
| 08 | [A neutral ending](steps/08-defeat-ending.md) | feature | todo | |
| 09 | [Fight events](steps/09-fight-events.md) | feature | todo | |
| 10 | [Counted items](steps/10-counted-items.md) | feature | todo | |
| 11 | [The LLM kit names the newest schema](steps/11-llm-kit-schema.md) | fix | todo | |
| 12 | [Presets as data](steps/12-presets-as-data.md) | docs + test | todo | |
| 13 | [Starter games](steps/13-starters.md) | docs + test | todo | |
| 14 | [A front door for people and AIs](steps/14-front-door.md) | docs + site | todo | |

Steps 01 to 06 and 11 are independent of each other; step 11 is tiny and may be done first. Steps 08 to 10 need step 07 (it opens schema 8) and are easier after step 06. Steps 12 to 14 come last so they describe schema 8, and 14 links what 12 and 13 add.

## What every spec change carries (from `../CONTRIBUTING.md`)
In the same commit:
- the text in `spec/framework.md` Part B, and Part A where a reader would notice; write plainly;
- a line in `spec/CHANGELOG.md` (fixes go under "Clarified without a version change");
- `spec/story.schema.json`;
- conformance cases under `conformance/cases/`, expected results worked out **from the spec**, not from the engine; one case, one idea; if the case format grows, `conformance/README.md` too (its tables and its "Coverage" list);
- the Dart engine and its unit tests (a bug fix adds the test that fails without it);
- `spec/llm-kit.md`, regenerated: `(cd engines/dart && dart run gamebook_engine:llm_kit)`; a test fails while it is stale;
- the feature list in `README.md`.

## What every feature (steps 07 to 10) also carries
- A schema gate: a story below schema 8 that uses the feature is rejected with `needs "schema": 8` at the feature's JSON path, plus an `invalid/<feature>-needs-schema-8.json` case.
- The site: view model in `site/lib/src/play/`, renderer in `site/lib/src/ui/`, every visitor-facing word in `site/strings/en.json` **and** `pt.json` (never hard-coded in Dart).
- The tutorial: a section in `site/content/en/<chapter>.md` **and** `site/content/pt/<chapter>.md`, with an example pair `site/examples/<chapter>/<name>.en.json` and `.pt.json`. Copy how the neighbouring sections embed their examples. `site/test/examples_test.dart` requires both languages, no errors, no warnings, and matching structure.

## Checks (run for every package the commit touches)
```
(cd engines/dart && dart pub get && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test)
(cd engines/dart && dart run gamebook_engine:llm_kit --check)
(cd site && dart pub get && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test && dart test -p chrome test/browser && dart run tool/build.dart)
python3 tools/check_schema.py site/examples/*/*.json
```
The last one needs `pip install jsonschema`, which was not installed on the owner's machine at planning time: ask before installing; CI runs it anyway.

For a new example story also run `(cd engines/dart && dart run gamebook_engine:simulate_story <file>)` and expect no stuck and no endless games.

## Map of the code you will touch
| File | Holds |
|---|---|
| `engines/dart/lib/story.dart` | models and parser, `supportedSchemas`, the schema gate (until step 06), `Story.effectLists()` |
| `engines/dart/lib/engine.dart` | `GameEngine` (choose, fight, testLuck, useItem, flee, resolveOffer, undo), events, `stateFits` |
| `engines/dart/lib/state.dart` | `GameState`, `CombatState`, `StatValue` and their save JSON |
| `engines/dart/lib/combat.dart` | `fightRound`, `groupRound`, `enemyStrike`, `testFightLuck` |
| `engines/dart/lib/effect.dart`, `condition.dart`, `dice.dart` | effects, conditions (`evaluate`, `explain`), dice |
| `engines/dart/lib/validate.dart` | errors and B16 warnings, reachability |
| `engines/dart/lib/graph.dart`, `simulate.dart` | story map, random playthroughs |
| `engines/dart/test/conformance_test.dart` | the runner for `conformance/cases/` |
| `site/lib/src/play/play_session.dart`, `views.dart`, `log.dart` | use case and view models |
| `site/lib/src/ui/player_view.dart`, `pack_panel.dart`, `combat_panel.dart` | DOM renderers |

## Candidates after this plan (not steps)
From the survey (`../spec/comparison.md` section 8). Each needs the owner's yes and a short story example before it is specified. In the order the evidence suggests:
1. **Limits per kind of item** (Lone Wolf: 2 weapons next to an 8-item backpack) and whether each unit of a stack fills a slot (Lone Wolf counts every Meal; step 10 gives a stack one slot).
2. **A bonus that depends on a condition** (Lone Wolf: +2 with one weapon, -4 unarmed).
3. **Rules that apply on every page** (Lone Wolf's Healing: +1 Endurance per page without a fight).
4. **Export to a printable book** of numbered, shuffled sections: a tool, no format change.
5. **New check kinds**: advantage and disadvantage, dice pools.
6. "Return to the page you came from", conditional effects, text emphasis, `{item}` counts in text.

## Waiting on the owner (outward-facing, never do these unasked)
- Push the `schema-8` branch and open the pull request.
- Enable GitHub Pages (still pending from `../roadmap/README.md`); step 14's addresses work only once it is on.
- Tag a release when schema 8 is merged, so stories and engines can cite a fixed version.
- Decide whether to publish the Dart engine on pub.dev (`publish_to: none` today) and to submit the schema to SchemaStore for editor autocompletion.

## Left out on purpose
A second engine in another language. The suite is ready for one; it is a project of its own.
