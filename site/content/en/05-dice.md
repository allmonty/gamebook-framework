# Dice

A gamebook without dice is a choose-your-path story. With dice, the reader's stats start to matter: a skilled hero leaps the gap more often, a lucky one dodges the dart. This chapter covers dice checks, Testing your Luck and random outcome tables.

## Dice notation

Wherever the format wants dice, you write them like a tabletop player would:

| Write | Means |
|---|---|
| `1d6` | one six-sided die: 1 to 6 |
| `2d6` | two six-sided dice added: 2 to 12 |
| `2d6+6` | two dice plus 6: 8 to 18 |
| `1d20` | a twenty-sided die |
| `2d6-1` | two dice minus 1 |
| `3` | always 3, no roll |

The player always shows the dice rolled, like rolling them on the table.

## Checks: pass or fail

A choice with a `check` instead of `to` rolls dice and sends the reader to one of two pages:

```gamebook
examples/05-dice/jump-the-gap
```

```json
{ "text": "Leap it (2d6 + Skill, 16 or more)",
  "check": { "roll": "2d6", "add": "skill", "op": "gte", "vs": 16, "pass": "across", "fail": "fall" } }
```

- `roll`: the dice.
- `add`: a stat to add (its current value, item bonuses included) or a plain number like `3`. Leave it out to add nothing.
- `op` and `vs`: `gte` passes when the total is `vs` or more; `lte` passes when it is `vs` or less. `vs` can be a number or a stat.
- `pass` and `fail`: the pages to go to.

Tell the reader what they are rolling in the choice text, as the example does: "(2d6 + Skill, 16 or more)". Checks are drawn in amber so readers can tell a risk from a plain choice. After the roll, the log shows the dice and the total.

## Test your Luck

In Fighting Fantasy, Testing your Luck means rolling two dice and hoping to get your Luck or less, and every test uses up a point of Luck, whatever the result. That is a check whose `vs` is a stat, with `effects`:

```gamebook
examples/05-dice/test-your-luck
```

```json
"check": { "roll": "2d6", "op": "lte", "vs": "luck",
           "effects": [ { "stat": "luck", "add": -1 } ],
           "pass": "safe", "fail": "hit" }
```

A check's `effects` apply after the roll whichever way it went, and the roll itself uses the stats from before them. Play it a few times and watch Luck drain.

## Random outcome tables

When there are more than two outcomes, use a `table`. The die picks the first outcome whose `upTo` is at least the roll:

```gamebook
examples/05-dice/search-the-rubble
```

```json
"table": { "roll": "1d6", "outcomes": [
  { "upTo": 2, "to": "nothing" },
  { "upTo": 5, "to": "coins", "effects": [ { "stat": "gold", "add": 3 } ] },
  { "upTo": 6, "to": "gem",   "effects": [ { "give": "gem" } ] }
] }
```

So 1 or 2 finds nothing, 3 to 5 finds coins, 6 finds the gem. `upTo` must go up from one outcome to the next, and the last one must cover the highest roll; the checker tells you if not. Each outcome may have its own `effects`.

### Try it

- Make the leap easier: change `vs` to `12`. Or harder, with `"add": 0`.
- Give the luck test a softer failure by editing the `hit` page.
- Turn the rubble into a `2d6` table with four outcomes. Remember the last `upTo` must be at least 12.

Next: the fights.
