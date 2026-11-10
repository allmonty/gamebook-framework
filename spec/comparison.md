# Gamebook frameworks and RPG rule systems: research

Written 2026-10-24. Purpose: record what exists, what each option is good and bad at, and why we built our own data-driven JSON framework (see [framework.md](framework.md)). Nothing here is a legal opinion; check licenses yourself before shipping third-party content.

## 1. The question
We want one app that can play many kinds of gamebooks. A gamebook is a graph of pages. Each page has text and/or an image and some choices. Some choices need an item, a stat or a dice roll. So we need two things:

1. A **story format**: how pages, choices, items and conditions are written down.
2. A **rules system**: what stats a character has, what dice are rolled, how fights work.

Existing tools mostly solve (1). Almost none solve (2) in a reusable way, because rules are usually hand-coded per game.

## 2. Story tools and formats

### Ink (inkle)
A narrative scripting language. Stories are written in a plain-text markup, compiled to a JSON format, and run by a runtime. There is a pure-Dart runtime, [`ink_dart`](https://pub.dev/packages/ink_dart), and Flutter widgets on top of it, [`flutter_ink`](https://pub.dev/packages/flutter_ink). The compiled format is documented in the [ink JSON runtime format](https://github.com/inkle/ink/blob/b1d54e7444713a84770c2df1dbc6fdc83706d7aa/Documentation/ink_JSON_runtime_format.md).
- Pros: mature and battle-tested; variables, conditions, visit counts and functions; good writing experience (Inky editor); a Dart runtime exists.
- Cons: it is a story language, not a rules engine. Dice, stats, inventory UI and combat would be hand-built on top of external functions. Authors must learn its syntax, and an AI or a script cannot easily generate valid graphs without the compiler. The compiler is a separate tool (C#/JS) outside our Dart toolchain. `ink_dart` is a small community package; check its maintenance before depending on it.
- Verdict: great for prose-heavy interactive fiction. Poor fit for "same engine, different rulesets as data".

### Twine
A visual editor for hypertext stories, with output "story formats": [Harlowe, SugarCube and Chapbook](https://twinery.org/cookbook/introduction/story_formats.html) (plus Snowman). Harlowe and Chapbook aim at beginners; SugarCube has the largest feature set and a built-in save system ([community comparison](https://intfiction.org/t/twine-story-format-differences/72242)).
- Pros: very friendly visual authoring, the graph is drawn for you, large community.
- Cons: the product is an HTML+JavaScript page, not a data file. Logic is written as macros in each format's own syntax. Running it in Flutter means a WebView, which breaks native feel, accessibility and our own save/inventory UI. Importing the Twine archive and re-implementing macros is a large, lossy job.
- Verdict: useful as an authoring inspiration (the story map). Not a runtime for us. A possible future importer for simple link-only stories.
- Not verified: the license of each story format. Check the repositories before reusing any code.

### ChoiceScript (Choice of Games)
A text-based scripting language for choice-driven games with variables and stats.
- Pros: designed for stat-driven interactive fiction; established authors and audience.
- Cons: not open source. The interpreter is under a free non-commercial license; commercial use needs a license or a contract ([forum discussion](https://forum.choiceofgames.com/t/cog-contract-if-i-want-to-do-self-publish/36657), [another thread](https://forum.choiceofgames.com/t/question-regarding-intellectual-property-and-publishing-with-choicescript/107189)). A forum post quotes a 25% revenue fee and a USD 20,000 first-year minimum; that figure may be outdated, so confirm with the company. Also JavaScript-based, so same WebView problem as Twine.
- Verdict: ruled out for licensing and runtime reasons.

### egamebook and other gamebook-specific engines
An older search result listed "egamebook" as a "sophisticated RPG engine in gamebook format" and "Jumbo Grove" with a JSON-heavy markup. **Not verified:** a follow-up search found nothing on either, so we do not know their status, license or fit. Treat as unexplored; check their repositories if we ever want prior art for a Dart-based engine.

### Plain JSON graph (our choice)
Write the graph directly as data: nodes, choices, conditions, effects, checks.
- Pros: trivial to parse in Dart and to validate statically (broken links, unreachable pages, missing items); easy for people, scripts and AI to generate; rules can be part of the data; no external runtime or compiler; translations are just more files.
- Cons: we build and maintain the engine, validator and authoring tooling; raw JSON is less pleasant to write than Ink for long prose (mitigated by the validator, the JSON Schema for editor help and the graph tool); no visual editor in v1.

## 3. Rules systems
All of these reduce to: **stats + a dice roll + a comparison**, optionally repeated in rounds. That is what our schema models (`roll`, `add`, `op`, `vs`, `combat.mode`).

### Fighting Fantasy (Puffin / Games Workshop era)
- Stats: Skill (combat ability), Stamina (health), Luck (a dwindling stock). Starting values: Skill = 1 die + 6, Stamina = 2 dice + 12, Luck = 1 die + 6 ([example fan adventure](https://fighting-fantasy-fan-engine.sourceforge.io/curseof/curseofblackwoodmanor.pdf); consistent across several fan adventures, e.g. [this one](https://fighting-fantasy-fan-engine.sourceforge.io/Dragon/DRAGON.pdf)).
- Combat round: each side rolls 2 dice and adds Skill. Higher total wounds the other for 2 Stamina; equal totals mean no damage. Fight until one Stamina reaches 0.
- Test your Luck: roll 2 dice; success if the total is at most current Luck; Luck then drops by 1. **This rule is from memory; the sources above only say Luck is spent to improve outcomes.** Our preset implements it as a `check` plus a stat effect.
- Maps to our schema: `opposed` combat mode; a check with `roll: 2d6`, `add: none`, `op: lte`, `vs: luck`.
- Caveat: exact text varies by book; the sources above are fan adventures that restate the rules, not the official rulebooks.

### Lone Wolf (Joe Dever)
- Stats: Combat Skill and Endurance. Kai series: Combat Skill = random number + 10, Endurance = random number + 20 (New Order series: +25 and +30).
- Combat: Combat Ratio = your Combat Skill (with bonuses) minus the enemy's. Pick a number from the Random Number Table (a 10-sided die is an accepted substitute), look up Combat Ratio against the number in the Combat Results Table, which gives Endurance lost by both sides. Repeat until one reaches 0 ([Project Aon: Kai combat](https://www.projectaon.org/en/ReadersHandbook/KaiCombat), [example combat](https://www.projectaon.org/en/ReadersHandbook/ExampleCombat), [New Order combat](https://www.projectaon.org/en/ReadersHandbook/NewOrderCombat)).
- Extras: Disciplines (skills the player picks) and special items grant bonuses or unlock choices.
- Maps to our schema: stats and items work today. Disciplines map to flags or items. The Combat Results Table needs a new `combat.mode` (`table`); it is **out of scope for v1** but `combat.mode` leaves room. We did not retrieve the table itself.

### d20 / D&D 5e
- Six ability scores; a modifier derived from each; a check is d20 + modifier (+ proficiency) against a Difficulty Class. Typical DCs: 5 very easy, 10 easy, 15 medium, 20 hard, 25 very hard, 30 nearly impossible. Advantage and disadvantage roll two d20 and keep the higher or lower ([SRD mirror](https://dnd-wiki.org/wiki/SRD5:Check); we did not check the official SRD).
- The 5.1 SRD is generally published under CC-BY 4.0; **verify** on the official page before copying any text.
- Maps to our schema: stats with a modifier formula, a check with `roll: 1d20`, `add: <stat>`, `op: gte`, `vs: <DC>`. `vs-defense` combat mode (attack roll vs a defense number, then damage dice). Advantage is out of scope for v1.
- d20-lite (our preset) takes this core and drops classes, levels, skills and spells.

### Percentile (Mythras / Basic Roleplaying)
Skill values 0-100; roll d100 and succeed if at or under the skill. Maps to `roll: 1d100`, `op: lte`, `vs: <skill>`. Needs no new engine feature. Not shipped as a preset in v1 ([overview of the differences with D&D](https://thedesignmechanism.com/blog/7-key-differences-between-dd-and-mythras/)).

### Dice pools (Forbidden Lands, etc.)
Roll N dice and count successes. Needs a new check type (`count`). Not in v1.

## 4. Comparison

| Option | Dice/stats built in | Runs natively in Flutter | Easy to validate statically | Authoring | License risk | Fit |
|---|---|---|---|---|---|---|
| Ink | No (external functions) | Yes (`ink_dart`) | Partly (compiler) | Good (Inky) | Low | Medium |
| Twine formats | No (macros) | No (WebView) | No | Excellent (visual) | Unverified | Low |
| ChoiceScript | Variables only | No (JS) | No | Good | High (commercial) | Low |
| egamebook | Claims RPG engine | Unverified | Unverified | Unverified | Unverified | Unknown |
| **Own JSON + rules as data** | **Yes** | **Yes (pure Dart)** | **Yes (our validator)** | Medium (hand/AI, schema, graph tool) | None | **High** |

## 5. Decision
Build our own JSON graph format with rules expressed as data, plus presets for Fighting Fantasy and d20-lite. Reasons: it is the only option where stats, dice, inventory and combat are first-class and a pure-Dart engine runs them with no external runtime. We pay for it by building the engine, validator and graph tool ourselves, and by having no visual editor in v1. The decision is cheap to revisit: a future importer can turn Ink or Twine content into our format, and `combat.mode` / check types can grow.

## 6. Content sources (for future games)
- **Project Aon** (Lone Wolf books, free to read online). Its [license](https://projectaon.org/en/Main/License) says that by viewing or downloading you agree **not to redistribute** the books or illustrations in any format, and the FAQ restricts use to personal enjoyment. So we **cannot bundle Lone Wolf text or art in an app**. Read the license text yourself before deciding anything.
- **Fighting Fantasy** books are commercial and copyrighted. Fan adventures exist but each has its own terms. Do not bundle without permission.
- **Original stories** written by the owner (or with AI help) are the safe default; the demo adventure is original.
- **D&D 5e SRD** text is the only mainstream RPG rules text with a permissive license, and we only borrow the mechanics (mechanics are not copyrightable, text is), so we do not need to copy any of it.

## 7. Not verified
- Licenses of Harlowe, SugarCube and Chapbook.
- Existence, status and license of egamebook and "Jumbo Grove".
- Lone Wolf's Combat Results Table values.
- The official Fighting Fantasy rulebook wording (we used fan adventures that restate it), and the exact Test your Luck rule (from memory).
- The official D&D 5e SRD text and license (we used a wiki mirror).
- The current maintenance state of `ink_dart` and `flutter_ink`.
