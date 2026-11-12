# Step 13: Starter games (docs + test)

Do after step 10g: the starters use version 1, with everything in it.

## Problem
Sixty example stories exist, all under `site/examples/` and named for tutorial chapters. None is laid out as a game folder (spec B1: `games/<slug>/story.<lang>.json`), so none can be handed to `validate_story` or `pack_game` as is. A person or an AI who wants to start a game has nothing to copy.

## Change
New top-level folder `starters/`, each starter a complete game folder that validates with `--strict` and packs:

| Folder | Shows |
|---|---|
| `starters/blank/` | the smallest valid game: one preset, three pages, one ending; `story.en.json` only |
| `starters/fighting-fantasy/` | the classic shape: a fight, a luck test, Provisions (counted items), a locked door, victory, death and defeat; `story.en.json` and `story.pt.json` |
| `starters/custom-rules/` | **no preset**: its own stats, health, a check and a fight, to show rules as data; `story.en.json` |

Each story starts with `"$schema"` pointing at the JSON Schema (the address step 14 settles; until then the raw GitHub address the tutorial already uses in `site/content/en/01-getting-started.md`).

- `starters/README.md`: three lines per starter and the four commands: validate, draw the map, simulate, pack.
- A test in `engines/dart/test/` (model: `site/test/examples_test.dart`): every starter parses, has no errors and no warnings, translations match, `simulate` finds no stuck or endless game, and `writePackage` accepts the folder.
- `.github/workflows/ci.yml`: add `starters/*/*.json` to the `schema` job's arguments.
- Text is original; no names or passages from published gamebooks (`spec/comparison.md` section 6).

## Done when
`dart run gamebook_engine:validate_story ../../starters/fighting-fantasy --strict` is clean, the test is green, CI checks the starters against the schema.

## Handoff notes
(fill in)
