# Items

Keys, potions, swords, ropes: things the reader picks up change what they can do. In this chapter you define items, hand them out, take them away, lock choices behind them, let the reader use them, and decide how much fits in the pack.

## Keys and locked doors

```gamebook
examples/03-items/locked-door
```

Three new pieces work together here:

1. **The item is declared** once, at the top of the file, in `items`. It has an id (`rusty-key`), a `name` the reader sees and an optional `description`:
   ```json
   "items": { "rusty-key": { "name": "Rusty key", "description": "Old iron, older than the city." } }
   ```
2. **A page gives it.** `effects` on a page happen when the reader arrives: `{ "give": "rusty-key" }`. Effects can also sit on a choice, and happen when it is taken.
3. **A choice needs it.** `"if": { "has": "rusty-key" }` locks the door until the key is in the pack. The app says why: "Needs: Rusty key". That choice also has `{ "take": "rusty-key" }`, because the key breaks in the lock.

Items are unique: the reader either has the rusty key or not. Giving it twice changes nothing.

> Try it: search the shelves twice. The key is given again, but you still hold one. Chapter 7 shows how to make a page give its reward only once.

## Items the reader can use

An item with `use` gets a **Use** button in the pack. Using it applies its effects and spends it. This needs `"schema": 2` or higher.

```gamebook
examples/03-items/healing-potion
```

```json
"potion": {
  "name": "Healing potion",
  "use": { "effects": [ { "stat": "stamina", "add": 4 } ], "when": ["story"] }
}
```

- `effects`: what happens. Here Stamina goes up by 4. (Effects on stats are explained in chapter 4; `add` can be negative too.)
- `when`: where it can be used: `"story"` on a normal page, `"combat"` in a fight, or both: `["story", "combat"]`.
- In a fight, using an item normally costs you the round. Add `"combatCost": "free"` for items that do not.

Stamina never goes above where it started: the potion cannot overheal.

## Items that make you better

With `bonus` an item changes a stat while it is carried (schema 5). Drop it and the bonus goes with it.

```gamebook
examples/03-items/rune-blade
```

The gate wants `{ "stat": "skill", "gte": 12 }`: Skill 12 or more (`gte` means "greater than or equal"; `lte` is "less than or equal", `eq` is "equal"). Few heroes start that skilled, but the blade adds 3. Watch the Skill pill when you take it. Bonuses count everywhere: conditions, dice checks and fights.

## A pack with limited room

Without rules, the pack holds everything. To make room matter, add `inventory` to `rules` (schema 3):

```json
"rules": { "preset": "fighting-fantasy", "inventory": { "capacity": 2, "pickup": "choose" } }
```

```gamebook
examples/03-items/full-pack
```

- `capacity` is how many items fit.
- `"pickup": "choose"` turns every `give` into an **offer**: the reader decides to take or leave it, and when the pack is full, what to leave behind for it. The story waits until each offer is settled.
- An item with its own `capacity` is a **container** (the satchel): it adds slots and takes none.

Because a reader may leave an item behind, never make one offered item the only way to win. Here the hatch opens with the crowbar *or* the rope.

## Thieves and floods

With `"pickup": "auto"` (the default) a `give` adds the item at once, and if the pack is full the item is simply refused. `{ "takeAll": true }` empties the pack in one go: a thief, a flood, a prison search.

```gamebook
examples/03-items/the-thief
```

Read the log above the page: the gem is refused for lack of room, and later the coin is lost.

## Things that come in numbers

Five meals, a quiver of arrows, three healing herbs: give the item a `stack` and the reader can carry several (schema 8).

```gamebook
examples/03-items/provisions
```

```json
"meal": { "name": "Meal", "stack": 5,
  "use": { "effects": [ { "stat": "stamina", "add": 4 } ], "when": ["story"] } }
```

- `{ "give": "meal", "count": 5 }` gives five; `{ "take": "meal", "count": 2 }` takes two (never below 0).
- `{ "has": "meal", "count": 2 }` needs at least two: the ferryman's choice stays locked, "Needs: 2 × Meal", once you have eaten too much.
- Using one spends one. The pack shows how many are left, and the item is gone with the last one.
- `stack` is how many fit in **one slot** of a limited pack: 5 meals fill one slot, the 6th starts a second. With `"stack": 1` every one fills its own slot. Without a `capacity` the pack, and the count, have no limit.

The night page is a classic: "Eat a meal" needs one and takes it; "Go hungry" shows only when you have none, and costs Stamina. Without a `stack` an item stays one of a kind, as before, and a `count` above 1 is an error.

## What you learned

| Write | Where | Meaning |
|---|---|---|
| `"items": { "id": { "name": ... } }` | top of the file | declare an item |
| `{ "give": "id" }` / `{ "take": "id" }` | `effects` of a page or choice | add / remove it |
| `{ "takeAll": true }` | `effects` | empty the pack (schema 3) |
| `{ "has": "id" }` | a choice's `if` | needs the item |
| `"use": { "effects": [...], "when": [...] }` | an item | usable item (schema 2) |
| `"bonus": { "skill": 3 }` | an item | stat bonus while carried (schema 5) |
| `"inventory": { "capacity": 2, "pickup": "choose" }` | `rules` | limited pack, offers (schema 3) |
| `"capacity": 2` | an item | a container |
| `"stack": 5` | an item | countable: any number, 5 to a slot (schema 8) |
| `"count": 2` | a `give`, `take` or `has` | how many (schema 8) |

Next: the hero's stats, and how to roll them.
