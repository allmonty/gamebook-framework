# gamebook_engine (Dart)

The reference engine for the [Gamebook Framework](../../README.md) format: pure Dart, no Flutter and no I/O in `lib/`, randomness injected. It powers the gamebook app and its Builder, and is where the format is tried first.

Supports schema version 1 ([../../spec/CHANGELOG.md](../../spec/CHANGELOG.md)).

## Use
```yaml
dependencies:
  gamebook_engine:
    git: { url: https://github.com/allmonty/gamebook-framework.git, path: engines/dart }
```
```dart
final story = Story.parse(json);                  // throws StoryFormatException naming the JSON path
final issues = validateStory(story);              // cross-reference checks: errors and warnings
final (engine, events) = GameEngine.newGame(
  story: story, rules: Rules.resolve(story.rules), random: Random(), stats: rolledStats);
engine.choose(0);                                 // returns the events of what happened
```
| Library | Holds |
|---|---|
| `story.dart` | models and parser (spec B1-B13) |
| `schema_gate.dart` | the schema-version gate: the first thing a story uses that its `schema` does not have (B2) |
| `rules.dart`, `rules_spec.dart` | presets and rule resolution (B4) |
| `engine.dart`, `state.dart` | the game state machine and its events (B10, B11) |
| `dice.dart`, `condition.dart`, `effect.dart`, `check.dart`, `combat.dart`, `quantity.dart`, `text.dart` | the parts |
| `validate.dart` | the validator, also comparing translations |
| `graph.dart` | the story as Graphviz DOT or Mermaid |
| `simulate.dart` | plays a story many times at random and reports win and death rates, dead ends, endless loops, endings and pages never reached |
| `twine.dart` | converts a Twine story (Twee 3 or a published Twine 2 file) into this format, with a report of what could not be converted |
| `package.dart` | `.gamebook` packages: read with every B14 check, write (B14) |

## Tools
```
dart run gamebook_engine:validate_story <dir|file>... [--strict] [--llm]   # --llm: a message to paste back to a chatbot
dart run gamebook_engine:story_graph <story.json> [--mermaid]
dart run gamebook_engine:pack_game <game-folder> [out.gamebook]
dart run gamebook_engine:simulate_story <story.json> [--games N] [--policy random|explore|decline] [--seed N]   # exits 1 on dead ends or endless games
dart run gamebook_engine:import_twine <story.twee|story.html> <out-folder> [--lang en]   # writes story.<lang>.json and builder.json, prints what was not converted
dart run gamebook_engine:llm_kit [--check]                                # regenerates ../../spec/llm-kit.md (run from this folder)
```

## Develop
```
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```
Tests never sleep and seed or script the dice (`test/support/scripted_random.dart`). Rules for changes: [../../CONTRIBUTING.md](../../CONTRIBUTING.md).
