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

Not versioned with `schema`: game packages (`.gamebook`, B14), which can hold a story of any version, and the validator warnings with their codes (B16), which change no story.

Clarified without a version change: luck in a fight changes the wound left after armor, and in a fight against several enemies it changes the round's total wound once (B11). Dice notation has limits: at most 100 dice, 1000 faces, and 6 digits for a modifier or a plain integer (B8).
