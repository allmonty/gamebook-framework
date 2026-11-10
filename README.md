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

## Why another format
Ink and Twine are great for branching text, but have no stats, dice or inventory built in, and Twine's output is a web page rather than data. ChoiceScript has license limits. This format is plain, strict data that any language can parse, statically check (broken links, unreachable pages, items never given) and play the same way everywhere. The full comparison: [spec/comparison.md](spec/comparison.md).

## What is here
| Path | What |
|---|---|
| [spec/framework.md](spec/framework.md) | **The spec.** Part A explains gamebooks and the format to anyone; Part B is the exact reference |
| [spec/CHANGELOG.md](spec/CHANGELOG.md) | what each `schema` version adds |
| [spec/story.schema.json](spec/story.schema.json) | JSON Schema (shape only) for editors and quick checks |
| [conformance/](conformance/README.md) | language-neutral test cases with scripted dice: the definition of "plays it right" |
| [engines/](engines/README.md) | engines; the reference one is [Dart](engines/dart/README.md) (with a validator and graph CLI) |
| [CONTRIBUTING.md](CONTRIBUTING.md) | how to change the spec or add an engine |

## Status
Schema versions 1 to 6 are specified. The Dart engine, which runs the gamebook app for iOS and Android (not public yet), implements all of them; `.gamebook` packages (B14) are specified and not implemented yet.

## License
The spec text is [CC BY 4.0](LICENSE-CC-BY-4.0); code, the JSON Schema and the conformance cases are [MIT](LICENSE-MIT). Details: [LICENSE](LICENSE).
