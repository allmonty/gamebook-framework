# Plan: harden the framework, fill the gaps, open the front door

Temporary working plan, written 2026-11-11 after a review of the whole repo and a survey of other gamebook engines (recorded in `../spec/comparison.md`, sections 2, 3 and 8). Delete this folder when every step is done. Read `../AGENTS.md` first; it still rules.

## Why
The review found the framework solid (spec, JSON Schema, 112 conformance cases and the Dart engine agree; 575 engine tests green; the repo layout needs no moving) but not complete:

- **Five holes**, each confirmed by running the engine (steps 01 to 05).
- **One structural outlier**: `engines/dart/lib/story.dart`, 929 lines, a third of it the schema-version gate (step 06).
- **Four gaps against real gamebooks**, chosen by the owner, added together as **schema 8** (steps 07 to 10), joined at the checkpoint by six more (steps 10a to 10f). Before release, step 10g merged every schema version into version 1.
- **The repo is hard to pick up from outside** (steps 11 to 15): the kit for chatbots tells them to write schema 6 while the format is at 7; the presets exist only as Dart code and spec tables; every example lives under `site/`; nothing tells a person or an AI that arrives cold which of three jobs (write a story, build an app, write an engine) starts where; the site never says which schema version a feature needs.

## The goal
The owner's aim: **the better gamebook engine and format, in a repository that people and AIs can use and cite to build their games.**

The survey found no other project with a written spec, a conformance suite, rules as data and a strict validator (`../spec/comparison.md` section 8). That is the lead to keep. So the order of work is: first make what exists unbreakable (01 to 06), then close the gaps real books expose (07 to 10f), then make it easy to start from (11 to 15).

## Owner decisions (do not reopen)
- Fix all five holes.
- Health at 0 is final: no later effect can save the hero (step 02).
- Extract and dedupe the schema gate (step 06).
- Add image alt text, a neutral ending, fight events and counted items, all as schema 8.
- Every new feature shows up in the site tutorial, English and Portuguese, with a playable example.

## How to work
1. Take the lowest-numbered step below that is not `done`. Do only that step. Set it to `in progress` here.
2. Work on one branch per step, `step-NN-<name>`, cut from an up-to-date `main`. Push it and open its pull request only when the owner asks. Exception (owner, 2026-11-12): steps 10a to 10d share one branch and pull request (`steps-10a-10d`), and so do 10e and 10f (`steps-10e-10f`), each step still in its own commits.
3. One step is one commit unless the step says otherwise. Each commit passes on its own (see "Checks").
4. In the same commit: set the step to `done` here and fill its "Handoff notes" (what you did differently, what the next step should know). The commit hash goes into the table with the next commit.
5. Stuck: set `blocked`, write why in the handoff notes, ask the owner.
6. Commit message: short imperative summary, no prefix, then a body saying what changed and why.

| # | Step | Kind | Status | Commit |
|---|---|---|---|---|
| 01 | [Limit dice size](steps/01-dice-limits.md) | fix | done | a3f93aa |
| 02 | [Health at 0 is final](steps/02-death-is-final.md) | fix | done | 9eef2fa |
| 03 | [A bonus never takes a stat below 0](steps/03-bonus-floor.md) | fix | done | 3faeb48 |
| 04 | [A save with impossible numbers does not fit](steps/04-save-fits.md) | fix | done | 7a45bac |
| 05 | [Specify stuck pages and undo after death](steps/05-spec-open-points.md) | docs + cases | done | 7460561 |
| 06 | [Extract the schema gate](steps/06-schema-gate.md) | refactor | done | a450b69 |
| 07 | [Schema 8 and image alt text](steps/07-image-alt.md) | feature | done | c6533d9, fcc15ed |
| 07b | [A picture in an example](steps/07b-example-picture.md) | site | done | f015afc |
| 08 | [A neutral ending](steps/08-defeat-ending.md) | feature | done | 317c51c, 51be7d1 |
| 09 | [Fight events](steps/09-fight-events.md) | feature | done | b75ed5c, 06e5fe5 |
| 10 | [Counted items](steps/10-counted-items.md) | feature | done | 248705e, 6c11b7d |
| 10a | [A lower limit per stat](steps/10a-stat-min.md) | feature | done | b0f3f90 |
| 10b | [A bonus that depends on a condition](steps/10b-conditional-bonus.md) | feature | done | f2d6096 |
| 10c | [A flee that costs a round](steps/10c-flee-costs-round.md) | feature | done | 3858d96 |
| 10d | [Item counts in text, and a cap on a counted item](steps/10d-item-counts-in-text.md) | feature | done | a9a50fb |
| 10e | [Rules on every page](steps/10e-every-page-rules.md) | feature | done | 4f40b08 |
| 10f | [A page that returns to where the player came from](steps/10f-return-page.md) | feature | done | 253ce0c |
| 10g | [One schema version](steps/10g-one-schema.md) | format | done | 8dc37b0 |
| 11 | [The LLM kit names the newest schema](steps/11-llm-kit-schema.md) | fix | done (in 10g) | |
| 12 | [Presets as data](steps/12-presets-as-data.md) | docs + test | done | |
| 13 | [Starter games](steps/13-starters.md) | docs + test | todo | |
| 14 | [A front door for people and AIs](steps/14-front-door.md) | docs + site | todo | |
| 15 | [A versions page on the site](steps/15-site-versions.md) | docs + site | todo | |

Steps 01 to 06 and 11 are independent of each other; step 11 is tiny and may be done first. Steps 08 to 10f need step 07 (it opens schema 8) and are easier after step 06. Steps 12 to 15 come last so they describe schema 8; 14 links what 12 and 13 add, and 15 is the last of all.

**Checkpoint before step 11 (passed 2026-11-12).** The owner chose six more schema 8 features, now steps 10a to 10f: candidates 10, 4, 2, part of 9, 5 and 1, smallest first. Steps 10e and 10f have open questions to settle with the owner after writing their example story and before the spec. Candidates 3 and 8, and the rest of 9, wait for a later schema. 6 and 7 are tools, buildable at any time.

## Where things stood when the plan was written (2026-11-11)
The baseline every step starts from; if your first run of the checks differs, stop and find out why before changing anything.
- Engine: format and analyze clean, 575 tests pass, the LLM kit check passes.
- Site: format and analyze clean, 185 VM tests and 5 browser tests pass.
- JSON Schema check: 146 stories, 0 not matching.
- Already done in preparation: the finished site roadmap was retired (its lasting notes are in `../site/README.md`), `../AGENTS.md` points here, an unused `applyEffects` helper was removed from the engine, and `../spec/comparison.md` holds the research behind steps 07 to 14.

## What every spec change carries (from `../CONTRIBUTING.md`)
In the same commit:
- the text in `spec/framework.md` Part B, and Part A where a reader would notice; write plainly;
- a line in `spec/CHANGELOG.md` (fixes go under "Clarified without a version change");
- `spec/story.schema.json`;
- conformance cases under `conformance/cases/`, expected results worked out **from the spec**, not from the engine; one case, one idea; if the case format grows, `conformance/README.md` too (its tables and its "Coverage" list);
- the Dart engine and its unit tests (a bug fix adds the test that fails without it);
- `spec/llm-kit.md`, regenerated: `(cd engines/dart && dart run gamebook_engine:llm_kit)`; a test fails while it is stale;
- the feature list in `README.md`.

## What every feature (steps 07 to 10f) also carried
Since step 10g those features are all version 1, with no gate; a feature after the release needs a new version and a gate again (`CONTRIBUTING.md`). Steps 12 to 15 add no feature.
- A schema gate: a story below schema 8 that uses the feature is rejected with `needs "schema": 8` at the feature's JSON path, plus an `invalid/<feature>-needs-schema-8.json` case.
- The site: view model in `site/lib/src/play/`, renderer in `site/lib/src/ui/`, every visitor-facing word in `site/strings/en.json` **and** `pt.json` (never hard-coded in Dart).
- The tutorial: a section in `site/content/en/<chapter>.md` **and** `site/content/pt/<chapter>.md`, with an example pair `site/examples/<chapter>/<name>.en.json` and `.pt.json`. Copy how the neighbouring sections embed their examples. `site/test/examples_test.dart` requires both languages, no errors, no warnings, and matching structure.
- A site test that plays the example to show the feature working (as steps 08 to 10 did), `simulate_story` on the example with nothing stuck, a "Try it" line in the chapter, and a row in the chapter's summary table when it has one.

## Checks (run for every package the commit touches)
```
(cd engines/dart && dart pub get && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test)
(cd engines/dart && dart run gamebook_engine:llm_kit --check)
(cd site && dart pub get && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && dart test && dart test -p chrome test/browser && dart run tool/build.dart)
.venv/bin/python tools/check_schema.py site/examples/*/*.json
```
The last one uses the virtual environment at the repo root (`.venv/`, ignored by git) where `jsonschema` 4.23.0 is installed, the version CI uses. On another machine: `python3 -m venv .venv && .venv/bin/pip install jsonschema==4.23.0`.

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
1. **A page that returns to where the player came from** (now step 10f) (a shop, a wandering monster, "fight this, then go back"): seen in printed books and as `fight`/`return` in the Python fighting-fantasy engine. The request with the most evidence.
2. **A `flee` that costs a round** (now step 10c) (Lone Wolf: in the evading round only the hero can be hurt).
3. **Limits per kind of item** (Lone Wolf: 2 weapons next to an 8-item backpack).
4. **A bonus that depends on a condition** (now step 10b) (Lone Wolf: +2 with one weapon, -4 unarmed).
5. **Rules that apply on every page** (now step 10e) (Lone Wolf's Healing: +1 Endurance per page without a fight). The same mechanism gives two debuffs the owner wants, to design together: **a loss on every page** (poison: -1 Stamina per page until cured) and **a debuff that runs out on its own** (a curse that lasts 3 pages or 2 fight rounds, without the story removing it). Open questions: what counts as a page (a fight round? a page entered again?), how undo and saves keep the counter.
6. **Export to a printable book** of numbered, shuffled sections: a tool, no format change.
7. **The engine as a tool server (MCP) for AI assistants**: the assistant narrates and the engine owns dice and state. A tool, no format change; fits the goal of being usable by AIs.
8. **New check kinds**: advantage and disadvantage, dice pools.
9. Conditional effects, text emphasis, `{item}` counts in text, a total cap on a countable item (the last two are now step 10d).
10. **A lower limit per stat** (now step 10a) (say `"min": -5`), so a stat can be a signed modifier as in tabletop RPGs ("Might -1"). Today every stat, item bonuses included, stays at 0 or above (B4, B5; step 03), so a cursed item at -5 Might held at Might 2 gives 0, and in `1d20 + might` the last 3 points of penalty are lost. The default stays 0, so existing stories play the same. No story needs it yet.
11. **Rules that count fight rounds**, not only pages (the owner, 2026-11-12): "the hex lasts 2 rounds", "poison bites each round". Step 10e runs rules on pages only.

## Where things stand (2026-11-12, end of a session)
- Steps 01 to 10f are done and merged into `main`.
- Step 10g merged the eight schema versions into version 1 (and did step 11).
- **Next:** step 13, then 14 and 15, one branch and pull request each.
- After 10f: steps 11 to 15, back to one branch and pull request per step.

## Waiting on the owner (outward-facing, never do these unasked)
- Enable GitHub Pages (Settings > Pages > Source: "GitHub Actions"; the workflow is already there); step 14's addresses work only once it is on.
- Tag a release once the plan is done, so stories and engines can cite a fixed version (version 1 of the format).
- Decide whether to publish the Dart engine on pub.dev (`publish_to: none` today) and to submit the schema to SchemaStore for editor autocompletion.

## Left out on purpose
A second engine in another language. The suite is ready for one; it is a project of its own.
