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
- `starters/blank/` (`blank`, English only), `starters/fighting-fantasy/` (`salt-mine`, *The Salt Mine*, English and Portuguese: Provisions with `stack`, a giant rat, an iron key behind a `lockedText` door, a Luck test over a crack, all three endings) and `starters/custom-rules/` (`night-archive`, *The Archive at Night*: no preset; Nerve is health, Wits drives a check and opposed combat). All text is original.
- Every story starts with `"$schema"` at the raw GitHub address the tutorial uses; step 14 may move it to the site's own address.
- `engines/dart/test/starters_test.dart`: per starter, English exists; each language parses, resolves its rules, and has no errors or warnings; other languages match English (`compareTranslations`); 300 random games with no stuck or endless one and every ending reached; `packFolder` packs it with nothing skipped. Breaking a starter fails it, which I checked by hand and put back.
- `starters/README.md` has the four commands, checked on the real folders. CI's `schema` job and the plan's check line include `starters/*/*.json`. The main README's map lists the folder.
- Simulator on 1000 games: blank 100% victory; the salt mine 20% victory, 75% defeat, 5% death; the archive 24% victory, 52% defeat, 24% death.
