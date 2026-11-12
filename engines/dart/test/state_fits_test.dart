import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

Story story({void Function(Map<String, Object?>)? mutate}) {
  final json = jsonDecode(
    File('test/fixtures/rusty-door.en.json').readAsStringSync(),
  ) as Map<String, Object?>;
  mutate?.call(json);
  return Story.fromJson(json);
}

const stats = {
  'skill': StatValue(9, 9),
  'stamina': StatValue(20, 20),
  'luck': StatValue(8, 8),
};

const saved = GameState(
  node: 'door',
  stats: stats,
  inventory: {'rusty-key'},
  visited: {'cellar', 'shelves', 'door'},
  visits: {'cellar': 2, 'shelves': 1, 'door': 1},
);

bool fits(GameState state, [Story? s]) {
  final st = s ?? story();
  return stateFits(state, st, Rules.resolve(st.rules));
}

Map<String, Object?> nodes(Map<String, Object?> j) =>
    j['nodes']! as Map<String, Object?>;

void main() {
  test('a save of the same story fits', () {
    expect(fits(saved), isTrue);
  });

  test('a new game fits', () {
    final s = story();
    final (engine, _) = GameEngine.newGame(
      story: s,
      rules: Rules.resolve(s.rules),
      random: Random(1),
      stats: stats,
    );
    expect(fits(engine.state, s), isTrue);
  });

  final changes = <String, (GameState, void Function(Map<String, Object?>)?)>{
    'the current page is gone': (saved, (j) => nodes(j).remove('door')),
    'a visited page is gone': (
      saved.copyWith(node: 'cellar'),
      (j) => nodes(j).remove('shelves'),
    ),
    'a carried item is gone': (saved, (j) => j.remove('items')),
    'an offered item is gone': (saved.copyWith(offers: ['lamp']), null),
    'a stat is gone': (saved.copyWith(stats: {...stats}..remove('luck')), null),
    'a stat was added': (
      saved.copyWith(stats: {...stats, 'gold': const StatValue(0)}),
      null,
    ),
    'a journal entry is gone': (saved.copyWith(journal: ['clue']), null),
    'a taken once-only choice is gone': (
      saved.copyWith(taken: {'door#5'}),
      null,
    ),
    'a stat is below 0': (
      saved.copyWith(stats: {...stats, 'luck': const StatValue(-5, 8)}),
      null,
    ),
    'a stat is above its ceiling': (
      saved.copyWith(stats: {...stats, 'luck': const StatValue(9, 8)}),
      null,
    ),
    'a count is kept for an item that cannot be counted': (
      saved.copyWith(counts: {'rusty-key': 2}),
      null,
    ),
    'a count is kept for an item not held': (
      saved.copyWith(inventory: {}, counts: {'rusty-key': 2}),
      (j) =>
          (j..['schema'] = 1)['items']! as Map<String, Object?>
            ..['rusty-key'] = {'name': 'Key', 'stack': 3},
    ),
    'a count is below 1': (
      saved.copyWith(counts: {'rusty-key': 0}),
      (j) =>
          (j..['schema'] = 1)['items']! as Map<String, Object?>
            ..['rusty-key'] = {'name': 'Key', 'stack': 3},
    ),
    'a count is above the item\'s cap': (
      saved.copyWith(counts: {'rusty-key': 5}),
      (j) =>
          (j..['schema'] = 1)['items']! as Map<String, Object?>
            ..['rusty-key'] = {'name': 'Key', 'stack': 3, 'max': 4},
    ),
    'the pack holds more than it has room for': (
      saved.copyWith(counts: {'rusty-key': 7}),
      (j) {
        j['schema'] = 1;
        j['rules'] = {
          'preset': 'fighting-fantasy',
          'inventory': {'capacity': 1},
        };
        (j['items']! as Map<String, Object?>)['rusty-key'] = {
          'name': 'Key',
          'stack': 3,
        };
      },
    ),
    'a taken choice has a negative index': (
      saved.copyWith(taken: {'door#-2'}),
      null,
    ),
    'a page was visited 0 times': (
      saved.copyWith(visits: {...saved.visits, 'door': 0}),
      null,
    ),
    'a fight is under way on a page without one': (
      saved.withCombat(const CombatState(0, [3])),
      null,
    ),
  };
  for (final MapEntry(:key, value: (state, mutate)) in changes.entries) {
    test('does not fit when $key', () {
      expect(fits(state, story(mutate: mutate)), isFalse);
    });
  }

  test('a fight must still match the enemies of its page', () {
    Story arena({int enemies = 1}) => story(
      mutate: (j) => nodes(j)['door'] = {
        'text': 'A rat.',
        'combat': {
          'enemies': [
            for (var i = 0; i < enemies; i++)
              {'name': 'Rat $i', 'attack': 1, 'health': 2},
          ],
          'win': 'treasure',
        },
      },
    );
    final fighting = saved.withCombat(const CombatState(0, [2]));
    expect(fits(fighting, arena()), isTrue);
    expect(fits(fighting, arena(enemies: 2)), isFalse);
  });

  group('a fight with impossible numbers does not fit', () {
    final arena = story(
      mutate: (j) => nodes(j)['door'] = {
        'text': 'Two rats.',
        'combat': {
          'enemies': [
            {'name': 'Rat', 'attack': 1, 'health': 2},
            {'name': 'Big rat', 'attack': 1, 'health': 4},
          ],
          'win': 'treasure',
        },
      },
    );
    LuckChance luck({int enemy = 0, int dealt = 2, int taken = 0}) =>
        LuckChance(enemy: enemy, dealt: dealt, taken: taken);

    final bad = <String, CombatState>{
      'the enemy index is negative': const CombatState(-1, [2, 4]),
      'the round count is negative': const CombatState(0, [2, 4], null, -1),
      'an enemy health is negative': const CombatState(0, [-3, 4]),
      'an enemy health is above its start': const CombatState(0, [2, 5]),
      'the luck test names a negative enemy': CombatState(0, [
        2,
        4,
      ], luck(enemy: -1)),
      'the luck test names an enemy past the list': CombatState(0, [
        2,
        4,
      ], luck(enemy: 2)),
      'the luck test has a negative wound dealt': CombatState(0, [
        2,
        4,
      ], luck(dealt: -1)),
      'the luck test has a negative wound taken': CombatState(0, [
        2,
        4,
      ], luck(taken: -1)),
    };
    for (final MapEntry(:key, value: fight) in bad.entries) {
      test(key, () {
        expect(fits(saved.withCombat(fight), arena), isFalse);
      });
    }

    test('a fight saved with an open luck test still fits', () {
      final fight = CombatState(1, [0, 3], luck(enemy: 1, dealt: 1, taken: 2));
      final reloaded = GameState.fromJson(
        jsonDecode(jsonEncode(saved.withCombat(fight).toJson()))
            as Map<String, Object?>,
      );
      expect(fits(reloaded, arena), isTrue);
    });
  });
}
