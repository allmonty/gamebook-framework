# Conformance tests

Language-neutral test cases for the [format](../spec/framework.md). An engine in any language is **conformant** for the versions it claims when it passes every case whose story uses only those versions. The Dart engine runs them in `engines/dart/test/conformance_test.dart`; use it as a model for a runner of your own.

Dice are scripted, not seeded: each case lists the exact die faces in order, so no language's random number generator is involved. The order in which an engine consumes them is [framework.md B8, "Order of rolls"](../spec/framework.md).

## Files
- `cases/play/*.json`: play a story with scripted dice and check the result.
- `cases/invalid/*.json`: a story that must be rejected, and where.

Every case has a `description` (what it shows) and `spec` (the sections it tests).

## Play cases
```json
{
  "description": "2d6 + Skill 9 = 15 meets gte 15.",
  "spec": ["B8", "B10"],
  "story": { "schema": 1, "...": "a complete story" },
  "stats": { "skill": 9, "stamina": { "value": 8, "max": 12 }, "luck": 8 },
  "name": "Ann",
  "dice": [3, 3],
  "actions": [ { "choose": 1 }, { "choose": 1 } ],
  "expect": { "node": "treasure", "ending": "victory" }
}
```
**Start.** Start a new game (B10, "The game starts...") with these start values instead of rolling them. `stats` gives every stat of the resolved rules: a number is a start value, turned into the stat as the creation roll would (with `max: true` it is also the ceiling; with a `limit` it is cut to the limit and the limit is the ceiling); an object gives the value and ceiling directly (`max` may be null). `name` is optional (the hero's name, B4). Creation picks are not used.

**Dice.** `dice` are die faces, used one by one whenever the engine rolls a die. A face is always on the die being rolled (1 to M for an `NdM`). After the last action **every face must have been used**: an unused face means the engine rolled less than the spec says.

**Actions**, in order. Each is an object with one key:
| Action | Meaning |
|---|---|
| `{ "choose": i }` | take the choice at position `i` of the current node's `choices` list (the position in the file, counting hidden ones) |
| `{ "fight": {} }`, `{ "fight": { "target": i } }` | play one combat round; `target` is an enemy position, for simultaneous fights |
| `{ "flee": {} }` | flee the fight |
| `{ "testLuck": {} }` | test luck after a round (B11) |
| `{ "use": "itemId" }` | use an item |
| `{ "offer": { "take": true, "replacing": "itemId" } }` | resolve the first pending offer: take it (optionally leaving a carried item behind) or `"take": false` to leave it |
| `{ "undo": {} }` | go back one page |

An action may also have `"rejected": true`: the engine must refuse it (it is not allowed now) and the game state must not change at all.

**Expect.** Every key given must match; keys left out are not checked.
| Key | Compared with |
|---|---|
| `node` | id of the current node |
| `ending` | `"victory"`, `"death"` or `null` (still playing) |
| `stats` | for each stat listed, its current value **with item bonuses** (B5) |
| `inventory` | the items carried, sorted by id |
| `flags` | the flags set, sorted |
| `visits` | for each node listed, how many times it was entered (0 if never) |
| `journal` | unlocked entry ids, in unlock order |
| `offers` | pending offers, in order |
| `paragraphs` | the current page's text as shown: the parts that apply, placeholders filled, split on blank lines (B6) |
| `choices` | the choices shown (hidden and spent ones left out), each `{ "index", "text", "locked" }`; `text` has placeholders filled |
| `title` | the current node's `title` (B13), or `null` |
| `combat` | the fight under way, `{ "enemy": position, "health": [each enemy's health] }`, or `null` |

## Invalid cases
```json
{ "description": "...", "spec": ["B2"], "story": { "...": "..." },
  "error": { "path": "nodes.a.choices[0].too" } }
```
Loading the story (parsing it, resolving its rules, and the validator's **error** checks) must fail, and the first error must be at `path`, written as in B2 (`nodes.door.choices[1].to`). Messages are not compared: each engine words its own.

## Coverage
Covered: pages, choices, locks and hidden choices, checks and their effects, tables, once nodes and once choices, death at 0 health, stat ceilings, limits and quantities, opposed and vs-defense combat, fleeing, usable items, pack capacity, containers, offers, item bonuses, conditional text and placeholders, the journal, undo, schema 6 authoring fields and draft pages, and the common load errors.

Not covered yet (good first contributions): character creation rolls and picks, simultaneous fights, armor, luck in fights, the results-table mode and duels, `takeAll`, audio events, translations (`compareTranslations`), validator warnings, `showTitles` beyond the title itself.

## Adding a case
One case, one idea. Work out the expected result **from the spec**, not from an engine, then run it on the Dart engine; if they disagree, find out which is wrong before committing. Name the file after what it shows.
