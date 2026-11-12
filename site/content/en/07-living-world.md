# A living world

Good gamebooks remember. The chest you emptied stays empty, the innkeeper recognizes you, the page mentions the gold in your purse, and your journal fills with clues. This chapter is about memory: once-only things, visit counts, flags, richer conditions, text that changes, the journal, achievements, audio and undo.

## Once only

```gamebook
examples/07-living-world/search-once
```

There are two kinds of "once":

- `"once": true` on a **page** makes its `effects` happen only the first time the reader arrives. The chest pays 5 gold once, however often you open it. Use it for every pickup and every heal, so revisiting cannot be farmed.
- `"once": true` on a **choice** makes the choice disappear after it is taken (schema 4). The nap is gone after one go.

## Flags, visits and conditions that combine

A **flag** is an on/off switch with any name you like. Effects `{ "set": "paid" }` and `{ "clear": "paid" }` switch it; the condition `{ "flag": "paid" }` tests it. You never declare flags; writing them is enough.

**Visits** count how many times the reader has entered a page: `{ "visits": "inn", "gte": 2 }` (schema 4). The start page counts as its first visit.

Conditions combine with `all` (every one is true), `any` (at least one is true) and `not`:

```gamebook
examples/07-living-world/the-innkeeper
```

```json
{ "text": "Go up to your room", "to": "room",
  "if": { "any": [ { "flag": "paid" }, { "visits": "inn", "gte": 4 } ] },
  "lockedText": "Pay first, or wear the innkeeper down." }
```

## Text that changes

A page's `text` can be a **list of parts** (schema 4). A plain string is always shown; an object with `if` is shown only while its condition holds. That is how the innkeeper greets a stranger the first time and an old friend after:

```json
"text": [
  "The Copper Kettle inn, warm and loud.",
  { "if": { "visits": "inn", "eq": 1 }, "text": "The innkeeper looks you over: a stranger." },
  { "if": { "visits": "inn", "gte": 2 }, "text": "\"Back again?\" the innkeeper says." }
]
```

### Numbers in text

Write a stat id in braces and the reader sees its current value (schema 4): `{gold}`, `{luck}`. `{luck.max}` is its ceiling. `{name}` is the hero's name when the story asks for one (chapter 4). It works in page text and in choice text:

```gamebook
examples/07-living-world/gold-counter
```

`{meal.count}` (schema 8) is how many of the item `meal` the reader carries: the provisions in chapter 3 count down with it.

To show real braces, write them twice: `{{` and `}}`.

## The journal and achievements

A `journal` at the top of the file lists entries the reader can unlock, each with a `title` and `text` (schema 5). The effect `{ "journal": "letter" }` unlocks one, once, and the log announces it. Unlocked entries appear in the journal panel, newest first.

**Achievements** (schema 7) are marks the reader keeps across games: replay value. Declare them in `achievements`, earn them with `{ "achieve": "scholar" }`. `"hidden": true` keeps an achievement secret until it is earned. They change nothing in the game itself.

```gamebook
examples/07-living-world/journal-clues
```

```json
"journal": { "letter": { "title": "The wizard's letter", "text": "\"The vault answers to the word EMBER.\"" } },
"achievements": { "scholar": { "title": "Scholar", "description": "Finished the study." } }
```

## Music and sound

A page can set music and sounds (schema 5):

```json
"crypt": { "text": "...", "music": "audio/crypt.ogg", "sound": "audio/door.wav", "choices": [ ... ] }
```

- `sound` plays once when the page is entered.
- `music` starts looping and keeps playing across pages until another page sets `music`, or `"music": "stop"` silences it.

Paths are relative to the story's folder, like images. Readers can turn audio off, so never hide something important only in a sound. (These examples are silent, to keep the site light.)

## Undo

`"undo": 1` in the rules lets the reader step back that many pages (schema 5). Everything returns to how it was before the choice: stats, items, flags, visits. Dice are rolled fresh if the same choice is taken again.

```gamebook
examples/07-living-world/undo-the-trap
```

Undo is generous: it even takes back a death. Leave it off for a classic, unforgiving book.

## Endings that are not a death

Caught at the border, lost in the woods, gone home: many adventures end without a win and without a death. Mark such a page `"ending": "defeat"` (schema 8). The reader is told the adventure is over, not that they died.

```gamebook
examples/07-living-world/captured
```

Two of its three endings are defeats, and the hero is alive in both. Health at 0 is still a death, whatever the page says.

### Try it

- In the inn, change `"gte": 4` to `"gte": 2`: the innkeeper gives in sooner.
- In the well, add a part `{ "if": { "stat": "luck", "gte": 12 }, "text": "You feel very lucky." }`.
- In the study, make the Cartographer achievement visible by removing `"hidden": true`.
- At the border, change the cell's `"defeat"` to `"death"` and see what the reader is told.

Next: making sure a long book has no broken links, and sharing it.
