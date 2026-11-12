# Gamebook frameworks and RPG rule systems: research

Written 2026-10-24, updated 2026-11-11 with two more rounds of research (new entries in section 2, rules checked at their sources in section 3, and section 8). Purpose: record what exists, what each option is good and bad at, and why we built our own data-driven JSON framework (see [framework.md](framework.md)). Nothing here is a legal opinion; check licenses yourself before shipping third-party content.

## 1. The question
We want one app that can play many kinds of gamebooks. A gamebook is a graph of pages. Each page has text and/or an image and some choices. Some choices need an item, a stat or a dice roll. So we need two things:

1. A **story format**: how pages, choices, items and conditions are written down.
2. A **rules system**: what stats a character has, what dice are rolled, how fights work.

Existing tools mostly solve (1). Almost none solve (2) in a reusable way, because rules are usually hand-coded per game.

## 2. Story tools and formats

### Ink (inkle)
A narrative scripting language. Stories are written in a plain-text markup, compiled to a JSON format, and run by a runtime. There is a pure-Dart runtime, [`ink_dart`](https://pub.dev/packages/ink_dart), and Flutter widgets on top of it, [`flutter_ink`](https://pub.dev/packages/flutter_ink). The compiled format is documented in the [ink JSON runtime format](https://github.com/inkle/ink/blob/b1d54e7444713a84770c2df1dbc6fdc83706d7aa/Documentation/ink_JSON_runtime_format.md).
- Pros: mature and battle-tested; variables, conditions, visit counts and functions; good writing experience (Inky editor); a Dart runtime exists.
- Cons: it is a story language, not a rules engine. It has variables and a built-in `RANDOM()` ([Writing with Ink](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md)), but stats, an inventory and combat are written by hand in each game. Authors must learn its syntax, and an AI or a script cannot easily generate valid graphs without the compiler. The compiler is a separate tool (C#/JS) outside our Dart toolchain. `ink_dart` is a small community package: on 2026-11-11 [pub.dev](https://pub.dev/packages/ink_dart) showed version 0.1.2, MIT, published a month earlier, for ink 1.2, with about 100 downloads.
- Verdict: great for prose-heavy interactive fiction. Poor fit for "same engine, different rulesets as data".

### Twine
A visual editor for hypertext stories, with output "story formats": [Harlowe, SugarCube and Chapbook](https://twinery.org/cookbook/introduction/story_formats.html) (plus Snowman). Harlowe and Chapbook aim at beginners; SugarCube has the largest feature set and a built-in save system ([community comparison](https://intfiction.org/t/twine-story-format-differences/72242)).
- Pros: very friendly visual authoring, the graph is drawn for you, large community.
- Cons: the product is an HTML+JavaScript page, not a data file. Logic is written as macros in each format's own syntax. Running it in Flutter means a WebView, which breaks native feel, accessibility and our own save/inventory UI. Importing the Twine archive and re-implementing macros is a large, lossy job.
- Verdict: useful as an authoring inspiration (the story map). Not a runtime for us. The Dart engine now imports simple Twine stories (`import_twine`, Twee 3 or a published Twine 2 file) and reports what it could not convert.
- Licenses, read in each repository on 2026-11-11: Chapbook is [MIT](https://github.com/klembot/chapbook/blob/main/LICENSE); SugarCube is a [two-clause BSD license](https://github.com/tmedwards/sugarcube-2/blob/master/LICENSE). Harlowe's repository refused our request; forum posts describe a custom permissive license. Not checked.

### ChoiceScript (Choice of Games)
A text-based scripting language for choice-driven games with variables and stats.
- Pros: designed for stat-driven interactive fiction; established authors and audience; random numbers with `*rand`; ships two automatic testers, Quicktest (every option and both sides of every `*if`) and Randomtest (plays the game over and over at random) ([its testing guide](https://www.choiceofgames.com/make-your-own-games/testing-choicescript-games-automatically/), read on 2026-11-12).
- Cons: not open source. The interpreter is under a free non-commercial license; commercial use needs a license or a contract ([forum discussion](https://forum.choiceofgames.com/t/cog-contract-if-i-want-to-do-self-publish/36657), [another thread](https://forum.choiceofgames.com/t/question-regarding-intellectual-property-and-publishing-with-choicescript/107189)). A forum post quotes a 25% revenue fee and a USD 20,000 first-year minimum; that figure may be outdated, so confirm with the company. Also JavaScript-based, so same WebView problem as Twine.
- Verdict: ruled out for licensing and runtime reasons.

### egamebook (Filip Hracek)
A Dart monorepo for "egamebooks", with one game, *Insignificant Little Vermin* (a procedural sword and sorcery adventure). BSD-3-Clause ([repository](https://github.com/filiph/egamebook)).
- Pros: pure Dart, rich simulated combat, built by someone who shipped a game with it.
- Cons: a story is **Dart code plus text files**; the documented way to make your own is to copy the example game's folder and change its code. There is no data format, so nothing can be checked, generated or played by another engine.
- Verdict: prior art for a Dart engine, not a format.

### Gamebook Engine (Brad Root)
An iOS app (Swift, MPL-2.0) to write and play gamebooks, with a web player ([repository](https://github.com/amiantos/gamebookengine), [wiki](https://github.com/amiantos/gamebookengine/wiki)). The closest project to ours in spirit.
- Model: a **Page** offers **Decisions**; **Rules** that test the player's **Attributes** decide which Decisions show; **Consequences** change Attributes. Stories export to `.gbook`, which is plain JSON. An analyzer warns about unreachable pages and dead ends. The web player has undo.
- Cons for us: attributes are the only mechanic. Its wiki says they "are the only way to track changeable player data"; a [Rule](https://github.com/amiantos/gamebookengine/wiki/Rule) compares one attribute with a number (`==`, `!=`, `>`, `<`) and a [Consequence](https://github.com/amiantos/gamebookengine/wiki/Consequence) sets, adds, subtracts or multiplies one. No dice or other randomness, no inventory, no combat. The format is whatever the app writes: no spec, schema, versions or tests for a second implementation.
- Verdict: confirms the bet on JSON and on a static analyzer. We go further on rules.

### GoDungeon
A hosted web player and visual builder in early alpha ([announcement](https://intfiction.org/t/godungeon-a-web-engine-to-create-and-read-digital-interactive-story-with-incorporate-dice-rolls-and-inventory/78750)): d20 checks on choices, stats rolled at the start, items that unlock choices. Its goal is ours: "the computer handles stats, dice and inventory".
- Cons for us: an account is needed to write; no combat, file format or license is described, so stories live on its servers.
- Verdict: shows the demand. Player feedback there is worth keeping: animate the dice, show pictures of items, make choices large on big screens.

### Tools for printed gamebooks
[gamebookformat and its successor pangamebook](https://mcdemarco.net/tools/hyperfic/software.html) (a Pandoc filter) turn marked-up text into a book of **numbered, shuffled sections**. LibroGameCreator (Java) exports ePUB, RTF, ChoiceScript and Squiffy. GBAT is commercial and Windows-only.
- They solve the opposite half: the book, with the reader doing the rules by hand.
- Verdict: an export from our format to a numbered book is possible later, because our stories are data (section 8).

### Small open-source gamebook engines with a JSON format
Found on 2026-11-11; each is one author's project with a handful of stars. None has a specification, versions or a test suite another engine could run.
- [fighting-fantasy](https://github.com/simonpainter/fighting-fantasy) (Python, MIT): the nearest in rules. Adventures are JSON, numbered sections with `exits` and `monsters`, plus a fixed list of built-in mechanics: `test_luck`, `test_stamina`, `dice_roll`, `dice_table`, `pre_combat_luck`, `random_encounter`, `fight`/`return` sub-sections, `key_sum`, `item_check`, `gold_check`. It counts gold and provisions and checks adventure files in its own unit tests. The rules are Fighting Fantasy's, in code: a different rule set means changing the engine.
- [rs-gamebook-engine](https://github.com/vtombesi/rs-gamebook-engine) (Rust, MIT): pages, options, fights and loot from a JSON file; items have types, quantities and effects.
- [GladStoriesEngine](https://github.com/gladimdim/GladStoriesEngine) (Dart on pub.dev, MIT): a JSON story format **with a JSON Schema**, but by design "only basic features": pages, choices, pictures, and an alive or dead ending.
- [gamebook-api](https://github.com/alexbernardi360/gamebook-api) (Node.js, MIT): converts a LibroGame Creator 3 book to JSON and validates it against a JSON Schema.
- [gamebook.js](https://github.com/cjauvin/gamebook.js): plays Lone Wolf book 2 from Project Aon's text with a typed-command parser; the book's special rules are hand-written code beside the data.
- [fantasy-gamebook-engine](https://github.com/rc-ventura/fantasy-gamebook-engine) (Python): an AI assistant narrates a Fighting Fantasy-style adventure while a tool server (MCP) owns the dice, the character and the fights, so the AI "never invents numbers". A new idea worth keeping (section 8).
- Verdict: the idea of a JSON gamebook keeps being reinvented, each time with one rule set fixed in code. That is the case for a shared format with rules as data and a suite that proves an engine right.

### Others checked
Squiffy, Dendry, Undum, Yarn Spinner and inklewriter are branching-text or dialogue tools like Ink and Twine: no dice, stats, inventory or combat built in ([IFWiki list](https://ifwiki.org/Authoring_systems_for_choice-based_IF)).

### Plain JSON graph (our choice)
Write the graph directly as data: nodes, choices, conditions, effects, checks.
- Pros: trivial to parse in Dart and to validate statically (broken links, unreachable pages, missing items); easy for people, scripts and AI to generate; rules can be part of the data; no external runtime or compiler; translations are just more files.
- Cons: we build and maintain the engine, validator and authoring tooling; raw JSON is less pleasant to write than Ink for long prose (mitigated by the validator, the JSON Schema for editor help, the graph tool, the website's playground and the kit for chatbots, [llm-kit.md](llm-kit.md)); no visual editor in this repository.

## 3. Rules systems
All of these reduce to: **stats + a dice roll + a comparison**, optionally repeated in rounds. That is what our schema models (`roll`, `add`, `op`, `vs`, `combat.mode`).

### Fighting Fantasy (Puffin era)
- Stats: Skill (combat ability), Stamina (health), Luck (a dwindling stock). Starting values: Skill = 1 die + 6, Stamina = 2 dice + 12, Luck = 1 die + 6 ([example fan adventure](https://fighting-fantasy-fan-engine.sourceforge.io/curseof/curseofblackwoodmanor.pdf); consistent across several fan adventures, e.g. [this one](https://fighting-fantasy-fan-engine.sourceforge.io/Dragon/DRAGON.pdf)).
- Combat round: each side rolls 2 dice and adds Skill. Higher total wounds the other for 2 Stamina; equal totals mean no damage. Fight until one Stamina reaches 0.
- Test your Luck: roll 2 dice; success if the total is at most current Luck; Luck then drops by 1 either way. In a fight: lucky after wounding the creature takes 2 more Stamina from it, unlucky gives 1 back; when wounded, lucky restores 1 and unlucky costs 1 more. Found on 2026-11-11 in search results quoting the books' rules (*City of Thieves*); these are the defaults of `rules.combat.luck`.
- Escaping, where a page offers it, costs 2 Stamina (same sources). In our format: the fight's `flee` page with a `stat` effect.
- Provisions: the hero usually starts with 10; each restores 4 Stamina, never above the starting value, and never during a fight. In *The Warlock of Firetop Mountain* they may be eaten only where the text says; later books allow it at any time outside a fight. Source: search results on 2026-11-11 quoting the [Fighting Fantasy wiki](https://fightingfantasy.fandom.com/wiki/Provisions) and two play-through blogs (the wiki itself refused our request). This needs counted items (section 8).
- Some books add a stat of their own: *House of Hell* has a Fear score that rises by 1 to 3 at frightening events. In our format that is one more stat with a `limit`.
- Maps to our schema: `opposed` combat mode; a check with `roll: 2d6`, `add: none`, `op: lte`, `vs: luck`.
- Caveat: exact text varies by book; the sources above are fan adventures that restate the rules, not the official rulebooks.

### Lone Wolf (Joe Dever)
- Stats: Combat Skill and Endurance. Kai series: Combat Skill = random number + 10, Endurance = random number + 20 (New Order series: +25 and +30).
- Combat: Combat Ratio = your Combat Skill (with bonuses) minus the enemy's. Pick a number from the Random Number Table (a 10-sided die is an accepted substitute), look up Combat Ratio against the number in the Combat Results Table, which gives Endurance lost by both sides. Repeat until one reaches 0 ([Project Aon: Kai combat](https://www.projectaon.org/en/ReadersHandbook/KaiCombat), [example combat](https://www.projectaon.org/en/ReadersHandbook/ExampleCombat), [New Order combat](https://www.projectaon.org/en/ReadersHandbook/NewOrderCombat)).
- Extras: Disciplines (skills the player picks) and special items grant bonuses or unlock choices.
- Evading, read on 2026-11-11 in [book 1's combat rules](https://www.projectaon.org/en/xhtml/lw/01fftd/cmbtrulz.htm): only where the text allows it; the round is worked out as usual but only Lone Wolf loses Endurance, then he escapes. Our `flee` has no such round (section 8).
- Equipment, read on 2026-11-11 in [book 1's rules](https://www.projectaon.org/en/xhtml/lw/01fftd/equipmnt.htm): at most 2 weapons; a Backpack of at most 8 items, Meals included; Special Items carried apart; at most 50 Gold Crowns; told to eat without a Meal, lose 3 Endurance; fighting unarmed, -4 Combat Skill. [Disciplines](https://www.projectaon.org/en/xhtml/lw/01fftd/discplnz.htm): choose 5 of 10; Healing restores 1 Endurance for every section passed without a fight; Weaponskill gives +2 with one kind of weapon; Hunting removes the need for Meals.
- Maps to our schema: the Combat Results Table is `combat.mode: "table"` and choosing disciplines is `rules.creation.picks`; the gold maximum is a stat `limit`; the backpack is `rules.inventory.capacity`; Meals are a counted item (`stack`); a bonus that depends on which weapon is held is a rule bonus; healing on every page is a rule in `rules.everyPage`. Not expressible yet: a separate limit for weapons (section 8). We did not copy the table's values.

### d20 / D&D 5e
- Six ability scores; a modifier derived from each; a check is d20 + modifier (+ proficiency) against a Difficulty Class. Typical DCs: 5 very easy, 10 easy, 15 medium, 20 hard, 25 very hard, 30 nearly impossible. Advantage and disadvantage roll two d20 and keep the higher or lower ([SRD mirror](https://dnd-wiki.org/wiki/SRD5:Check); we did not check the official SRD).
- License, read on 2026-11-11 on the [publisher's SRD page](https://www.dndbeyond.com/srd): SRD 5.1 is under both OGL 1.0a and CC-BY-4.0; SRD 5.2 and later under CC-BY-4.0 only.
- Maps to our schema: stats with a modifier formula, a check with `roll: 1d20`, `add: <stat>`, `op: gte`, `vs: <DC>`. `vs-defense` combat mode (attack roll vs a defense number, then damage dice). Advantage is not in the format (section 8).
- d20-lite (our preset) takes this core and drops classes, levels, skills and spells.

### Percentile (Mythras / Basic Roleplaying)
Skill values 0-100; roll d100 and succeed if at or under the skill. Maps to `roll: 1d100`, `op: lte`, `vs: <skill>`. Needs no new engine feature. Not shipped as a preset ([overview of the differences with D&D](https://thedesignmechanism.com/blog/7-key-differences-between-dd-and-mythras/)).

### Dice pools (Forbidden Lands, etc.)
Roll N dice and count successes. Needs a new check type (`count`); not in the format (section 8).

## 4. Comparison

| Option | Dice/stats built in | Runs natively in Flutter | Easy to validate statically | Authoring | License risk | Fit |
|---|---|---|---|---|---|---|
| Ink | Not built in (variables and `RANDOM()`; the rest by hand) | Yes (`ink_dart`) | Partly (compiler) | Good (Inky) | Low | Medium |
| Twine formats | No (macros) | No (WebView) | No | Excellent (visual) | Low for Chapbook and SugarCube; Harlowe not checked | Low |
| ChoiceScript | Variables and `*rand`; no inventory or combat | No (JS) | Yes (Quicktest, Randomtest) | Good | High (commercial) | Low |
| egamebook | Yes, in code | Yes (Dart) | No (stories are code) | Dart programming | Low (BSD-3) | Low |
| Gamebook Engine (`.gbook`) | Numbers only, no dice | No (Swift, web player) | Partly (its analyzer) | Good (in the app) | Low (MPL-2.0) | Medium |
| GoDungeon | Dice, stats, items; no combat | No (hosted) | Unknown | Good (visual) | Unknown | Low |
| fighting-fantasy (Python) | Yes, one rule set in code | No (Python) | Partly (its tests) | Medium (JSON by hand) | Low (MIT) | Medium |
| **Own JSON + rules as data** | **Yes** | **Yes (pure Dart)** | **Yes (our validator)** | Medium (hand/AI, schema, graph tool) | Low (our own text; two presets are named after published games) | **High** |

## 5. Decision
Build our own JSON graph format with rules expressed as data, plus presets for Fighting Fantasy and d20-lite. Reasons: it is the only option where stats, dice, inventory and combat are first-class and a pure-Dart engine runs them with no external runtime. We pay for it by building the engine, validator and graph tool ourselves, and by having no visual editor here. The decision is cheap to revisit: the Twine importer exists, an Ink one could follow, and `combat.mode` and check types can grow. The second round of research (section 8) found nothing that changes it.

## 6. Content sources (for future games)
- **Project Aon** (Lone Wolf books, free to read online). Its [license](https://projectaon.org/en/Main/License) says that by viewing or downloading you agree **not to redistribute** the books or illustrations in any format, and the FAQ restricts use to personal enjoyment. So we **cannot bundle Lone Wolf text or art in an app**. Read the license text yourself before deciding anything.
- **Fighting Fantasy** books are commercial and copyrighted. Fan adventures exist but each has its own terms. Do not bundle without permission.
- **Original stories** written by the owner (or with AI help) are the safe default; the demo adventure is original.
- **D&D 5e SRD** text is the only mainstream RPG rules text with a permissive license, and we only borrow the mechanics (mechanics are not copyrightable, text is), so we do not need to copy any of it.

## 7. Not verified
- Harlowe's license (its repository refused our request).
- "Jumbo Grove", which an early search result described as a gamebook tool with a JSON-heavy markup: still nothing found, so we do not know that it exists.
- Lone Wolf's Combat Results Table values. Project Aon publishes [the table](https://www.projectaon.org/en/xhtml/lw/01fftd/crtable.htm) as two pictures (seen on 2026-11-12), which we did not transcribe.
- The official Fighting Fantasy rulebook wording: every rule here comes from fan adventures, a fan wiki or blogs that restate it. They agree with each other. The primary source is the rules section at the front of each book (for example *The Warlock of Firetop Mountain*, Jackson and Livingstone, Puffin, 1982); we have not had one in hand.
- The license and file format of GoDungeon.
- The licenses of gamebook.js and fantasy-gamebook-engine (none shown), and how active any of the small engines in section 2 is.
- The official D&D 5e SRD rules text (we used a wiki mirror; the license is now checked). The official text is the [SRD 5.1 PDF](https://media.dndbeyond.com/compendium-images/srd/5.1/SRD_CC_v5.1.pdf), listed on the publisher's SRD page on 2026-11-12; we have not compared the mirror with it.
- The maintenance state of `flutter_ink`.

## 8. Where we stand (2026-11-11)

### What only this project has
Among everything in section 2 (about twenty projects) we found no other project with:
- a **written specification** with versions, where each version only adds;
- a **conformance suite** with scripted dice, so a second engine in any language can prove it plays the same;
- **rules as data** with presets: opposed, vs-defense and results-table combat, luck, checks and random tables without code;
- a **strict validator with stable warning codes**, a random-play simulator, a JSON Schema and a kit that lets a chatbot write valid stories.

### What others have and we lack
| Seen in | What | For us |
|---|---|---|
| Fighting Fantasy, Lone Wolf | items you hold several of (Provisions, Meals, arrows) | done: counted items (`stack`, `count`, a cap) |
| Fighting Fantasy | "if it wounds you, turn to...", "if you win within N rounds" | done: fight events (`wounded`, `rounds`) |
| every book | endings that are neither victory nor death | done: a `defeat` ending |
| web accessibility practice | a text for each picture | done: `imageAlt`, `coverAlt` |
| Lone Wolf | at most 2 weapons next to an 8-item backpack | open: limits per kind of item |
| Lone Wolf | +2 with one weapon, -4 unarmed | done: rule bonuses (`rules.bonuses`) |
| Lone Wolf (Healing) | +1 Endurance on every page without a fight | done: rules on every page (`rules.everyPage`) |
| Lone Wolf | evading costs a round in which only the hero can be hurt | done: `fleeCost: "round"` |
| fighting-fantasy (Python), every printed book | "fight this, then return to the section you came from" | done: `call` and `return` |
| fantasy-gamebook-engine | an AI narrates while a tool server owns dice and state | open: the engine as a tool server for AI assistants; no format change |
| gamebookformat, pangamebook, LibroGameCreator | a printable book of numbered, shuffled sections | open: an export tool; needs no format change |
| Gamebook Engine | a dead-end analyzer | we have it by simulation (`simulate_story`), not statically; the simulated player never uses an item or undoes, so a page whose only way on needs one of those reads as stuck |
| GoDungeon, Twine | a visual builder | outside this repository (the Builder is a separate app) |
| d20 games | advantage and disadvantage; dice pools | open: new check kinds |

"Done" items are in version 1 of the format. "Open" items are candidates: each needs an author who wants it and a short story example before it is specified ([../CONTRIBUTING.md](../CONTRIBUTING.md)).

