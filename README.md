# Gamebook Framework

An open format for **gamebooks**: stories you play by reading a page, choosing what to do, collecting items and rolling dice against your stats. A story is one JSON file. Its **rules are data** inside the story (stats, dice, checks, combat), with presets for Fighting Fantasy and a d20-lite, so one engine plays many kinds of gamebook.

```json
{ "schema": 1, "id": "rusty-door", "lang": "en", "title": "The Rusty Door",
  "rules": { "preset": "fighting-fantasy" },
  "items": { "rusty-key": { "name": "Rusty key" } },
  "start": "cellar",
  "nodes": {
    "cellar": { "text": "You wake in a cold cellar.",
      "choices": [ { "text": "Search the shelves", "to": "shelves" }, { "text": "Go to the door", "to": "door" } ] },
    "shelves": { "text": "Behind a jar you find a rusty key.", "once": true,
      "effects": [ { "give": "rusty-key" } ], "choices": [ { "text": "Go back", "to": "cellar" } ] },
    "door": { "text": "The door is locked.",
      "choices": [
        { "text": "Unlock it", "to": "treasure", "if": { "has": "rusty-key" } },
        { "text": "Kick it open", "check": { "roll": "2d6", "add": "skill", "op": "gte", "vs": 15, "pass": "treasure", "fail": "door" } } ] },
    "treasure": { "text": "A chest of gold. You win!", "ending": "victory" }
  }
}
```

## Play it, learn it
The website plays stories in your browser with the reference engine, and every example can be edited and replayed on the spot (English and Portuguese):
- **[Home](https://allmonty.github.io/gamebook-framework/)**: a complete showcase gamebook, the features and the comparison.
- **[Writer's tutorial](https://allmonty.github.io/gamebook-framework/en/tutorial/index.html)**: eight short chapters and a cookbook, from your first page to fights, dice and translations. No programming needed.
- **[Playground](https://allmonty.github.io/gamebook-framework/en/play.html)**: write or open a story, check it and play it.

The site's source, and how to build it, is in [site/](site/README.md).

## Why another format
Ink and Twine are great for branching text, but have no stats, dice or inventory built in, and Twine's output is a web page rather than data. ChoiceScript has license limits. This format is plain, strict data that any language can parse, statically check (broken links, unreachable pages, items never given) and play the same way everywhere. The full comparison: [spec/comparison.md](spec/comparison.md).

---

## What you can do as a game writer

This section is for authors — no technical background needed. It explains everything the framework lets you put in your gamebook.

### 📖 Pages and choices

Every gamebook is a **collection of pages** (called *nodes*) connected by **choices**. Each page has text, an optional illustration (with a short description for players who cannot see it), and a list of buttons the player can tap to move forward.

- Write as many pages as you like, in any order.
- Each choice leads to another page.
- A choice can be **hidden** (the player never sees it) or **greyed out with a reason** ("Needs: Rusty key") until the right conditions are met.
- A choice can be marked **once**: after the player takes it, it disappears for the rest of the game — perfect for clues you can only follow once.
- **Conditional page text**: different paragraphs are shown or hidden depending on what the player has done or carries. The same page can read differently on a second visit.
- **Live numbers in text**: write `{gold}` or `{stamina}` anywhere in a page or choice label and the app fills in the player's current value.

---

### 🎒 Inventory and items

- Define any number of **items** (keys, potions, weapons, tools…). Each has a name, an optional description and an optional image, which can be described for players who cannot see it.
- Items are **unique** by default: the player either holds one or they don't.
- Some items can be **counted**: ten Provisions, a quiver of arrows. Say how many fit in one pack slot (`stack`), give or take several at once, ask for "at least 2", and each one used is gone.
- Choices and pages can **give** items to the player or **take** them away.
- A choice can require the player to **hold a specific item** before it's available ("Unlock the door" stays locked until the rusty key is in the bag).

#### Usable items
Some items can be **actively used** by the player:
- A healing potion that restores health.
- A torch that reveals a hidden message.
- Each usable item says *when* it works: on a normal page, during a fight, or both.
- Using an item consumes it automatically — no extra setup needed.
- During a fight, using an item that takes a full round means the monster attacks unchallenged for that round; some items are "free" and don't cost the player their turn.

#### Item bonuses
- An item can give **passive bonuses** while carried: a sword that adds +1 to Skill, a cursed ring that lowers Luck. The bonus is applied automatically everywhere — in checks, combat and displayed stats.

#### Carrying limits and containers
- Optionally, set a **pack capacity**: the player can only carry *N* items at a time.
- When something new is found, the player can be asked to **choose** whether to take it (and swap it for something else if the pack is full), or the item is simply refused with a message.
- Special items can be **containers** (a backpack, a satchel) that add extra carrying slots and don't use a slot themselves.
- Events in the story can remove *everything* from the player's pack at once — a thief, a flood, a magical trap.

---

### 📊 Stats and character

Stats are numbers that describe the hero — things like Skill, Stamina, Luck, Gold, or anything you invent.

- **Define any stats** you need with custom names and labels (translated per story file).
- Each stat is **rolled at the start** using dice notation, or given a fixed starting value.
- Stats can have a **ceiling**: health that can't go above what it started at; gold that can never exceed 50.
- Effects throughout the story can **raise or lower** any stat, or **set it to a specific value**.
- A stat can be set to a **dynamic value** ("pay the price stored in another stat"), so prices and costs can be part of the story data.

#### Character creation
Before the adventure begins, you can let the player:
- **Name their hero** (the name then appears in page text with `{name}`).
- **Roll their stats** and optionally re-roll up to a set number of times before accepting.
- **Pick starting equipment or skills** — for example, "choose two pieces of kit" from a list of options you define, each with its own effects (give items, set stats, raise flags).

#### Ready-made rule sets (presets)
Two presets are built in so you don't have to configure everything from scratch:

| Preset | Style | Stats |
|---|---|---|
| `fighting-fantasy` | Classic Fighting Fantasy | Skill, Stamina, Luck |
| `d20-lite` | Tabletop RPG (d20) | Might, Agility, Wits, HP |

You can use a preset as-is, or override any part of it (rename a stat, change the dice, adjust starting values).

---

### 🎲 Dice and skill checks

- Any choice can trigger a **dice roll**: "roll 2d6, add your Skill, and if the total is 8 or more you succeed."
- On success the player goes to one page; on failure, to another.
- The **target number** can be a fixed value or the current value of any stat (e.g., "roll against your Luck").
- Dice notation is flexible: `1d6`, `2d6+6`, `1d20`, `2d6-1`, or even a fixed number.
- The dice roll is **shown to the player** so it feels like rolling at the table.
- A check can apply **effects after the roll** (regardless of success or failure) — this is how "Test your Luck" works in Fighting Fantasy: the roll happens, then Luck drops by 1 either way.

#### Random outcome tables
Instead of a simple pass/fail, a choice can roll a die and send the player to **one of several outcomes** depending on the result. Example: "Search the rubble — roll 1d6: on 1–2 nothing, on 3–5 you find coins, on 6 you find a gem." Each outcome can also apply effects before moving on.

---

### ⚔️ Combat

Pages can be **fight scenes**. The player taps a button to fight round by round.

- Define one or more **enemies**, each with a name, attack score and health.
- Two combat modes built in: **opposed** (Fighting Fantasy style — both sides roll, highest total wins) and **vs-defense** (d20 style — attacker rolls against the defender's rating).
- If the player runs low on health they can **flee** to a page you specify (optional).
- When all enemies are defeated the story continues on the page you set as the win destination.

#### Advanced combat options
- **Enemy armor**: reduce the damage the player deals to a tough enemy by a set number.
- **Multiple enemies at once**: the player fights several enemies simultaneously, choosing a target each round.
- **Results table combat** (Lone Wolf style): instead of dice vs dice, a lookup table determines damage based on the difference in fighting scores.
- **Duel mode**: a special set-piece fight resolved by a results table, while every other fight in the game uses the normal mode.
- **Test your Luck in a fight**: after a round that hurt someone, the player may risk their Luck stat for a better (or worse) outcome on that round's wounds.
- **Custom damage per enemy**: override the default damage for a specific enemy.
- **Fight events**: leave a fight on the first wound ("if the creature wounds you, turn to…") or after a number of rounds ("if you have not won after three rounds…").

---

### 🗺️ Story structure and flow

- Pages can track **how many times** the player has visited them, and show different text or unlock different choices based on that count.
- **Flags** are simple on/off switches you can set anywhere and check anywhere — useful for "has the player met the innkeeper?" or "has the secret been revealed?".
- **Multiple endings**: mark any page as a `victory`, `defeat` or `death` ending. A defeat is an ending that is neither a win nor a death: captured, lost, gone home. The player's health hitting zero always triggers death automatically.
- **Undo**: let the player step back up to a set number of pages, with everything restored exactly as it was (stats, items, flags). Dice are rerolled if the same choice is taken again.

---

### 📓 Journal

A story can maintain a **journal** — a collection of unlockable entries the player accumulates over the course of the adventure.

- Define named entries (clues, lore, notes, maps…) anywhere in the story data.
- An effect anywhere in the story can **unlock** a journal entry. It unlocks only once.
- The app tells the player when a new entry is added ("Journal updated: A stranger's note").
- All unlocked entries are shown on the character screen, newest first.

---

### 🔊 Music and sound

Each page can play audio:
- **Background music** (`music`): starts when the page is entered and **keeps playing across pages** until another page changes it. Set `music: stop` to silence it.
- **Sound effects** (`sound`): a one-shot sound played when the page is entered.
- Players can toggle music and sound effects in the app settings independently; the story reads identically either way.
- The current music track is saved with the game and resumes when the player returns.

---

### 🌍 Multiple languages

- Each language is a **separate story file** (e.g. `story.en.json`, `story.pt.json`), sharing the same page structure and item/stat ids.
- Only the human-readable text changes between files — the app handles the rest.
- The app UI language is independent of the story language.

---

### 🛠️ Author tools

The framework includes tools to help you catch mistakes before anyone plays:

- **Validator**: checks for broken links (a choice that leads nowhere), unreachable pages, items that are used but never given, stat placeholders that don't exist, and more. Reports exact locations of errors.
- **Story map**: generates a visual diagram of your story — boxes are pages, arrows are choices. Dashed arrows are locked choices; dice-roll arrows split into success and failure branches.
- **Draft pages** (schema 6): mark a page as `draft: true` to save an unfinished story at any time. Draft pages are flagged as warnings by the validator and are not shown to players in release builds.

#### Authoring fields (for visual editors)
- Give pages a short **title** (shown on editor cards and in validator messages; optionally shown to players as a page heading).
- Add **author notes** to any page — private reminders that are never shown to players.
- Group pages into **chapters** for a clearer overview while writing.

---

### 📦 Publishing

Finished stories can be **packaged** into a single `.gamebook` file (a zip) that players can import into the app:

- Includes all language files, images and audio in one bundle.
- Importing a `.gamebook` whose id matches an existing imported game is treated as an **update** — saves are kept if they're still compatible, or the player is told the story changed.
- Bundled (official) games cannot be overwritten.

---

## What is here
| Path | What |
|---|---|
| [spec/framework.md](spec/framework.md) | **The spec.** Part A explains gamebooks and the format to anyone; Part B is the exact reference |
| [spec/CHANGELOG.md](spec/CHANGELOG.md) | what each `schema` version adds |
| [spec/story.schema.json](spec/story.schema.json) | JSON Schema (shape only) for editors and quick checks |
| [spec/llm-kit.md](spec/llm-kit.md) | **One file to give a chatbot** so it can write or change a story: instructions, common mistakes and the reference (generated) |
| [conformance/](conformance/README.md) | language-neutral test cases with scripted dice: the definition of "plays it right" |
| [engines/](engines/README.md) | engines; the reference one is [Dart](engines/dart/README.md) (with a validator and graph CLI) |
| [site/](site/README.md) | the website and the bilingual tutorial, built in Dart on the reference engine |
| [CONTRIBUTING.md](CONTRIBUTING.md) | how to change the spec or add an engine |
| [AGENTS.md](AGENTS.md) | how AI assistants (and people) work in this repo |

## Status
Schema versions 1 to 8 are specified. The Dart engine, which runs the gamebook app for iOS and Android (not public yet), implements all of them, and reads and writes `.gamebook` packages (B14).

## License
The spec text is [CC BY 4.0](LICENSE-CC-BY-4.0); code, the JSON Schema and the conformance cases are [MIT](LICENSE-MIT). Details: [LICENSE](LICENSE).
