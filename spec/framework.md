# The gamebook framework

This is the definition of the gamebook story format and its rules. **Part A** is for everyone. **Part B** is the exact reference every engine is built against; if an engine and Part B disagree, that is a bug in one of them, and the fix starts here (see [../CONTRIBUTING.md](../CONTRIBUTING.md)). The [conformance tests](../conformance/README.md) check an engine against it.

Words: *the app* or *the player* means any program that plays stories; *the Builder* means a visual editor for them.

Why a new format instead of Ink, Twine or ChoiceScript: [comparison.md](comparison.md). Version history: [CHANGELOG.md](CHANGELOG.md).

---

# Part A. For everyone

## What is a gamebook?
A gamebook is a book you play. You read a short passage, then choose what to do: "If you open the door, go to page 12. If you walk away, go to page 30." Each page leads to other pages, so the book is really a **map of pages joined by choices**. Different choices lead to different adventures and different endings: you win, you die, or the adventure is simply over (captured, lost, gone home).

A gamebook app is the same thing on your phone: a **page** shows a picture and some text, and **buttons** are the choices. Tap one and you land on another page. A picture can come with a short description of what it shows, so a player who cannot see it (with a screen reader, say) still gets it.

## The five ingredients

| Ingredient | What it is | Example |
|---|---|---|
| **Page** (we call it a *node*) | One screen: a picture and/or text, then choices | "You stand before a rusty door." |
| **Choice** | A button on a page that leads somewhere | "Open the door" |
| **Item** | Something you carry in your inventory: one of a kind, or several | A rusty key; five meals |
| **Stats** | Numbers that describe your character | Skill 9, Stamina 18, Luck 8 |
| **Dice** | Random rolls that decide risky choices | "Roll two dice; you need 8 or less" |

### How items change the story
A choice can be **locked** until you have the right item or enough of a stat. "Unlock the door" stays greyed out, with a note saying "Needs: rusty key", until you pick the key up on another page. This is what makes you explore.

### A richer character
A story can let you **name your hero** and **pick a few things at the start** (two pieces of kit, three skills). Items you carry can **make you stronger** while you hold them: a sword that adds one to your Skill. Numbers can have a **ceiling of their own** (gold up to 50), and a choice can compare one number with another ("you have enough gold for the price"). Fights can have several enemies at once, enemies with armor, and a "Test your Luck" after a round. A game can allow you to **go back a page**, keeps a **journal** of clues you unlocked, and can play **music and sounds**.

### Pages that remember, and choices that go away
A page can change its text depending on what you did or how often you have been there ("The fire has burned lower since you first came in"), and can show your numbers ("You have 3 crowns"). A choice can be marked **once**: after you take it, it is gone, like a clue you have already followed. A choice can also roll a die and send you to one of several pages depending on the result ("roll a die: 1-2 nothing, 3-5 a coin, 6 a secret").

### Carrying limits
A story can limit how much you carry, say three items. Then finding something becomes a decision: take it or leave it, and if your pack is full, swap it for something you already carry. A bag or backpack can add room, and a thief can take it again (or a flood can wash everything away). A story can also keep the simple way: anything found is taken, with no limit. The author chooses per story. Some things come in numbers: five meals, a quiver of arrows. You carry several, they fill your pack a few to a slot, and each one you eat or shoot is gone.

### Using items
Some items can be **used**: a healing potion restores Stamina, and it is used up. Each item says where it works: on a normal page, during a fight, or both. During a fight, a **Use item** button opens your pack and lets you pick one of the items that work in a fight; the rest are shown greyed out. Some items take the whole round to use (the monster still attacks), others are free: the item decides.

### How dice change the story
Some choices are a gamble. "Pick the lock" asks the app to roll dice and add your Skill. Success sends you to one page; failure sends you to another. You see the dice roll on the screen, so it feels like rolling at a table.

### Fights
Some pages are fights. Each round, you and the monster both roll dice and add your fighting stat. The higher total wounds the other. When someone's health reaches zero the fight ends. If you run out of health, your adventure ends; if the monster does, the story goes on. A fight can also end another way, as the book says: "if the creature wounds you, turn to the next page", or "if you have not won after three rounds, it gets away".

### Different rule sets
Different gamebooks use different rules. One may have Skill, Stamina and Luck (the classic *Fighting Fantasy* style). Another may use a twenty-sided die, like a tabletop roleplaying game. **The rules are written down inside each story**, so the app is one engine that can play many kinds of gamebook. Authors can start from a ready-made rule set (a *preset*) and tweak it.

### Languages
Each story file is in **one** language. A story that exists in English and Portuguese is two files with the same pages in the same order. The app menus are translated separately.

## What an author writes
An author writes one text file per language that lists every page, its text, its choices and where each choice leads. They never write app code. A checker tool reads the file and reports mistakes before anyone plays: a choice that leads nowhere, a page you can never reach, an item that is used but never given.

There is also a tool that draws the **story map**: boxes are pages, arrows are choices. Dashed arrows are locked choices; arrows from a dice roll split into success and failure.

## Worked example: "The Rusty Door"
```
        [1 Cellar]
        /        \
 (take key)    (go to door)
    |             |
 [2 Key]      [3 Locked door] --needs key--> [4 Treasure room] --> [5 You win!]
    |             \
 back to 1       (kick it) --roll dice--> success: [4]   failure: [6 You hurt your foot]
                                                                         |
                                                                       back to 3
```
1. You wake in a cellar. Choices: *Search the shelves* (goes to page 2), *Go to the door* (page 3).
2. You find a rusty key. It goes into your inventory. Only choice: *Go back*.
3. A locked door. *Unlock it* is locked until you hold the key. *Kick it open* asks for a dice roll with your Skill.
4. The treasure room, and the story ends in victory.

The next section shows this same story in the file format.

---

# Part B. Technical reference

Schema version: **1**, with everything in this document. B2 says how later versions will be added. B16 lists the validator's warnings, which tools may report. Game packages (B14) are not a schema feature: any version can be packed.

## B1. Files and languages
- A game is a folder: `games/<slug>/`. Stories are `games/<slug>/story.<lang>.json` (`story.en.json`, `story.pt.json`). Images live in `games/<slug>/images/` and are referenced by a path relative to the folder.
- `<lang>` is a short language code. The file's `lang` field must equal it.
- Translations of one game share the same `id`. They must also share **identical node ids, item ids, stat ids, flag names, and, for each node, the same number of choices in the same order (and the same number of text parts)**. The validator checks this. Only human-readable strings differ.
- The app groups files by `id` and offers the languages that exist. App UI language is independent of story language.
- JSON only, UTF-8. No comments.

## B2. Strictness and versioning
- Unknown keys are **errors** (typo protection). Error messages name the JSON path, e.g. `nodes.door.choices[1].to`.
- `schema` is an integer: the version of the format the story is written for. There is one version so far, **1**. An engine accepts only versions it supports and rejects any other, so a story never half-works.
- Versions only add. When a new field or kind is added, it comes with a new version: a story that uses it must say that version, and an engine rejects a story that uses something newer than its `schema` (with `needs "schema": N` at the JSON path of the first such thing). A story written for one version stays valid in every later one once its `schema` says so. Old stories keep working; an old engine rejects what it does not know instead of misreading it.
- Saved games are not part of the format: each engine stores and versions its own, and must never fail on a save it does not understand (it reads as "no save").

## B3. Top level
| Field | Type | Req | Notes |
|---|---|---|---|
| `$schema` | string | no | path to `story.schema.json`, an editor hint the engine ignores |
| `schema` | int | yes | `1`, the version of the format (B2) |
| `journal` | object | no | map `entryId -> { title, text }` (B6) |
| `achievements` | object | no | map `achievementId -> { title, description, hidden }` (B15) |
| `chapters` | object | no | map `chapterId -> { title }`, in reading order (B13) |
| `showTitles` | bool | no | default false: show node titles to players as page headings (B13) |
| `id` | string | yes | slug, `[a-z0-9-]+`, shared by translations |
| `lang` | string | yes | matches file name |
| `title` | string | yes | |
| `author` | string | no | |
| `description` | string | no | shown on the game detail screen |
| `cover` | string | no | image path |
| `coverAlt` | string | no | what the cover shows, for players who cannot see it; only next to `cover`, like a page's `imageAlt` (B6) |
| `rules` | object | yes | see B4 |
| `items` | object | no | map `itemId -> Item` (B5) |
| `start` | string | yes | id of the first node |
| `nodes` | object | yes | map `nodeId -> Node` (B6) |

Ids (items, stats, flags, nodes) match `[A-Za-z0-9_-]+`.

## B4. Rules
```json
"rules": {
  "preset": "fighting-fantasy",
  "rerolls": 2,
  "health": "stamina",
  "stats": { "skill": { "label": "Habilidade" } },
  "combat": { "damage": "2" }
}
```
- `preset` (optional): `fighting-fantasy` or `d20-lite`. Without a preset, `stats`, `health` and (if the story has combat) `combat` must be fully given.
- Everything else **overrides the preset, field by field**. `stats` merges per stat id; a stat given in full adds a new stat.
- **Labels are per story**, because story files are single-language. Presets carry English labels; non-English stories override them (`label`).
- `bonuses`: bonuses to stats while a condition holds (B5, "Rule bonuses").
- `everyPage`: rules applied each time a page is entered, before the page's own `effects` (B10 step 4). Each is `{ "if": <condition>, "effects": [ ... ], "calm": true }`: `if` is optional (without it the rule always applies), `effects` follow B9, and `"calm": true` skips a page that has a `combat`, however it was reached. Rules apply in list order, each seeing the state the one before left. They are how a story writes healing between fights (`{ "calm": true, "effects": [ { "stat": "endurance", "add": 1 } ] }`), a poison that drains until cured (`{ "if": { "flag": "fever" }, "effects": [ { "stat": "stamina", "add": -1 } ] }`), and a debuff that runs out: a counter stat set to 3, a rule `{ "if": { "stat": "hex", "gte": 1 }, "effects": [ { "stat": "hex", "add": -1 } ] }`, and the penalty as a rule bonus while the counter is at least 1 (B5). They run on pages only, not on fight rounds.

### Stats
Each stat: `{ "label": string, "roll": dice, "max": bool }`.
- `roll`: dice notation (B8) rolled at character creation. A plain integer gives a fixed start (`"0"` for gold).
- `max: true`: the creation roll is also the ceiling. Effects can never raise the stat above it (healing stops at full health).
- `hidden: true`: the stat is kept off the stats bar, say a counter the reader need not see. It is a stat in every other way: effects, conditions and `{stat}` placeholders all see it.
- Every stat is clamped at 0 from below, unless it has a `min`.
- `min`: an integer, which may be negative, that the stat is clamped at instead: `{ "label": "Might", "roll": "1d4", "min": -3 }` can go down to -3, a signed modifier as in tabletop games. A creation roll below it is raised to it; with a `limit` it must be below the limit. The `health` stat cannot have a `min` (it is always 0).
- `health` names the stat that means "alive". When it reaches 0 the game ends with a **death** ending, wherever that happens. Health at 0 is final: from then on no effect applies, so nothing later in the same action (or the game) can bring the hero back (B9, B10).

### Stat limits and quantities
`limit` (integer ≥ 1) is a ceiling that does not depend on the roll: `{ "label": "Gold", "roll": "0", "limit": 50 }` starts at 0 and can never pass 50. A stat has either `max: true` or a `limit`, not both. A creation roll above the limit is cut to it.

A **quantity** is an integer, or `{ "stat": "price" }`, or `{ "stat": "price", "times": -1 }`: the current value of that stat times `times` (default 1, may be negative). Quantities may be used on the right-hand side of a `stat` condition (B7) and for `add` and `set` in a `stat` effect (B9).

### Creation
At character creation each stat is rolled once. The player may roll all stats again up to `rerolls` times (default `0`), then must accept the last roll. *Rerolls are a mobile convenience that the original books do not have; the presets set 2.*

### Creation choices
```json
"creation": {
  "name": true,
  "picks": [
    { "id": "kit", "title": "Choose two pieces of kit", "count": 2,
      "options": [
        { "id": "torch", "label": "A torch", "description": "Light in dark places.", "effects": [ { "give": "torch" } ] },
        { "id": "rope", "label": "A rope", "effects": [ { "give": "rope" } ] },
        { "id": "charm", "label": "A lucky charm", "effects": [ { "stat": "luck", "add": 1 }, { "set": "has-charm" } ] }
      ] }
  ]
}
```
- `name: true` asks the player for the hero's name (1 to 24 characters after trimming). `{name}` in page and choice text becomes that name (it is only a valid placeholder when the story asks for a name).
- Each pick group makes the player choose **exactly `count`** of its `options` (`count` is at most the number of options). `title` is shown above the options; each option has an `id`, a `label`, an optional `description` and `effects`.
- When the player accepts the character, the effects of every chosen option apply in order (group by group, option by option) before the first page. A `give` here adds the item **directly**: it is never an offer, even under `pickup: "choose"`, and if the pack is over capacity the newest items are dropped as usual.
- Ids must be the same in every translation.

### Presets (exact numbers)
Each preset is also a file, the normative numbers in data: [presets/fighting-fantasy.json](presets/fighting-fantasy.json) and [presets/d20-lite.json](presets/d20-lite.json). Each is exactly the `rules` object a story would write to get the preset without naming it, so an engine can load it instead of retyping the tables below, and an author can copy it to change one thing. The reference engine's tests check that the files and its built-in presets agree.

**`fighting-fantasy`**: Fighting Fantasy style.

| Stat | Roll | Max |
|---|---|---|
| `skill` | `1d6+6` | yes |
| `stamina` | `2d6+12` | yes |
| `luck` | `1d6+6` | yes |

`health: stamina`, `rerolls: 2`, combat `opposed` (below) with `attackRoll: 2d6`, `attackStat: skill`, `damage: 2`.
*Test your Luck*, as the books are commonly played, is written as the check `{ "roll": "2d6", "op": "lte", "vs": "luck", "effects": [{ "stat": "luck", "add": -1 }] }`.

**`d20-lite`**: tabletop-RPG style, tiny.

| Stat | Roll | Max |
|---|---|---|
| `might` | `1d4` (bonus +1..+4) | no |
| `agility` | `1d4` | no |
| `wits` | `1d4` | no |
| `hp` | `2d6+8` | yes |

`health: hp`, `rerolls: 2`, combat `vs-defense` with `attackRoll: 1d20`, `attackStat: might`, `defenseStat: agility`, `defenseBase: 10`, `damage: 1d6`.
Typical check: `{ "roll": "1d20", "add": "wits", "op": "gte", "vs": 12 }` (difficulty 12).

### Combat rules block
```json
"combat": { "mode": "opposed", "attackRoll": "2d6", "attackStat": "skill", "damage": "2" }
"combat": { "mode": "vs-defense", "attackRoll": "1d20", "attackStat": "might",
            "defenseStat": "agility", "defenseBase": 10, "damage": "1d6" }
```
Future modes are new `mode` values; `table` is one (B11).

### Combat extensions in the rules block
```json
"combat": {
  "mode": "opposed", "attackRoll": "2d6", "attackStat": "skill", "damage": "2",
  "luck": { "stat": "luck" }
}
```
`luck` turns on **Testing your Luck in a fight** (B11). Optional fields, with Fighting Fantasy's numbers as defaults: `"roll": "2d6"`, `"lucky": { "dealt": 2, "taken": -1 }`, `"unlucky": { "dealt": -1, "taken": 1 }`.

### Undo
`"undo": 3` lets the player step back up to 3 pages (default 0: no undo). Going back restores everything as it was before the choice: stats, items, flags, offers, visits. Dice are not remembered, so taking the choice again rolls again; a story that wants no rerolls leaves undo off. Fights are not undoable round by round; going back from a fight returns to the page before the choice that started it. Going back is also allowed after the game ended (a death or an ending page): the game is then running again, as it was before that choice. The history lives in memory only (it is not saved), so a restored game starts with none.

### Inventory rules
```json
"inventory": { "capacity": 3, "pickup": "choose" }
```
Without an `inventory` block the pack is unlimited and every `give` just adds the item.

| Field | Notes |
|---|---|
| `capacity` | optional integer ≥ 1: how many **slots** the pack has. A unique item fills one slot; a countable item (B5) fills one slot per `stack` units. Absent means unlimited. Items with a `capacity` of their own (containers, B5) do not count. |
| `pickup` | `"auto"` (default) or `"choose"`; see below. |

`pickup` decides what a `give` effect (on a node, a choice, a check or an item's `use`) does:
- **`auto`**: the item is added at once. If the pack is full it is **refused**: the player is told ("Your pack is full. You left behind: Rope") and does not get it. With no `capacity` every item is added.
- **`choose`**: the item becomes an **offer**. Offers are kept in order, and the player must resolve each one before choosing anything else or fighting (using an item is allowed, to make room):
  - **take it**: if there is room, it is added. If the pack is full, the player must also pick one carried item (not a container) to **leave behind**: a swap.
  - **leave it**: nothing changes and the story goes on.

  An offer for an item that is already carried or already offered is ignored (for a countable item, see below). A container never needs room. Offers still pending when the game ends are discarded. Because the player may decline, a story should never make an offered item the only way to win; give a worse alternative route.

**Countable items.** A `give` of a countable item (B5) adds `count` units:
- **`auto`**: as many units as fit are added, first into the room left in its part-filled slot, then into free slots, and never past the item's `max`; the rest are refused, and the player is told how many were left behind.
- **`choose`**: if the whole count fits in the room left in its part-filled slot, it is added directly, without an offer. Otherwise the give is **one offer for the whole count**, even if some are already carried; a further give while it is on offer adds to that offer. Taking it adds as many units as fit and leaves the rest (the player is told); with a full pack the player may first leave one carried item behind, all of it, to free room. A give of an item already at its `max` is refused at once, without an offer, and an offer stopped only by the `max` asks for no swap: freeing room would not help.

A `give` with a count during character creation adds every unit directly, up to the item's `max`; then the usual overflow rule applies.

## B5. Items
```json
"items": { "rusty-key": { "name": "Rusty key", "description": "Opens something old.", "image": "images/key.webp" } }
```
`name` is required; `description` and `image` optional.

An item is **unique** unless it has a `stack`: the pack holds it or not, and giving an item you hold changes nothing.

**Countable items.** `"stack": 5` (integer ≥ 1) makes the item countable: the player can hold several, any number of them.
```json
"meal": { "name": "Meal", "stack": 5,
  "use": { "effects": [ { "stat": "stamina", "add": 4 } ], "when": ["story"] } }
```
- `stack` is how many fit in **one pack slot**, not how many can be held: 5 Meals fill one slot, 6 fill two (a stack of 5 and a single one). With `"stack": 1` every unit fills its own slot. A countable item fills `ceil(count / stack)` slots; without `rules.inventory.capacity` the pack, and so the count, is unlimited (B4).
- `max` (only with `stack`): the most the player can hold, say 12 arrows in a quiver. A give never goes past it: what does not fit is refused, as when the pack is full (B4).
- `give`, `take` and `has` take a `count` (B7, B9). A `count` above 1 for an item without `stack` is an error.
- Using a countable item spends one; it leaves the pack when the last one is spent. Its `bonus` applies once, while at least one is held. `takeAll` removes every unit.
- A container cannot have a `stack`.
- `stack` and every `count` are structure, so translations must agree on them (the Dart validator does not compare them yet). `imageAlt` says what the image shows, as for a page (B6).

### Usable items
```json
"healing-potion": {
  "name": "Healing potion",
  "use": {
    "effects": [ { "stat": "stamina", "add": 6 } ],
    "when": ["story", "combat"],
    "combatCost": "round"
  }
}
```
| Field | Notes |
|---|---|
| `effects` | required list of effects (B9) applied when the item is used. The item is **removed from the inventory** automatically (one of a countable item); do not write `take`. |
| `when` | required, non-empty list of `"story"` (on a page with choices) and/or `"combat"` (during a fight). |
| `combatCost` | `"round"` (default) or `"free"`. Only allowed when `when` includes `"combat"`. |

An item without `use` cannot be used (a key is only held, and is spent by a choice's `take`). Using an item is possible while the game is running and not ended. Effects follow B9 (stats clamp to `min..max`); if they bring health to 0 the game ends in death (B10 step 5). Using an item changes no node, so `once` and `visited` are untouched.

**In a fight with `combatCost: "round"`** the player forfeits the attack for that round and the current enemy strikes: in `opposed` mode the enemy wins the round automatically and the player loses the enemy's `damage` (no contest is rolled); in `vs-defense` mode the enemy makes its normal attack roll against the player's defense. With `"free"` the enemy does nothing. Either way the player can then attack as usual.

### Item bonuses
```json
"sword": { "name": "Notched sword", "bonus": { "skill": 1 } }
```
While the item is in the pack, each stat in `bonus` is higher (or lower, with a negative number) by that amount, **everywhere**: checks, combat, conditions and `{stat}` placeholders. Bonuses add to the current value, but the result is never below the stat's floor (B4: 0, or its `min`), so a Luck of 8 with a bonus of -20 is 0. They never change the stat itself, its `limit` or its `max`, so losing the item takes the bonus away cleanly. A bonus on the `health` stat is not allowed. The stats bar shows the effective value with the bonus ("Skill 10 (+1)").

**Rule bonuses.** `rules.bonuses` is a list of bonuses that apply while a condition holds, whatever the pack holds:
```json
"bonuses": [ { "if": { "not": { "any": [ { "has": "sword" }, { "has": "club" } ] } }, "bonus": { "skill": -4 } } ]
```
While its `if` (B7) holds, a rule bonus works exactly like an item bonus: everywhere, added to the item bonuses, never changing the stat itself, never on the `health` stat. Its condition sees the stats **with item bonuses but without any rule bonus**, so a rule bonus can never switch itself (or another rule bonus) on or off: "-2 Skill while Skill is 9 or more" applies at Skill 9 and stays.

### Containers
```json
"backpack": { "name": "Backpack", "capacity": 3 }
```
`capacity` (integer ≥ 1) makes the item a **container**: while carried it adds that many slots to the pack, and it does not use a slot itself. It only matters when the story has `rules.inventory.capacity`. If a container leaves the pack (a `take`, a thief) and the remaining items no longer fit, the items picked up **most recently** that do not fit are lost, and the player is told ("You had no room and lost: Rope"). Of a countable item, units are lost only until what is left fits.

## B6. Nodes
```json
"cellar": {
  "text": "You wake in a cold cellar.",
  "image": "images/cellar.webp",
  "once": false,
  "effects": [ ... ],
  "choices": [ ... ]
}
```
| Field | Notes |
|---|---|
| `text` | required: a string, or a list of parts. Shown with the image. `\n\n` separates paragraphs. See below. |
| `image` | optional path. A missing file at runtime shows nothing; the validator flags it. |
| `imageAlt` | optional, only next to `image`: a short text saying what the picture shows, for players who cannot see it. A player that shows the image gives this text to assistive technology (a screen reader); without it the image is treated as decoration. Must not be empty. It is text, so each translation words it freely. |
| `effects` | optional list applied on **entering** the node (B9). |
| `once` | optional bool, default false. If true, `effects` apply only the first time the node is entered. Use for pickups and healing so revisiting cannot be exploited. |
| `choices` | list of choices (B10). |
| `combat` | a fight (B11). |
| `ending` | `"victory"`, `"death"` or `"defeat"`: the adventure is over, the hero is alive and has not won (captured, lost, gave up). |
| `title`, `note`, `chapter`, `draft` | authoring fields (B13) |

Exactly **one** of `choices` (non-empty), `combat`, `ending` must be present. A page with no way out is a parse error, except a draft page (B13).

### Audio and the journal
A node may have `"music": "audio/crypt.ogg"` and/or `"sound": "audio/door.wav"` (paths relative to the game folder, like images). `sound` plays once when the page is entered. `music` starts looping when the page is entered and **keeps playing across pages** until another page sets a `music`, or `"music": "stop"` stops it. The current music is part of the saved game, so a resumed game picks it up again. Players can switch music and sound effects off and set their volume in the settings; with both off or missing files the story reads exactly the same.

A story may define a `journal`: `"journal": { "clue-1": { "title": "A stranger's note", "text": "..." } }`. The effect `{ "journal": "clue-1" }` unlocks the entry (once; later unlocks do nothing) and the page tells the player ("Journal updated: A stranger's note"). The character sheet screen lists unlocked entries, newest first, with the hero's stats and items. Entry ids must be the same in every translation.

### Conditional text and numbers in text
`text` may be a **list of parts**. A part is a string, or an object `{ "if": <condition>, "text": "..." }` that is shown only while its condition holds. The parts that apply are shown in order, each as its own paragraph (a part may itself contain `\n\n`).
```json
"text": [
  "The innkeeper looks you over.",
  { "if": { "flag": "met-innkeeper" }, "text": "\"Back again?\" he says." },
  { "if": { "stat": "gold", "lte": 4 }, "text": "You count your last {gold} crowns." }
]
```
In page text and in choice `text`, `{id}` is replaced with the **current value** of the stat `id`, and `{id.max}` with its ceiling (the stat's value if it has none). `{item.count}` is replaced with how many of the item `item` are held (0 if none; 1 for a unique item held); the `.count` suffix keeps it apart from a stat with the same id. Write `{{` and `}}` for literal braces. A placeholder that is not a stat (or, with `.count`, an item) of the story is a validator error, and shows as written if it ever reaches a player. The text of a page is computed each time the page is shown, so it follows the current state.

## B7. Conditions
A condition is an object with exactly one kind:
| Kind | Meaning |
|---|---|
| `{ "has": "itemId" }` | the player holds the item. With `"count": 2` (a countable item): at least 2 of it |
| `{ "stat": "skill", "gte": 8 }` | stat compared with a number. One of `gte`, `lte`, `eq`. Uses the **current** value, bonuses included. The right side may be a quantity (B4): `{ "stat": "gold", "gte": { "stat": "price", "times": 2 } }`. |
| `{ "flag": "name" }` | the flag is set |
| `{ "visited": "nodeId" }` | the node was entered before |
| `{ "visits": "nodeId", "gte": 3 }` | how many times the node was entered. One of `gte`, `lte`, `eq`. Entering counts every time, including coming back to the same page and fleeing to it; the start page counts as 1. |
| `{ "all": [c, ...] }` | all true (empty = true) |
| `{ "any": [c, ...] }` | at least one true (empty = false) |
| `{ "not": c }` | negation |

## B8. Dice notation
`NdM` with optional `+K` or `-K`, or a plain integer. No spaces. `N` is the number of dice (at least 1, at most 100), `M` the number of faces (at least 2, at most 1000). `K` and a plain integer have at most 6 digits. Anything larger is invalid notation, so a story from a stranger cannot make an engine roll forever.
Examples: `1d6`, `2d6+6`, `1d20`, `2d6-1`, `3` (fixed).
Rolls keep the individual dice (the UI shows them) and the total (dice sum plus modifier).
Engines take their randomness from outside (a seedable source), so tests and tools can fix the dice.

### Order of rolls
Engines must roll in this order, so that the same dice give the same game everywhere (the [conformance tests](../conformance/README.md) script the die faces). A roll of `NdM` takes N dice one after another; a plain integer takes none.
- **Character creation**: each stat once, in rules order: the preset's stats in the order of its table (B4), then the stats the story adds, in the order of `rules.stats`.
- **Check** (B10): its `roll`. **Table**: its `roll`.
- **Round, `opposed`**: the player's `attackRoll`, then the enemy's `attackRoll`, then the `damage` of whichever side won (none on a tie).
- **Round, `vs-defense`**: the player's `attackRoll`; the player's `damage` if it hits; then, if the enemy is still alive, its `attackRoll`, and its `damage` if it hits.
- **Round, `table`** (and duels): the table `roll` only.
- **Several enemies at once**: the player's `attackRoll` once. In `opposed` mode, then for each living enemy in list order: its `attackRoll`, then the damage of the side that won against it (the player deals damage only to the target). In `vs-defense` mode, the player's `damage` on the target if it hits, then for each enemy still living, in list order: its `attackRoll` and, if it hits, its `damage`.
- **Testing luck in a fight**: the `luck.roll`.
- **Enemy strikes** (an item that costs the round, B5; a flee that costs a round, B11): for each enemy that strikes, in list order: in `opposed` mode its `damage`; in `vs-defense` mode its `attackRoll` and, if it hits, its `damage`; in `table` mode and duels the table `roll`.

Fight events (`wounded`, `rounds`; B11) roll nothing: they only decide where a fight ends.

## B9. Effects
An effect is an object with exactly one kind:
| Kind | Meaning |
|---|---|
| `{ "give": "itemId" }` | add the item to the inventory. With `"count": 3` (a countable item): add 3 (B4 says what happens when they do not all fit) |
| `{ "take": "itemId" }` | remove it (no-op if absent; the validator warns if it can never be held). With `"count": 2`: remove 2 of a countable item, stopping at 0; at 0 it leaves the pack |
| `{ "stat": "stamina", "add": -2 }` | add (or subtract) an integer; result clamped to `[min, max or limit]` (`min` is 0 unless the stat sets one) |
| `{ "stat": "gold", "set": 0 }` | set the stat, clamped the same way. `add` and `set` take a quantity (B4): `{ "stat": "gold", "add": { "stat": "price", "times": -1 } }` pays a price held in another stat. Exactly one of `add` or `set`. |
| `{ "journal": "entryId" }` | unlock a journal entry (B6) |
| `{ "set": "flag" }` | set a flag |
| `{ "clear": "flag" }` | clear it |
| `{ "takeAll": true }` | remove every item from the pack, every unit of a countable one: a theft or a flood. Pending offers are unaffected. |
| `{ "achieve": "achievementId" }` | the player earns an achievement (B15); it changes nothing in the game |

`give` follows the story's inventory rules (B4): added at once, refused when the pack is full (`pickup: "auto"`), or turned into an offer (`pickup: "choose"`).

Effects in a list apply in order, except that once the `health` stat is 0 no further effect applies, in this list or any later one (B4).

## B10. Choices
```json
{ "text": "Unlock the door", "to": "treasure", "if": { "has": "rusty-key" },
  "effects": [ { "take": "rusty-key" } ], "hideIfLocked": false, "lockedText": "You need a key." }
```
| Field | Notes |
|---|---|
| `text` | required |
| `to` | target node id. Exactly one of `to`, `check`, `table` or `return`. |
| `check` | a dice check (below) |
| `table` | a random outcome table (below) |
| `once` | default false. If true, once the player has taken this choice it is **gone** for the rest of the game (not shown, even if `hideIfLocked` is false). A choice is identified by its page and position, so translations must keep the order. |
| `if` | condition. If false the choice is **locked**. |
| `effects` | applied when chosen (see order below) |
| `hideIfLocked` | default false. If true, a locked choice is not shown at all. |
| `call` | default false. If true, taking the choice **remembers this page** before entering the target, whatever leads there (`to`, a check's `pass` or `fail`, a table outcome). A later `return` leads back to it. |
| `return` | `"return": true` instead of `to`: leads back to the page **last remembered** by a `call`, and forgets it. With nothing remembered the choice is **locked**. A choice cannot both `call` and `return`. |
| `lockedText` | optional string shown when locked. Without it the app builds a message from the condition ("Needs: Rusty key", "Needs Skill 8 or more") using its own translated UI strings, with item names and stat labels from the story. |

Locked choices are shown **disabled** with their reason, and can't be chosen.

**Calls and returns.** A shop, a wandering monster or a side room that can be reached from many pages leads back to whichever page sent the player there. The pages remembered form a stack, last in first out, so calls can nest (the shop's back room returns to the shop, the shop to the road); it holds at most **16** pages, and a deeper call forgets the oldest one, so a game never fails on it. A return **enters** the page again like any other entry (B10 step 4): its `effects` apply unless `once`, the visit counts, the every-page rules run. What is remembered is part of the game state: saved with the game, and restored by undo. A fight can return too (B11).

### Checks
```json
"check": { "roll": "2d6", "add": "skill", "op": "lte", "vs": 10,
           "pass": "door-open", "fail": "hurt-foot", "effects": [ ... ] }
```
- Total = dice roll + `add` (a stat id, whose current value is used, or an integer; default 0).
- `op` `gte`: pass if total ≥ `vs`. `op` `lte`: pass if total ≤ `vs`.
- `vs` is an integer, or a stat id (current value). So FF's Luck test is `roll 2d6, op lte, vs "luck"`.
- `effects` (optional) apply **after the roll, whichever way it went**, and the roll uses the stat values from *before* them. This is how Luck is spent.
- `pass` and `fail` are node ids.
- The UI should show what will be rolled (stat, target) before the tap, and the dice and result after.

### Random outcome tables
```json
{ "text": "Search the rubble",
  "table": { "roll": "1d6",
             "outcomes": [ { "upTo": 2, "to": "nothing" },
                           { "upTo": 5, "to": "coins", "effects": [ { "stat": "gold", "add": 3 } ] },
                           { "upTo": 6, "to": "gem" } ] } }
```
- `roll` is dice notation (B8). The first outcome whose `upTo` is **at least the total** is used, so `upTo` must increase from one outcome to the next, and the last one must be at least the largest possible total (otherwise the story is invalid).
- An outcome may have `effects` (B9), applied after the roll and before entering `to`, like `check.effects`.
- The UI shows the roll ("You rolled 1d6 = 4.") after the tap.

### What happens when the player taps a choice
1. A locked choice is rejected.
2. Apply the choice's `effects`.
3. If there is a `check`: roll it, apply `check.effects`, pick `pass` or `fail` as the target. If there is a `table`: roll it, apply the outcome's `effects` and use its `to`. With `return`, the target is the page last remembered, which is forgotten. Otherwise the target is `to`. A `once` choice is marked as taken at this point. With `call`, the current page is remembered.
4. **Enter the target node**: record it as visited and count the visit. Apply the every-page rules (`rules.everyPage`, B4), then its `effects` (skipped if `once` and it was already visited).
5. If the `health` stat is 0 (after step 2, 3 or 4) the game ends with **death**, whatever the node says. Once health is 0, the steps after it still run but apply no effects: a check or table still rolls and decides the target, and the target is still entered (visited, visit counted, music and sound as usual).
6. If the node has `ending`, the game ends with that ending (`victory`, `defeat` or `death`). If it has `combat`, the fight starts.

**A page with no open choice.** If every choice of a page is spent (`once`), hidden (`hideIfLocked`) or locked, and the page has no `ending` and no `combat`, the player has nothing to tap. The game is **not** ended: the engine offers nothing, and undo (if the story allows it, B4) leads out. This is an author's mistake, but no check of the story alone can always find it, because it depends on what the player did. Tools should look for it by playing: the Dart `simulate_story` tool reports such games as "stuck".

While there are pending offers (B4) no choice can be taken and no fight round can be played until each offer is resolved.

The game starts by entering `start` the same way, after character creation.

## B11. Combat
```json
"combat": {
  "enemies": [ { "name": "Goblin", "attack": 7, "health": 6 } ],
  "win": "after-fight",
  "flee": "cellar"
}
```
- `enemies`: fought **one at a time, in list order** (unless `simultaneous`, below). Each: `name`, `attack` (number), `health` (number), and for `vs-defense` mode `defense` (number); optional `damage` (dice) overriding the rules default for that enemy; optional `armor`: the damage the player deals to this enemy is reduced by `armor`, never below 0.
- `win`: node entered when the last enemy reaches 0 (the node is entered normally, step 4 above). `{ "return": true }` instead leads back to the page last remembered by a `call` (B10); with nothing remembered the fight ends and the player stays on the page, with nothing to do (the validator warns: B16 `return-without-call`).
- `flee`: optional node. If present the player may flee after any round (no automatic penalty; put penalties in the flee node's `effects`). If absent, no fleeing. `{ "return": true }` flees back to the page last remembered; with nothing remembered, fleeing is not offered.
- `fleeCost`: `"free"` (default) or `"round"`, only with `flee`. With `"round"`, fleeing costs the round, as an item that costs the round does (B5): the current enemy, or every enemy still standing in a fight against several, strikes first. If that brings health to 0 the game ends in **death**; otherwise the flee node is entered. The strike leads to no `wounded` and counts for no `rounds`: the player is leaving.
- `wounded`: optional node. The first time the player loses health in this fight and is still alive, the fight ends and this node is entered.
- `rounds`: optional `{ "after": 3, "to": "it-escapes" }`, `after` an integer of at least 1. When `after` rounds have been played and the fight is not over, it ends and `to` is entered. "Win within 3 rounds" is `after: 3`, with `to` the page for being too slow.
- Fighting is round by round, driven by the player (a button per round).

**Round, `opposed`**: player total = `attackRoll` + player `attackStat`. Enemy total = `attackRoll` + enemy `attack`. Higher wins: the loser loses `damage` health (the enemy's `damage`, or the rules default, when the enemy wins). Equal: nobody is hurt.

**Round, `vs-defense`**: first the player: `attackRoll` + `attackStat` ≥ enemy `defense` is a hit, and the enemy loses a roll of `damage`. If the enemy is still alive it attacks: `attackRoll` + enemy `attack` ≥ `defenseBase` + player `defenseStat` is a hit, and the player loses the enemy's `damage` (or the rules default).

**Round, `table`**, as in Lone Wolf: the rules give `"mode": "table"`, an `attackStat`, a `roll` (default `"1d10-1"`, which must start at 0) and a results `table`:
```json
"combat": { "mode": "table", "attackStat": "skill", "roll": "1d10-1",
  "table": [
    { "upTo": -3, "results": [[0,4],[0,3],[1,3],[1,2],[2,2],[2,2],[3,1],[3,1],[4,0],[4,0]] },
    { "upTo": 3,  "results": [[1,2],[2,2],[2,1],[3,1],[3,1],[4,1],[4,0],[5,0],[5,0],[6,0]] },
    {             "results": [[3,1],[4,1],[5,0],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[99,0]] }
  ] }
```
The **ratio** is the player's `attackStat` minus the enemy's `attack`. The row is the first whose `upTo` is at least the ratio; the last row has no `upTo` and takes everything above. The roll picks a pair `[enemyLoss, playerLoss]` (index = the roll's total): the health points the enemy and the player lose that round. A table needs one pair for every value the roll can give, and rows must have increasing `upTo`. Enemy `defense` and `damage` are not used; an enemy's `armor` still takes points off the enemy's loss. An item that costs the round (B5) lets the enemy strike: the roll picks a result and only the player's loss is applied. `table` mode cannot be combined with `simultaneous` or `luck` (the validator and the rules parser say so).

**A duel inside another mode:** a story that fights mostly with `opposed` or `vs-defense` can still have set-piece duels. Give `rules.combat` a `table` (and optionally a `roll`) next to its normal mode, and mark a fight `"duel": true`: that fight is resolved by the table as above, while every other fight uses the mode. The `attackStat` is shared. A duel cannot be `simultaneous`, and no luck test is offered in it (even if the rules have `luck`); `luck` and `table` can coexist only in this form, not with `"mode": "table"`.

**Several enemies at once:** `"simultaneous": true` on the fight. Every living enemy fights every round and the player **chooses a target** each round. In `opposed` mode the player rolls once; each enemy rolls its own total; against the target the higher total wounds the other as usual, against the others an enemy with the higher total wounds the player and otherwise nothing happens. In `vs-defense` mode the player attacks the target only, then every living enemy attacks. The fight is won when every enemy is at 0; the player loses health from several enemies in one round.

**Testing your Luck in a fight:** when the rules have `combat.luck` and a round has hurt someone but the fight is not over, the player may test luck once: roll the `luck.roll` (default 2d6); at or below the current `luck` stat is lucky, above is unlucky; the luck stat then drops by 1 either way (never below 0). Lucky: if the player wounded an enemy this round that wound grows by `lucky.dealt` (default +2); if an enemy wounded the player that wound changes by `lucky.taken` (default -1). Unlucky: the same with `unlucky.dealt` (default -1) and `unlucky.taken` (default +1). Wounds never become negative and a healed side never goes above its maximum. A wound is what the round actually took off: an enemy's `armor` comes off first, and luck changes what is left (a blow that armor stopped entirely is no wound, and luck leaves it at 0). In a fight against several enemies at once, the wounds the player took that round count as **one** wound: luck changes their total once, not each enemy's. The test is not offered after a round that ended the fight, after a round that killed an enemy, or after a round in which nobody was hurt. A lucky blow that finishes an enemy counts as a kill (and as the win if it was the last). The open test is part of the saved fight; fighting on, using an item that costs the round, or testing closes it.

**Using an item** during a fight is allowed for items whose `use.when` includes `"combat"` (B5); depending on `combatCost` it forfeits the round or is free.

**How a round ends a fight.** After each round, in this order: if the player's health is 0, **death** (B10 step 5); if every enemy is at 0, the **win**; then if the player lost health this round, `wounded`; then, if `after` rounds have now been played, `rounds.to`. Using an item that costs the round (B5) counts as a round, and the enemies' strikes as a wound; a free item counts as neither. In a fight against several enemies at once, the wounds of one round count as one wound. These work in every mode (`opposed`, `vs-defense`, `table`, duels). No luck test is offered after a round that ended the fight, so a wound that leads to `wounded` cannot be softened by luck. The pages are entered normally (B10 step 4).

Mid-fight state (current enemy, enemy health, the open luck test, and the rounds played so far) is part of the saved game state.

## B12. Complete example
```json
{
  "schema": 1, "id": "rusty-door", "lang": "en", "title": "The Rusty Door",
  "rules": { "preset": "fighting-fantasy" },
  "items": { "rusty-key": { "name": "Rusty key" } },
  "start": "cellar",
  "nodes": {
    "cellar": { "text": "You wake in a cold cellar. Shelves line one wall; a heavy door stands opposite.",
      "choices": [
        { "text": "Search the shelves", "to": "shelves" },
        { "text": "Go to the door", "to": "door" } ] },
    "shelves": { "text": "Behind a jar you find a rusty key.", "once": true,
      "effects": [ { "give": "rusty-key" } ],
      "choices": [ { "text": "Go back", "to": "cellar" } ] },
    "door": { "text": "The door is locked.",
      "choices": [
        { "text": "Unlock it", "to": "treasure", "if": { "has": "rusty-key" } },
        { "text": "Kick it open", "check": { "roll": "2d6", "add": "skill", "op": "gte", "vs": 15,
            "pass": "treasure", "fail": "foot" } } ] },
    "foot": { "text": "Ouch. The door does not move.", "effects": [ { "stat": "stamina", "add": -2 } ],
      "choices": [ { "text": "Try something else", "to": "door" } ] },
    "treasure": { "text": "A chest of gold. You win!", "ending": "victory" }
  }
}
```
Note that `foot` has no `once`, so every visit costs 2 Stamina on purpose.

## B13. Authoring fields
These fields exist for authors and visual editors (the Builder). None of them changes how a finished story plays, except `showTitles`.

```json
"chapters": { "village": { "title": "Act 1: The village" }, "crypt": { "title": "Act 2: The crypt" } },
"nodes": {
  "crypt-door": { "title": "Crypt door", "chapter": "crypt",
    "note": "Second visit should feel colder. Check the key is reachable.",
    "text": "...", "choices": [ ... ] },
  "crypt-deep": { "title": "Deeper in", "chapter": "crypt", "draft": true }
}
```
| Field | Where | Notes |
|---|---|---|
| `title` | node | optional, non-empty string: a short name for the page. Shown on Builder cards, by the graph tool and in validator messages. Players see it only when the story has `showTitles`. |
| `showTitles` | top level | optional bool, default false. When true the app shows a node's `title` as the page heading (a node without one has no heading). |
| `note` | node | optional string, for authors only: never shown to players. Translations may differ or leave it out. |
| `chapters` | top level | optional map `chapterId -> { "title": string }`. The key order is the reading order. Chapter titles are for authors (Builder frames, graph tool clusters). |
| `chapter` | node | optional chapter id; it must be a key of `chapters` (parse error otherwise). A node belongs to at most one chapter. |
| `draft` | node | optional bool, default false. See below. |

Ids of chapters match `[A-Za-z0-9_-]+` and, like node ids, must be the same in every translation, with the same `chapter` on each node. Titles and notes are free text per file.

### Draft pages
A node with `"draft": true` is a page not written yet. For a draft the rule "exactly one of `choices`, `combat`, `ending`" does not apply and `text` may be missing; any field that is present must still be valid, and choices may lead to drafts. So the Builder (and an LLM writing part of a story) can always save a file.
- An engine enters a draft page as usual (it counts as visited and its `effects` apply), but offers **nothing** from it: no choices, no fight and no ending, whatever fields it has. The game cannot go on from there except by undo or editor tools.
- The validator reports each draft as a **warning** ("draft page, not written yet"), so `--strict` fails while any remain.
- The app does **not list** a story with drafts in release builds. Debug builds and the Builder's playtest do; entering a draft page there shows its text (or nothing) and a "Not written yet" notice with no choices; undo or the playtest tools lead out.
- Removing `draft` makes the node an ordinary page with every usual rule.

## B14. Game packages (`.gamebook`)
A game travels outside the app as one file: a **zip** of the game folder (B1) with the extension `.gamebook`. Editors export it and players import it; the Dart engine reads and writes them (`package.dart`) and packs a folder with its `pack_game` tool.
- The zip root holds what `games/<slug>/` holds: one or more `story.<lang>.json`, and the `images/` and `audio/` they reference. `builder.json` may be included; the app ignores it. Nothing else is allowed (no other files, no folders above the root, no links).
- Every story in it must parse, have no validator **errors** (B2: a broken link would strand a player; warnings are allowed), and share one `id`, and the translations must match (B1). Missing media are allowed (the player shows nothing), as for bundled games.
- Limits, checked before anything is unpacked: at most 100 MB unpacked, 2,000 files, media files only of the types the app plays (`.webp`, `.png`, `.jpg`, `.jpeg`, `.ogg`, `.mp3`, `.wav`, `.m4a`). Anything else rejects the whole file with a message saying why.
- A package whose story `id` matches a bundled game is refused (bundled games cannot be replaced); one matching an imported game is an **update** of it.

**Updates and saves.** An update replaces the old version. The player's save for that game is kept only if it still fits the new story: every node, item, stat and journal entry it names still exists, the pack still fits (a count is kept only for a countable item, and the slots used fit the capacity), every stat is within its `min` and ceiling, the pages to return to still exist and are at most 16,, and the save loads cleanly (flags need no declaration, so they always fit). Otherwise the save is dropped and the player is told the story changed and the adventure starts again. This is the rule every save already follows (a save that does not fit reads as "no save"), plus the message.

## B15. Achievements
```json
"achievements": {
  "brave": { "title": "Brave", "description": "Faced the dragon and lived." },
  "coward": { "title": "Better safe", "description": "Went home.", "hidden": true }
}
```
An achievement is a mark of something the player did, kept **across games** of a story: replay value.
- The effect `{ "achieve": "brave" }` earns it, wherever effects go (a page, a choice, a check, a table outcome, an item's use, a creation pick).
- Achievements belong to the **player**, not to one adventure: an app keeps the ones earned for each story (by its `id`, so for every language), outside saved games. Starting again, dying or undoing does not take one back; earning one already earned does nothing. An app may tell the player the first time.
- `title` is required; `description` is optional; `hidden: true` keeps the title and description from players until it is earned (they see that a hidden achievement exists).
- An engine reports each achievement earned as an event and keeps nothing in the game state, so the effect never changes how a story plays.
- Ids must be the same in every translation; titles and descriptions are per language.

## B16. Validator warnings (lint)
Errors make a story unplayable, and every engine must reject it (B2; conformance `invalid` cases). **Warnings** point at what is probably a mistake in a story that still plays. Reporting them is optional: an engine can play stories without them. A tool that does report them (a validator, an editor) may claim the **lint** tier of the conformance suite, and then reports exactly these, each with its code and path. Messages are each tool's own wording.

| Code | Path | When |
|---|---|---|
| `unreachable` | `nodes.<id>` | no way leads to the node from the start (choices, checks, tables, fight win and flee, and the fight's `wounded` and `rounds.to`; a `return` only leads back to pages already reached) |
| `return-without-call` | `nodes.<id>` | the page has a `return` (a choice, a fight's `win` or `flee`) and can be reached from the start without any `call`, so the return may have nowhere to go |
| `no-victory` | `nodes` | no victory ending can be reached |
| `draft` | `nodes.<id>` | the node is a draft (B13) |
| `never-earned` | `achievements.<id>` | no `achieve` effect earns it |
| `required-never-given` | where the `has` condition is | the item is required but nothing gives it |
| `usable-never-given` | `items.<id>` | the item has a `use` but nothing gives it |
| `taken-never-given` | where the `take` effect is | the item is taken but nothing gives it |
| `flag-never-set` | where the `flag` condition is | the flag is checked but nothing sets it |
| `flag-never-checked` | `flags.<flag>` | the flag is set but nothing checks it |
| `journal-never-unlocked` | `journal.<id>` | no `journal` effect unlocks the entry |
| `capacity-without-pack` | `items.<id>.capacity` | a container, but the rules give the pack no `capacity` |

An item or flag required, taken or checked in several places is reported once, at one of them (which one is up to the tool).

**Translations.** A translation (another language file of the same story, B1) is compared with the source, the first language. It must have the same ids and structure; only the words differ:
| Code | Path | When |
|---|---|---|
| `translation-missing` | where the id is declared (`nodes.<id>`, `items.<id>`, `rules.stats.<id>`, `journal.<id>`, `achievements.<id>`, `chapters.<id>`, `flags.<flag>`) | the source has the id and the translation does not |
| `translation-extra` | the same | the translation has an id the source does not |
| `translation-text-parts` | `nodes.<id>` | the node's text has a different number of parts (B6) |
| `translation-choices` | `nodes.<id>` | the node has a different number of choices |
| `translation-chapter` | `nodes.<id>` | the node is in a different chapter |

Warnings are not versioned with `schema`: a new warning can be added at any time. It changes no story, only what tools say about it.
