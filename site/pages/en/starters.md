# Starter games

Eight complete gamebooks to play here and then make your own. Each is short, original and written to be copied: it shows one way of building a book, with the fields that way needs.

For each one:

- **Play** it right on this page.
- **See** how it is written on the **Edit JSON** tab, and change it: the game restarts with your version.
- **Use** it: press **Download** on the Edit JSON tab to save the file, or copy the whole folder from GitHub, in English and Portuguese.

The [tutorial](tutorial/index.html) explains every field you will meet.

## Blank

The smallest valid game: three pages and one ending, on the Fighting Fantasy preset. Start here when you already know what you want to write.

```gamebook
../starters/blank/story
```

What it shows:

- a page with a choice, a page in the middle, an ending
- the fields every story needs, and nothing else

The folder to copy: [`starters/blank`](https://github.com/allmonty/gamebook-framework/tree/main/starters/blank).

## The Salt Mine

The classic shape: Skill, Stamina and Luck, a fight, a Luck test, provisions you eat from your pack and a door that needs a key.

```gamebook
../starters/fighting-fantasy/story
```

What it shows:

- the `fighting-fantasy` preset as it comes
- an opposed fight and Testing your Luck
- a counted item (`stack`) you can use
- all three endings: victory, death and defeat

The folder to copy: [`starters/fighting-fantasy`](https://github.com/allmonty/gamebook-framework/tree/main/starters/fighting-fantasy).

## The Archive at Night

No preset: the story defines its own two stats, says which one is health and how fights work.

```gamebook
../starters/custom-rules/story
```

What it shows:

- `rules` written in full: `stats`, `health`, `combat`
- a dice check that adds a stat
- a fight under your own rules

The folder to copy: [`starters/custom-rules`](https://github.com/allmonty/gamebook-framework/tree/main/starters/custom-rules).

## The Ash Road

Fights are read off a results table instead of dice against dice. You pick two arts at the start, carry a pack of eight, and must eat.

```gamebook
../starters/results-table/story
```

What it shows:

- `"mode": "table"` combat with its table
- picks at character creation, each setting a flag
- a pack with `capacity`, a container, counted meals with a `max`
- a bonus that depends on a condition (unarmed, or the sword with the right art)
- healing on every page without a fight (`everyPage`, `calm`)
- fleeing that costs a round

The folder to copy: [`starters/results-table`](https://github.com/allmonty/gamebook-framework/tree/main/starters/results-table).

## The Clockmaker's Will

A mystery with no fights at all. Skills run from 30 to 75 and you roll 1d100 under them; clues go into the journal until you can name the forger.

```gamebook
../starters/percentile-mystery/story
```

What it shows:

- a story with no `combat` in its rules
- `1d100` checks with `lte` against a stat, each allowed once
- the journal as a board of clues
- flags that open what people say, and text that changes with what you know
- two defeats and a victory, and no death

The folder to copy: [`starters/percentile-mystery`](https://github.com/allmonty/gamebook-framework/tree/main/starters/percentile-mystery).

## Market Day at Three Bridges

A town you come back to. One shop is reached from two places and sends you back where you came from; you buy, sell and swap what you carry.

```gamebook
../starters/hub-and-shop/story
```

What it shows:

- `call` and `return`: one shop, many ways in
- a price kept in a hidden stat, and one "Buy it" that pays whatever it says
- a pack of three with `"pickup": "choose"`: a fourth thing is a swap
- text that changes with `visits`, and a job you can do only `once`
- a way to win that needs no item, because an offered item can be left

The folder to copy: [`starters/hub-and-shop`](https://github.com/allmonty/gamebook-framework/tree/main/starters/hub-and-shop).

## The Sunken Chapel

A small dungeon on the d20-lite preset, changed rather than taken whole: two enemies at once, an armored boss and rising water.

```gamebook
../starters/d20-dungeon/story
```

What it shows:

- a preset with one stat changed (`min` below zero) and one added
- a random `table`, an item with a `bonus` and one with a curse
- usable items: one free in a fight, one that costs the round
- a `simultaneous` fight, `armor`, an enemy with its own `damage`
- a fight that ends after six `rounds`, won or not

The folder to copy: [`starters/d20-dungeon`](https://github.com/allmonty/gamebook-framework/tree/main/starters/d20-dungeon).

## The Lighthouse Year

The skeleton of a long book: structure rather than rules. Copy it when you are about to write two hundred pages.

```gamebook
../starters/long-book/story
```

What it shows:

- `chapters`, and a `chapter` on every page
- page titles the reader sees (`showTitles`) and a `note` only you see
- a journal entry and two achievements, one `hidden`
- `undo`, so the hard choice can be taken both ways

The folder to copy: [`starters/long-book`](https://github.com/allmonty/gamebook-framework/tree/main/starters/long-book).

## Making one yours

Copy the folder, rename it, and change the `id` in every language file to the same new name. Then check your story as you write: [chapter 8](tutorial/08-check-and-publish.html) shows the checker and the tools.
