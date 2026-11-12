# Format versions

A story says which version it needs in its `schema` field. Each version only adds; a story valid in one version is valid in every later one once its `schema` says so (framework.md B2). Engines say which versions they support.

| Version | Adds | Spec |
|---|---|---|
| 1 | Pages, choices, items, stats, conditions, effects, dice checks, combat (`opposed`, `vs-defense`), presets `fighting-fantasy` and `d20-lite` | B1-B12 |
| 2 | Usable items (`use`) | B5 |
| 3 | A limited pack: `rules.inventory`, item `capacity` (containers), the `takeAll` effect | B4, B5, B9 |
| 4 | Once-only choices, visit counts, random outcome tables, conditional page text, `{stat}` placeholders | B6, B7, B10 |
| 5 | Stat limits and quantities, item bonuses, character creation choices, combat extensions (several enemies, armor, luck in fights), the results-table combat mode and duels, undo, the journal, page audio | B4-B7, B9, B11 |
| 6 | Authoring fields: node `title`, `note`, `chapter` and `draft`; story `chapters` and `showTitles` | B13 |
| 7 | Achievements: story `achievements` and the `achieve` effect | B15 |
| 8 | Descriptions of pictures: node and item `imageAlt`, story `coverAlt`; the neutral ending `"ending": "defeat"` | B3, B5, B6 |

Not versioned with `schema`: game packages (`.gamebook`, B14), which can hold a story of any version, and the validator warnings with their codes (B16), which change no story.

Clarified without a version change: luck in a fight changes the wound left after armor, and in a fight against several enemies it changes the round's total wound once (B11). Dice notation has limits: at most 100 dice, 1000 faces, and 6 digits for a modifier or a plain integer (B8). Health at 0 is final: once it is 0, no further effect applies, so a later effect in the same list, a check's effects or the target page's effects cannot bring the hero back; checks and tables still roll and the target is still entered (B4, B9, B10). A stat with item bonuses is never below 0: a bonus of -20 at Luck 8 gives 0, not -12, and the stat itself keeps 8 (B5). A page with no open choice, no ending and no fight does not end the game: the engine offers nothing and undo leads out (B10). Undo is allowed after the game ended, which runs it again (B4).
