# Combat

A fight is a page of its own. Instead of choices it has `combat`: the enemies, where to go when you win and, if you allow it, where to run. The reader fights round by round with the Attack button, and the rules decide how each round goes.

## A fight, round by round

```gamebook
examples/06-combat/goblin-guard
```

```json
"fight": {
  "text": "The goblin snarls and lunges.",
  "combat": {
    "enemies": [ { "name": "Goblin guard", "attack": 6, "health": 5 } ],
    "win": "won",
    "flee": "fled"
  }
}
```

- `enemies`: each with a `name`, an `attack` score and `health`. Several enemies are fought one after another, in order.
- `win`: the page entered when the last enemy falls.
- `flee` (optional): the page you run to. There is no automatic penalty for running; put it in that page's `effects`, as the example does with -2 Stamina. Without `flee`, there is no escape.

With the Fighting Fantasy rules each round is **opposed**: you roll 2d6 + Skill, the enemy rolls 2d6 + its `attack`, and the lower total loses 2 health. A tie hurts nobody. If your health reaches 0, the story ends in death.

The tonic shows **items in fights**: its `use` has `"when": ["story", "combat"]`, so the Use button works mid-fight. Using it costs your attack that round, and the enemy hits you for free. Add `"combatCost": "free"` to an item that should not.

## Versus defense: the d20 way

With `d20-lite` rules each round is **versus defense**: you roll 1d20 + Might, and hit if you reach the enemy's `defense`; then the enemy rolls 1d20 + its `attack` against 10 + your Agility. Hits deal damage dice, 1d6 by default.

```gamebook
examples/06-combat/d20-skirmish
```

```json
"enemies": [ { "name": "Rust-bandit", "attack": 2, "defense": 11, "health": 6, "damage": "1d4" } ]
```

`defense` is required in this mode. `damage` on an enemy overrides the rules' damage for that enemy only.

## Several enemies at once, armor and luck

```gamebook
examples/06-combat/golem-and-rat
```

- `"simultaneous": true` on the fight: every living enemy attacks every round, and the reader **chooses a target** each round (schema 5).
- `"armor": 1` on an enemy: your blows deal 1 less to it, never less than 0.
- `"luck": { "stat": "luck" }` in the rules' `combat` turns on **Testing your Luck in fights**: after a round where someone was hurt, the reader may roll 2d6 against Luck. Lucky, your wound on the enemy grows by 2 or the wound you took shrinks by 1; unlucky, the reverse. Luck drops by 1 either way.

```json
"rules": { "preset": "fighting-fantasy", "combat": { "luck": { "stat": "luck" } } }
```

## Results tables and duels

Lone Wolf books resolve fights with a **results table** instead of dice against dice. The difference between your fighting stat and the enemy's (the *combat ratio*) picks a row; a roll of `1d10-1` (0 to 9) picks a column; each cell says how much both sides lose that round.

You can make a whole story fight this way with `"mode": "table"` in the rules' `combat`, or, as here, keep normal fights and mark a set-piece fight as a `duel`:

```gamebook
examples/06-combat/duel-table
```

```json
"rules": { "preset": "fighting-fantasy",
  "combat": { "roll": "1d10-1", "table": [
    { "upTo": -3, "results": [[0,4],[0,3],[1,3],[1,2],[2,2],[2,2],[3,1],[3,1],[4,0],[4,0]] },
    { "upTo": 3,  "results": [[1,2],[2,2],[2,1],[3,1],[3,1],[4,1],[4,0],[5,0],[5,0],[6,0]] },
    {             "results": [[3,1],[4,1],[5,0],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[99,0]] }
  ] } }
```

Each pair is `[enemy loses, you lose]`. A row covers every ratio up to its `upTo`; the last row has none and takes everything above. Every row needs one pair per possible roll, ten here. The fight in the hall has `"duel": true`; the sparring drone in the yard still fights the usual way.

## Fights that end early

Gamebooks love "if the creature wounds you, turn to 55" and "if you have not won after three rounds, turn to 120". Two fields on `combat` say it (schema 8):

```gamebook
examples/06-combat/poison-sting
```

```json
"combat": {
  "enemies": [ { "name": "Giant scorpion", "attack": 7, "health": 6 } ],
  "win": "won",
  "wounded": "stung",
  "rounds": { "after": 3, "to": "gone" }
}
```

- `wounded`: the first time the scorpion hurts you, and you are still alive, the fight stops and `stung` follows.
- `rounds`: once 3 rounds are played without a winner, the fight stops and `gone` follows. "Win within three rounds" is written the same way.

After each round the order is: death, then the win, then a wound, then the round limit. An item that costs the round counts as a round, and the enemy's free hit as a wound. To escape at a price you need nothing new: that is `flee` with an effect on the page you run to, as the goblin guard shows.

### Try it

- Give the goblin `"health": 12` and see how long the fight gets. Remove `flee` and the Flee button disappears.
- Give the golem `"armor": 2`: now only lucky blows hurt it.
- Remove `"duel": true` from the Champion and fight him with dice instead.
- Remove `wounded` from the scorpion: its sting is now just a wound, and the fight goes on.

Next: making the world remember what the reader did.
