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
        stat.min,
      ),
      final int value when stat.limit != null => StatValue(
        min(max(value, stat.min), stat.limit!),
        stat.limit,
        stat.min,
      ),
      final int value => StatValue(
        max(value, stat.min),
        stat.max ? max(value, stat.min) : null,
        stat.min,
      ),
      _ => throw ArgumentError('case gives no start value for "${stat.id}"'),
    },
};

/// The given start values, or (with no `stats`) the stats rolled from the
/// scripted dice, `rerolls` more times, keeping the last roll.
Map<String, StatValue> _startStats(
  Rules rules,
  Random random,
  Map<String, Object?> c,
) {
  if (c['stats'] case final Map<String, Object?> given) {
    return _stats(rules, given);
  }
  var stats = rules.rollStats(random);
  for (var i = 0; i < ((c['rerolls'] as int?) ?? 0); i++) {
    stats = rules.rollStats(random);
  }
  return stats;
}

/// The effects of the picked creation options: group by group, each group's
/// options in file order (B4).
List<Effect> _picked(Rules rules, Map<String, Object?>? picks) => [
  for (final group in rules.creation?.picks ?? const <PickGroup>[])
    for (final option in group.options)
      if ((picks?[group.id] as List<Object?>?)?.contains(option.id) ?? false)
        ...option.effects,
];

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

void _check(
  GameEngine engine,
  Map<String, Object?> want,
  List<GameEvent> events,
) {
  final s = engine.state;
  for (final MapEntry(:key, :value) in want.entries) {
    final actual = switch (key) {
      'node' => engine.node.id,
      'ending' => engine.ending?.name,
      'stats' => {
        for (final id in (value! as Map<String, Object?>).keys) id: s.stat(id),
      },
      'inventory' => _sorted(s.inventory),
      'counts' => {
        for (final id in (value! as Map<String, Object?>).keys) id: s.count(id),
      },
      'flags' => _sorted(s.flags),
      'visits' => {
        for (final id in (value! as Map<String, Object?>).keys)
          id: s.visits[id] ?? 0,
      },
      'journal' => s.journal,
      'offers' => s.offers,
      'returnTo' => s.returnTo,
      'paragraphs' => engine.paragraphs,
      'choices' => [
        for (final c in engine.choices)
          {'index': c.index, 'text': c.text, 'locked': c.locked},
      ],
      'title' => engine.node.title,
      'music' => s.music,
      'sounds' => [for (final e in events.whereType<SoundPlayed>()) e.file],
      'achieved' => [
        for (final e in events.whereType<AchievementEarned>()) e.achievement,
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

  group('lint', () {
    for (final (file, c) in _cases('lint')) {
      test('$file: ${c['description']}', () {
        final sources = (c['stories'] ?? {'only': c['story']}) as Map;
        final stories = [
          for (final json in sources.values)
            Story.fromJson(json! as Map<String, Object?>),
        ];
        final found = {
          for (final story in stories)
            for (final i in validateStory(story))
              if (i.severity == Severity.warning) '${i.code} ${i.where}',
          for (final other in stories.skip(1))
            for (final i in compareTranslations(stories.first, other))
              '${i.code} ${i.where}',
        };
        expect(found, {
          for (final w in c['warnings']! as List<Object?>)
            if (w case {'code': final String code, 'path': final String path})
              '$code $path',
        });
      });
    }
  });

  group('play', () {
    for (final (file, c) in _cases('play')) {
      test('$file: ${c['description']}', () {
        final story = Story.fromJson(c['story']! as Map<String, Object?>);
        final rules = Rules.resolve(story.rules);
        final random = ScriptedRandom((c['dice']! as List<Object?>).cast());
        final (engine, started) = GameEngine.newGame(
          story: story,
          rules: rules,
          random: random,
          stats: _startStats(rules, random, c),
          name: c['name'] as String?,
          creationEffects: _picked(rules, c['picks'] as Map<String, Object?>?),
        );
        final events = [...started];
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
            events.addAll(_act(engine, action));
          }
        }
        _check(engine, c['expect']! as Map<String, Object?>, events);
        expect(random.remaining, 0, reason: 'every scripted die is used');
      });
    }
  });
}
