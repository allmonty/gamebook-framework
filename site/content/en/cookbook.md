# Cookbook

Ready-made recipes for scenes every gamebook needs. Each one is a tiny, complete story: play it, open Edit JSON, and copy the parts you need into your own book. The chapters that explain each piece are linked.

## The locked chest

*A chest that opens with a key or a lucky lockpick, and pays out only once.*

```gamebook
examples/cookbook/locked-chest
```

- Two choices lead to the same `open` page: one needs the key (`"if": { "has": "key" }`), the other is a skill check ([chapter 5](05-dice.md)).
- `"once": true` on the `open` page means the gold is given only the first time ([chapter 7](07-living-world.md)).
- The key is spent with `take` when used.

## The wandering merchant

*Buy and sell with a price, and show the reader their purse.*

```gamebook
examples/cookbook/wandering-merchant
```

- Buying needs `{ "stat": "gold", "gte": 5 }` and pays with `{ "stat": "gold", "add": -5 }`.
- Selling needs the item and gives gold back.
- `{gold}` in the text keeps the purse up to date ([chapter 7](07-living-world.md)). For many shops with different prices, keep the price in a stat ([chapter 4](04-stats-and-hero.md)).

## The hidden passage

*A secret that only sharp heroes see at once, and everyone else notices on a third look.*

```gamebook
examples/cookbook/hidden-passage
```

- The secret choice has `"hideIfLocked": true`, so it is invisible until its condition holds ([chapter 2](02-pages-and-choices.md)).
- The condition is `any` of Skill 11 or more, or a third visit to the library ([chapter 7](07-living-world.md)).
- A text part hints at it from the second visit on.

## The poison trap

*Damage that keeps hurting on every page until it is cured.*

```gamebook
examples/cookbook/poison-trap
```

- Failing the check sets the flag `poisoned` and offers an antidote whose `use` clears it ([chapter 3](03-items.md)).
- Every page after has two versions of "Walk on", both with `hideIfLocked`: one for the healthy (`not` poisoned), one for the poisoned that costs 2 Stamina. The reader only ever sees one.
- A text part reminds the poisoned reader why it hurts.

## The boss fight

*A boss with a guard, a plea for mercy, and a second, harder phase.*

```gamebook
examples/cookbook/boss-fight
```

- Phase one: the boss and his guard attack together (`simultaneous`), and the boss has `armor` ([chapter 6](06-combat.md)).
- Winning leads to a normal page with a moral choice, not straight to victory.
- Finishing him starts a second fight on its own page, with a stronger enemy and no way to flee.
- Fleeing from phase one is allowed, but it leads to a death ending: the price of running from a boss.

Have a recipe to share? The format is open: write it, validate it, and send it in.
