import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

Map<String, Object?> rusty() =>
    jsonDecode(File('test/fixtures/rusty-door.en.json').readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?> node(Map<String, Object?> j, String id) =>
    (j['nodes']! as Map<String, Object?>)[id]! as Map<String, Object?>;

/// The rusty door with a "found the key" and a hidden "won" achievement.
Map<String, Object?> achieving() {
  final j = rusty()
    ..['schema'] = 7
    ..['achievements'] = {
      'keyed': {'title': 'Keyed', 'description': 'Found the key.'},
      'won': {'title': 'Rich', 'hidden': true},
    };
  (node(j, 'shelves')['effects']! as List).add({'achieve': 'keyed'});
  node(j, 'treasure')['effects'] = [
    {'achieve': 'won'},
  ];
  return j;
}

void main() {
  test('achievements are read', () {
    final story = Story.fromJson(achieving());
    expect(story.achievements.keys, ['keyed', 'won']);
    expect(story.achievements['keyed']!.description, 'Found the key.');
    expect(story.achievements['won']!.hidden, isTrue);
  });

  test('they need schema 7', () {
    for (final (path, mutate)
        in <(String, void Function(Map<String, Object?>))>[
          (
            'achievements',
            (j) => j['achievements'] = {
              'a': {'title': 'A'},
            },
          ),
          (
            'nodes.cellar.effects[0]',
            (j) => node(j, 'cellar')['effects'] = [
              {'achieve': 'a'},
            ],
          ),
        ]) {
      final j = rusty()..['schema'] = 6;
      mutate(j);
      expect(
        () => Story.fromJson(j),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => '$e',
            'message',
            '$path: needs "schema": 7',
          ),
        ),
      );
    }
  });

  test('earning one is an event and changes nothing in the game', () {
    final story = Story.fromJson(achieving());
    final rules = Rules.resolve(story.rules);
    final (engine, _) = GameEngine.newGame(
      story: story,
      rules: rules,
      random: Random(1),
      stats: rules.rollStats(Random(1)),
    );
    final before = jsonEncode(engine.state.toJson());
    final events = engine.choose(0); // the shelves

    expect(events.whereType<AchievementEarned>().map((e) => e.achievement), [
      'keyed',
    ]);
    final after = GameState.fromJson(engine.state.toJson());
    expect(after.inventory, {'rusty-key'});
    expect(jsonEncode(engine.state.toJson()), isNot(before));
    expect(jsonEncode(engine.state.toJson()), isNot(contains('keyed')));
  });

  test('the validator checks them', () {
    final j = achieving()
      ..['achievements'] = {
        'keyed': {'title': 'Keyed'},
        'lonely': {'title': 'Never earned'},
      };
    final issues = [for (final i in validateStory(Story.fromJson(j))) '$i'];
    expect(
      issues,
      contains('error: nodes.treasure.effects[0]: unknown achievement "won"'),
    );
    expect(issues, contains('warning: achievements.lonely: is never earned'));
  });

  test('translations keep the same achievements', () {
    final pt = achieving()
      ..['lang'] = 'pt'
      ..['achievements'] = {
        'keyed': {'title': 'Com a chave'},
        'won': {'title': 'Rico', 'hidden': true},
        'extra': {'title': 'Extra'},
      };
    (node(pt, 'cellar')['effects'] = <Object?>[]);
    expect([
      for (final i in compareTranslations(
        Story.fromJson(achieving()),
        Story.fromJson(pt),
      ))
        '$i',
    ], contains('warning: pt: achievement "extra" exists in pt but not in en'));
  });
}
