// Runs the language-neutral conformance cases in ../../conformance against
// this engine. The case format is ../../conformance/README.md.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

const _root = '../../conformance/cases';

List<(String, Map<String, Object?>)> _cases(String kind) {
  final files = Directory('$_root/$kind').listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      if (f.path.endsWith('.json'))
        (
          f.uri.pathSegments.last,
          jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
        ),
  ];
}

/// The JSON path of the first reason [json] cannot be loaded, or null.
String? _rejection(Map<String, Object?> json) {
  try {
    final story = Story.fromJson(json);
    Rules.resolve(story.rules);
    final errors = validateStory(story)
        .where((i) => i.severity == Severity.error);
    return errors.isEmpty ? null : errors.first.where;
  } on StoryFormatException catch (e) {
    return e.path;
  }
}

Map<String, StatValue> _stats(Rules rules, Map<String, Object?> given) => {
  for (final stat in rules.stats)
    stat.id: switch (given[stat.id]) {
      {'value': final int value, 'max': final int? max} => StatValue(
        value,
        max,
      ),
      final int value when stat.limit != null => StatValue(
        min(value, stat.limit!),
        stat.limit,
      ),
      final int value => StatValue(value, stat.max ? value : null),
      _ => throw ArgumentError('case gives no start value for "${stat.id}"'),
    },
};

List<GameEvent> _act(GameEngine engine, Map<String, Object?> action) {
  final MapEntry(key: name, value: arg) = action.entries.firstWhere(
    (e) => e.key != 'rejected',
  );
  final args = arg is Map<String, Object?> ? arg : const <String, Object?>{};
  return switch (name) {
    'choose' => engine.choose(arg! as int),
    'fight' => engine.fight(target: args['target'] as int?),
    'flee' => engine.flee(),
    'testLuck' => engine.testLuck(),
    'use' => engine.useItem(arg! as String),
    'offer' => engine.resolveOffer(
      take: args['take']! as bool,
      replacing: args['replacing'] as String?,
    ),
    'undo' => engine.undo(),
    _ => throw ArgumentError('unknown action "$name"'),
  };
}

List<String> _sorted(Iterable<String> s) => s.toList()..sort();

void _check(GameEngine engine, Map<String, Object?> want) {
  final s = engine.state;
  for (final MapEntry(:key, :value) in want.entries) {
    final actual = switch (key) {
      'node' => engine.node.id,
      'ending' => engine.ending?.name,
      'stats' => {
        for (final id in (value! as Map<String, Object?>).keys) id: s.stat(id),
      },
      'inventory' => _sorted(s.inventory),
      'flags' => _sorted(s.flags),
      'visits' => {
        for (final id in (value! as Map<String, Object?>).keys)
          id: s.visits[id] ?? 0,
      },
      'journal' => s.journal,
      'offers' => s.offers,
      'paragraphs' => engine.paragraphs,
      'choices' => [
        for (final c in engine.choices)
          {'index': c.index, 'text': c.text, 'locked': c.locked},
      ],
      'combat' =>
        s.combat == null
            ? null
            : {'enemy': s.combat!.enemy, 'health': s.combat!.enemyHealth},
      _ => throw ArgumentError('unknown expectation "$key"'),
    };
    expect(actual, value, reason: key);
  }
}

void main() {
  group('invalid', () {
    for (final (file, c) in _cases('invalid')) {
      test('$file: ${c['description']}', () {
        final error = c['error']! as Map<String, Object?>;
        expect(_rejection(c['story']! as Map<String, Object?>), error['path']);
      });
    }
  });

  group('play', () {
    for (final (file, c) in _cases('play')) {
      test('$file: ${c['description']}', () {
        final story = Story.fromJson(c['story']! as Map<String, Object?>);
        final rules = Rules.resolve(story.rules);
        final random = ScriptedRandom((c['dice']! as List<Object?>).cast());
        final (engine, _) = GameEngine.newGame(
          story: story,
          rules: rules,
          random: random,
          stats: _stats(rules, c['stats']! as Map<String, Object?>),
          name: c['name'] as String?,
        );
        for (final (i, a) in (c['actions']! as List<Object?>).indexed) {
          final action = a! as Map<String, Object?>;
          if (action['rejected'] == true) {
            final before = jsonEncode(engine.state.toJson());
            expect(
              () => _act(engine, action),
              throwsA(anyOf(isA<StateError>(), isA<RangeError>())),
              reason: 'action $i should be rejected',
            );
            expect(jsonEncode(engine.state.toJson()), before);
          } else {
            _act(engine, action);
          }
        }
        _check(engine, c['expect']! as Map<String, Object?>);
        expect(random.remaining, 0, reason: 'every scripted die is used');
      });
    }
  });
}
