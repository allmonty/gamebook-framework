# gamebook_engine (Dart)

The reference engine for the [Gamebook Framework](../../README.md) format: pure Dart, no Flutter and no I/O in `lib/`, randomness injected. It powers the gamebook app and its Builder, and is where the format is tried first.

Supports schema versions 1 to 6, except draft pages (B13) so far ([../../spec/CHANGELOG.md](../../spec/CHANGELOG.md)).

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
| `rules.dart`, `rules_spec.dart` | presets and rule resolution (B4) |
| `engine.dart`, `state.dart` | the game state machine and its events (B10, B11) |
| `dice.dart`, `condition.dart`, `effect.dart`, `check.dart`, `combat.dart`, `quantity.dart`, `text.dart` | the parts |
| `validate.dart` | the validator, also comparing translations |
| `graph.dart` | the story as Graphviz DOT or Mermaid |

## Tools
```
dart run gamebook_engine:validate_story <dir|file>... [--strict]
dart run gamebook_engine:story_graph <story.json> [--mermaid]
```

## Develop
```
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```
Tests never sleep and seed or script the dice (`test/support/scripted_random.dart`). Rules for changes: [../../CONTRIBUTING.md](../../CONTRIBUTING.md).
