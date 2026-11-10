import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

GameState state({
  Set<String> inventory = const {},
  Set<String> flags = const {},
  Set<String> visited = const {},
  Map<String, int> visits = const {},
}) => GameState(
  node: 'a',
  stats: const {
    'skill': StatValue(8, 10),
    'stamina': StatValue(5, 20),
    'gold': StatValue(0),
  },
  inventory: inventory,
  flags: flags,
  visited: visited,
  visits: visits,
);

Condition cond(Map<String, Object?> json) => Condition.fromJson(json, '');

void main() {
  group('evaluate', () {
    test('has, flag, visited', () {
      final s = state(inventory: {'key'}, flags: {'met'}, visited: {'n1'});
      expect(evaluate(cond({'has': 'key'}), s), isTrue);
      expect(evaluate(cond({'has': 'sword'}), s), isFalse);
      expect(evaluate(cond({'flag': 'met'}), s), isTrue);
      expect(evaluate(cond({'flag': 'angry'}), s), isFalse);
      expect(evaluate(cond({'visited': 'n1'}), s), isTrue);
      expect(evaluate(cond({'visited': 'n2'}), s), isFalse);
    });

    test('visits compare how many times a node was entered', () {
      final s = state(visits: {'inn': 3});
      expect(evaluate(cond({'visits': 'inn', 'gte': 3}), s), isTrue);
      expect(evaluate(cond({'visits': 'inn', 'gte': 4}), s), isFalse);
      expect(evaluate(cond({'visits': 'inn', 'lte': 3}), s), isTrue);
      expect(evaluate(cond({'visits': 'inn', 'eq': 3}), s), isTrue);
      expect(evaluate(cond({'visits': 'inn', 'eq': 2}), s), isFalse);
      expect(evaluate(cond({'visits': 'never', 'eq': 0}), s), isTrue);
    });

    test('stat comparisons use the current value', () {
      final s = state();
      expect(evaluate(cond({'stat': 'skill', 'gte': 8}), s), isTrue);
      expect(evaluate(cond({'stat': 'skill', 'gte': 9}), s), isFalse);
      expect(evaluate(cond({'stat': 'stamina', 'lte': 5}), s), isTrue);
      expect(evaluate(cond({'stat': 'stamina', 'lte': 4}), s), isFalse);
      expect(evaluate(cond({'stat': 'gold', 'eq': 0}), s), isTrue);
      expect(evaluate(cond({'stat': 'gold', 'eq': 1}), s), isFalse);
    });

    test('a stat can be compared with another stat, with a multiplier', () {
      final s = GameState(
        node: 'a',
        stats: const {
          'gold': StatValue(12),
          'price': StatValue(5),
          'luck': StatValue(3),
        },
      );
      Condition c(Map<String, Object?> j) => Condition.fromJson(j, '');

      expect(
        evaluate(
          c({
            'stat': 'gold',
            'gte': {'stat': 'price'},
          }),
          s,
        ),
        isTrue,
      );
      expect(
        evaluate(
          c({
            'stat': 'gold',
            'gte': {'stat': 'price', 'times': 3},
          }),
          s,
        ),
        isFalse,
        reason: '12 < 15',
      );
      expect(
        evaluate(
          c({
            'stat': 'price',
            'lte': {'stat': 'gold'},
          }),
          s,
        ),
        isTrue,
      );
      expect(
        evaluate(
          c({
            'stat': 'luck',
            'eq': {'stat': 'luck'},
          }),
          s,
        ),
        isTrue,
      );
    });

    test('an unknown stat counts as 0', () {
      expect(evaluate(cond({'stat': 'nope', 'eq': 0}), state()), isTrue);
    });

    test('all, any, not and their empty forms', () {
      final s = state(inventory: {'key'});
      final yes = {'has': 'key'};
      final no = {'has': 'sword'};
      expect(
        evaluate(
          cond({
            'all': [yes, yes],
          }),
          s,
        ),
        isTrue,
      );
      expect(
        evaluate(
          cond({
            'all': [yes, no],
          }),
          s,
        ),
        isFalse,
      );
      expect(
        evaluate(
          cond({
            'any': [no, yes],
          }),
          s,
        ),
        isTrue,
      );
      expect(
        evaluate(
          cond({
            'any': [no, no],
          }),
          s,
        ),
        isFalse,
      );
      expect(evaluate(cond({'not': no}), s), isTrue);
      expect(evaluate(cond({'not': yes}), s), isFalse);
      expect(evaluate(cond({'all': <Object?>[]}), s), isTrue);
      expect(evaluate(cond({'any': <Object?>[]}), s), isFalse);
    });
  });

  group('explain', () {
    test('is empty when the condition holds', () {
      expect(explain(cond({'has': 'key'}), state(inventory: {'key'})), isEmpty);
    });

    test('a stat comparison reports the number it was compared with', () {
      final s = GameState(
        node: 'a',
        stats: const {'gold': StatValue(4), 'price': StatValue(5)},
      );

      final unmet = explain(
        cond({
          'stat': 'gold',
          'gte': {'stat': 'price', 'times': 2},
        }),
        s,
      ).single;

      expect(unmet.target, 10);
      final plain = explain(cond({'stat': 'gold', 'gte': 9}), s).single;
      expect(plain.target, 9);
      expect(explain(cond({'has': 'x'}), s).single.target, isNull);
    });

    test('a visits requirement is a leaf the UI can describe', () {
      final unmet = explain(
        cond({'visits': 'inn', 'gte': 2}),
        state(visits: {'inn': 1}),
      ).single;
      expect((unmet.condition as VisitCount).node, 'inn');
    });

    test('names the missing item', () {
      final unmet = explain(cond({'has': 'key'}), state()).single;
      expect((unmet.condition as HasItem).item, 'key');
      expect(unmet.negated, isFalse);
    });

    test('lists only the failing parts of an all', () {
      final unmet = explain(
        cond({
          'all': [
            {'has': 'key'},
            {'stat': 'skill', 'gte': 12},
            {'flag': 'met'},
          ],
        }),
        state(inventory: {'key'}),
      );
      expect(unmet.map((u) => u.condition.runtimeType), [StatCompare, FlagSet]);
    });

    test('lists every alternative of an any', () {
      final unmet = explain(
        cond({
          'any': [
            {'has': 'key'},
            {'has': 'axe'},
          ],
        }),
        state(),
      );
      expect(unmet, hasLength(2));
    });

    test('marks requirements under not as negated', () {
      final unmet = explain(
        cond({
          'not': {'flag': 'angry'},
        }),
        state(flags: {'angry'}),
      ).single;
      expect(unmet.negated, isTrue);
      expect((unmet.condition as FlagSet).flag, 'angry');
    });
  });

  group('applyEffect', () {
    Effect effect(Map<String, Object?> json) => Effect.fromJson(json, '');

    test('give is idempotent and keeps pickup order', () {
      var s = state();
      s = applyEffect(effect({'give': 'a'}), s);
      s = applyEffect(effect({'give': 'b'}), s);
      s = applyEffect(effect({'give': 'a'}), s);
      expect(s.inventory.toList(), ['a', 'b']);
    });

    test('take removes, and a missing item is a no-op', () {
      var s = state(inventory: {'a'});
      s = applyEffect(effect({'take': 'a'}), s);
      s = applyEffect(effect({'take': 'zzz'}), s);
      expect(s.inventory, isEmpty);
    });

    test('add and set take a number or another stat, and clamp', () {
      var s = const GameState(
        node: 'a',
        stats: {
          'gold': StatValue(10, 50),
          'price': StatValue(4),
          'loot': StatValue(60),
        },
      );
      Effect e(Map<String, Object?> j) => Effect.fromJson(j, '');

      s = applyEffect(
        e({
          'stat': 'gold',
          'add': {'stat': 'price'},
        }),
        s,
      );
      expect(s.stat('gold'), 14);
      s = applyEffect(
        e({
          'stat': 'gold',
          'add': {'stat': 'price', 'times': -1},
        }),
        s,
      );
      expect(s.stat('gold'), 10);
      s = applyEffect(
        e({
          'stat': 'gold',
          'add': {'stat': 'loot'},
        }),
        s,
      );
      expect(s.stat('gold'), 50, reason: 'capped at the limit');
      s = applyEffect(e({'stat': 'gold', 'set': 0}), s);
      expect(s.stat('gold'), 0);
      s = applyEffect(
        e({
          'stat': 'gold',
          'set': {'stat': 'price'},
        }),
        s,
      );
      expect(s.stat('gold'), 4);
      s = applyEffect(e({'stat': 'gold', 'set': 999}), s);
      expect(s.stat('gold'), 50, reason: 'set is clamped too');
      s = applyEffect(e({'stat': 'gold', 'set': -5}), s);
      expect(s.stat('gold'), 0);
      expect(s.stats['gold']!.max, 50);
    });

    test('a stat effect needs exactly one of add or set', () {
      String error(Map<String, Object?> j) {
        try {
          Effect.fromJson(j, 'e');
        } on StoryFormatException catch (x) {
          return x.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(
        error({'stat': 'g'}),
        'e: a stat effect needs exactly one of add or set',
      );
      expect(
        error({'stat': 'g', 'add': 1, 'set': 2}),
        'e: a stat effect needs exactly one of add or set',
      );
      expect(error({'stat': 'g', 'add': 'x'}), startsWith('e.add: expected'));
      expect(
        error({'stat': 'g', 'add': 1, 'give': 'x'}),
        'e.give: unknown key',
      );
    });

    test('takeAll empties the pack and leaves the rest alone', () {
      final s = applyEffect(
        const TakeAll(),
        state(inventory: {'a', 'b'}, flags: {'f'}),
      );

      expect(s.inventory, isEmpty);
      expect(s.flags, {'f'});
      expect(s.stat('skill'), 8);
    });

    test('set and clear flags', () {
      var s = applyEffect(effect({'set': 'met'}), state());
      expect(s.flags, {'met'});
      s = applyEffect(effect({'clear': 'met'}), s);
      expect(s.flags, isEmpty);
    });

    test('stat changes clamp to 0 and to max', () {
      var s = applyEffect(effect({'stat': 'stamina', 'add': 100}), state());
      expect(s.stat('stamina'), 20);
      s = applyEffect(effect({'stat': 'stamina', 'add': -100}), s);
      expect(s.stat('stamina'), 0);
      s = applyEffect(effect({'stat': 'gold', 'add': 50}), s);
      expect(s.stat('gold'), 50);
      expect(s.stats['stamina']!.max, 20);
    });

    test('a stat the state lacks is ignored', () {
      final s = state();
      expect(applyEffect(effect({'stat': 'luck', 'add': 1}), s), same(s));
    });

    test('effects apply in order and do not mutate the old state', () {
      final before = state();
      final after = applyEffects([
        effect({'give': 'a'}),
        effect({'stat': 'gold', 'add': 3}),
      ], before);
      expect(after.inventory, {'a'});
      expect(after.stat('gold'), 3);
      expect(before.inventory, isEmpty);
      expect(before.stat('gold'), 0);
    });

    test('applying effects keeps a fight in progress', () {
      final fighting = state().withCombat(const CombatState(1, [0, 4]));
      final after = applyEffect(effect({'set': 'x'}), fighting);
      expect(after.combat!.enemy, 1);
    });
  });

  group('GameState json', () {
    test('round trips', () {
      final original = GameState(
        node: 'door',
        stats: const {'skill': StatValue(8, 10), 'gold': StatValue(2)},
        inventory: const {'key', 'map'},
        flags: const {'met'},
        visited: const {'cellar', 'door'},
        combat: const CombatState(1, [0, 4]),
      );
      final copy = GameState.fromJson(original.toJson());
      expect(copy.toJson(), original.toJson());
      expect(copy.inventory.toList(), ['key', 'map']);
      expect(copy.stats['gold']!.max, isNull);
      expect(copy.combat!.enemyHealth, [0, 4]);
    });

    test('offers round trip, in order', () {
      const original = GameState(node: 'a', offers: ['rope', 'lamp']);

      final copy = GameState.fromJson(original.toJson());

      expect(copy.offers, ['rope', 'lamp']);
    });

    test('a save from before offers existed has none', () {
      final json = const GameState(node: 'a').toJson()..remove('offers');

      expect(GameState.fromJson(json).offers, isEmpty);
    });

    test('copyWith and withCombat keep the offers', () {
      const s = GameState(node: 'a', offers: ['rope']);

      expect(s.copyWith(node: 'b').offers, ['rope']);
      expect(s.withCombat(const CombatState(0, [3])).offers, ['rope']);
      expect(s.copyWith(offers: const []).offers, isEmpty);
    });

    test('taken once-only choices round trip', () {
      const original = GameState(node: 'a', taken: {'a#0', 'b#2'});

      expect(GameState.fromJson(original.toJson()).taken, {'a#0', 'b#2'});
      expect(original.copyWith(node: 'b').taken, {'a#0', 'b#2'});
      expect(original.withCombat(null).taken, {'a#0', 'b#2'});
    });

    test('visit counts round trip', () {
      const original = GameState(node: 'a', visits: {'a': 2, 'b': 1});

      final copy = GameState.fromJson(original.toJson());

      expect(copy.visits, {'a': 2, 'b': 1});
      expect(original.copyWith(node: 'b').visitsTo('a'), 2);
      expect(original.withCombat(null).visitsTo('b'), 1);
      expect(original.visitsTo('nowhere'), 0);
    });

    test('a save from before counting has one visit per visited node', () {
      final json = const GameState(node: 'a', visited: {'a', 'b'}).toJson()
        ..remove('visits');

      expect(GameState.fromJson(json).visits, {'a': 1, 'b': 1});
    });

    test('a save from before once-only choices has none taken', () {
      final json = const GameState(node: 'a').toJson()..remove('taken');

      expect(GameState.fromJson(json).taken, isEmpty);
    });

    test('rejects malformed data', () {
      for (final bad in <Object?>[
        null,
        'x',
        <String, Object?>{},
        {'node': 'a', 'stats': 3},
        {'node': 'a', 'stats': <String, Object?>{}, 'inventory': 'k'},
        {
          'node': 'a',
          'stats': {
            's': {'value': 'x'},
          },
          'inventory': <Object?>[],
          'flags': <Object?>[],
          'visited': <Object?>[],
        },
        {
          'node': 'a',
          'stats': <String, Object?>{},
          'inventory': <Object?>[],
          'flags': <Object?>[],
          'visited': <Object?>[],
          'combat': {'enemy': 'x'},
        },
        {
          'node': 'a',
          'stats': <String, Object?>{},
          'inventory': <Object?>[],
          'flags': <Object?>[],
          'visited': <Object?>[],
          'offers': 'rope',
        },
      ]) {
        expect(() => GameState.fromJson(bad), throwsFormatException);
      }
    });
  });
}
