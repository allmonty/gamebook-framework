# Stats and your hero

Stats are the numbers that describe the hero: how skilled, how healthy, how lucky, how rich. You choose which stats exist, how they are rolled, what they are called, and which one means "alive". Then the reader creates their hero: rolls, names them and picks their gear.

## Presets: rules in one line

So far every example used `"preset": "fighting-fantasy"`. A preset is a ready-made set of rules:

| Preset | Stats (starting roll) | Health | Fights |
|---|---|---|---|
| `fighting-fantasy` | Skill `1d6+6`, Stamina `2d6+12`, Luck `1d6+6` | Stamina | both roll 2d6 + Skill; the loser loses 2 |
| `d20-lite` | Might, Agility, Wits `1d4` each, HP `2d6+8` | HP | 1d20 + Might against 10 + Agility; damage 1d6 |

Here is the same kind of story with `"preset": "d20-lite"`:

```gamebook
examples/04-stats-and-hero/d20-hero
```

Anything you write next to the preset **overrides it, field by field**. The most common override is a stat's label, because presets are named in English. The Portuguese version of every example does exactly this:

```json
"rules": { "preset": "d20-lite", "stats": { "might": { "label": "Força" } } }
```

## Your own stats

Leave the preset out and define everything yourself: the `stats`, and which one is `health`.

```gamebook
examples/04-stats-and-hero/ghost-market
```

```json
"rules": {
  "health": "nerve",
  "stats": {
    "nerve": { "label": "Nerve", "roll": "2d6+6", "max": true },
    "wits":  { "label": "Wits",  "roll": "1d6" },
    "gold":  { "label": "Gold",  "roll": "1d6", "limit": 10 }
  }
}
```

- `label` is what the reader sees; the id (`nerve`) is what you write in conditions and effects.
- `roll` is dice notation: `1d6` is one six-sided die, `2d6+6` is two dice plus 6, and a plain number like `"3"` is a fixed start. Chapter 5 covers dice.
- `"max": true` makes the starting roll a ceiling: healing never goes above it.
- `limit` is a fixed ceiling instead (schema 5): gold here can never pass 10.
- `health` names the stat that means alive. When it hits 0 the reader dies, wherever that happens.
- No stat goes below 0, unless you give it a `min` (below).

### Changing stats

Stats change through effects on pages, choices and items:

| Effect | Meaning |
|---|---|
| `{ "stat": "nerve", "add": -4 }` | lose 4 Nerve (positive numbers add) |
| `{ "stat": "gold", "set": 0 }` | set Gold to exactly 0 (schema 5) |

And conditions compare them: `{ "stat": "gold", "gte": 3 }` (3 or more), `lte` (or less), `eq` (exactly).

### Below zero

In tabletop games a stat is often a modifier added to a roll, and a weak or cursed hero has a negative one: "Might -2". Give the stat a `min` and it can go down that far (schema 8):

```gamebook
examples/04-stats-and-hero/cursed-gauntlet
```

```json
"rules": { "preset": "d20-lite", "stats": { "might": { "min": -3 } } }
```

The gauntlet's `bonus` of -4 now takes Might below zero, and the door's `1d20 + might` feels it. Effects and bonuses stop at the `min`, as they stop at 0 for any other stat. The `health` stat cannot have one: at 0 the hero is dead.

### Bonuses with a condition

An item's `bonus` (chapter 3) counts while the item is carried. Some bonuses depend on more: a hero with no weapon at all fights at -4 Skill. Write it once in the rules (schema 8):

```gamebook
examples/04-stats-and-hero/unarmed
```

```json
"bonuses": [
  { "if": { "not": { "any": [ { "has": "sword" }, { "has": "club" } ] } },
    "bonus": { "skill": -4 } }
]
```

While the `if` holds, the bonus counts everywhere, like an item's: checks, fights, conditions, `{skill}` in text and the stats bar. Lose the sword and it starts; pick up the club and it stops. The condition sees item bonuses but not other rule bonuses, so a rule cannot switch itself on or off.

## Prices and other stats that point at stats

A **quantity** can stand where a number goes, in `add`, `set` and conditions: `{ "stat": "price" }` means "the current value of Price", and `"times": -1` flips its sign (schema 5). That lets one "Buy it" choice work for every stall:

```gamebook
examples/04-stats-and-hero/merchant-price
```

```json
{ "text": "Buy it", "to": "street",
  "if": { "stat": "gold", "gte": { "stat": "price" } },
  "effects": [ { "stat": "gold", "add": { "stat": "price", "times": -1 } }, { "give": "noodles" } ] }
```

Each stall sets `price` as you walk up to it. The reader sees Price in their stats, which here reads like a price tag.

## Creating the hero

Add `creation` to the rules (schema 5) and the story opens with a character screen:

```gamebook
examples/04-stats-and-hero/pick-your-kit
```

```json
"rules": {
  "preset": "fighting-fantasy",
  "rerolls": 3,
  "creation": {
    "name": true,
    "picks": [ { "id": "kit", "title": "Choose two things to bring", "count": 2, "options": [
      { "id": "torch", "label": "A torch", "description": "Light in dark places.", "effects": [ { "give": "torch" } ] },
      { "id": "rope", "label": "A rope", "effects": [ { "give": "rope" } ] },
      { "id": "charm", "label": "A lucky charm", "effects": [ { "stat": "luck", "add": 1 }, { "set": "lucky" } ] }
    ] } ]
  }
}
```

- `rerolls`: how many times the reader may roll all stats again (Fighting Fantasy allows 2). The last roll is kept.
- `"name": true` asks for the hero's name; write `{name}` in any text to use it.
- `picks`: groups of options, each with how many to choose (`count`). Every chosen option applies its `effects` before the first page. `{ "set": "lucky" }` raises a **flag**, an on/off switch a condition can test with `{ "flag": "lucky" }`; chapter 7 has more.

The character screen appears when the story has `creation` or sets its own `rerolls`. Otherwise the hero is rolled silently and the story starts on its first page, like the earlier examples.

### Try it

- In the ghost market, change the gold `roll` to `"20"`. The limit still caps it at 10.
- In Pick Your Kit, change `count` to `1`, or add a fourth option.
- In the night market, make the jacket cost 2.
- In the vault, remove `"min": -3`: the gauntlet now stops Might at 0, and the door gets easier.
- In Unarmed, change `-4` to `-1`, or remove `{ "has": "club" }` so the club no longer helps.

Next: rolling dice when it matters.
