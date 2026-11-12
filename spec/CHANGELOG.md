# Format versions

For authors, the site explains versions in plain words, in English and Portuguese: [Format versions](https://allmonty.github.io/gamebook-framework/en/versions.html). This file is the exact record, for engine writers.

A story says which version of the format it is written for in its `schema` field (framework.md B2). Versions only add: a later version brings new fields and kinds, a story valid in one version is valid in every later one once its `schema` says so, and an engine rejects a story that uses something newer than its `schema`. Engines say which versions they support.

| Version | What it has | Spec |
|---|---|---|
| 1 | Everything in framework.md: pages and choices (conditions, once-only choices, calls and returns), effects, items (usable, bonuses, containers, countable with a stack and a cap), a limited pack with offers, stats (ceilings, limits, floors, hidden counters, quantities), dice checks and random tables, combat (opposed, vs-defense, results tables and duels, several enemies at once, armor, luck in fights, fight events, a flee that costs a round), character creation, rule bonuses and rules on every page, undo, the journal, achievements, page audio, conditional text and placeholders, page titles, notes, chapters and drafts, descriptions of pictures, victory, defeat and death endings | B1-B16 |

Version 1 has limits, so a story from a stranger cannot exhaust an engine: the size of dice (B8) and how deep conditions nest (B7).

The format went through eight working versions while it was built. They were merged into version 1 before anything was released, so no story or engine depends on them.

Not versioned with `schema`: game packages (`.gamebook`, B14), which can hold a story of any version, and the validator warnings with their codes (B16), which change no story.
