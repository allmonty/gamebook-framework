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
}
