import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// A fight on page `a` with a flee to `ran`; [combat] adds to it.
Map<String, Object?> json({
  String preset = 'fighting-fantasy',
  Map<String, Object?> combat = const {'fleeCost': 'round'},
  List<Map<String, Object?>>? enemies,
  int schema = 1,
}) => {
  'schema': schema,
  'id': 'flee',
  'lang': 'en',
  'title': 'Flee',
  'rules': {'preset': preset},
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A troll.',
      'combat': {
        'enemies':
            enemies ??
            [
              {'name': 'Troll', 'attack': 9, 'health': 9, 'defense': 12},
            ],
        'win': 'won',
        'flee': 'ran',
        ...combat,
      },
    },
    'ran': {'text': 'Ran', 'ending': 'defeat'},
    'won': {'text': 'Won', 'ending': 'victory'},
    'stung': {'text': 'Stung', 'ending': 'defeat'},
  },
};

(GameEngine, ScriptedRandom) start(
  Map<String, Object?> j, {
  List<int> dice = const [],
  Map<String, StatValue>? stats,
}) {
  final story = Story.fromJson(j);
  final random = ScriptedRandom(dice);
  final (engine, _) = GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: random,
    stats:
        stats ??
        const {
          'skill': StatValue(9, 12),
          'stamina': StatValue(12, 24),
          'luck': StatValue(8, 12),
        },
  );
  return (engine, random);
}

void main() {
  test('fleeing for free leaves at once, as before', () {
    final (engine, _) = start(json(combat: const {}));

    final events = engine.flee();

    expect(events.whereType<CombatStrike>(), isEmpty);
    expect(engine.node.id, 'ran');
  });

  test('fleeing that costs a round lets the enemy strike first', () {
    final (engine, _) = start(json());

    final events = engine.flee();

    expect(engine.state.stat('stamina'), 10);
    expect(engine.node.id, 'ran');
    expect(
      events.indexWhere((e) => e is CombatStrike),
      lessThan(events.indexWhere((e) => e is NodeEntered)),
    );
  });

  test('the strike can kill: no flee page then', () {
    final (engine, _) = start(
      json(),
      stats: const {
        'skill': StatValue(9, 12),
        'stamina': StatValue(2, 24),
        'luck': StatValue(8, 12),
      },
    );

    engine.flee();

    expect(engine.ending, Ending.death);
    expect(engine.node.id, 'a');
  });

  test('in vs-defense the enemy rolls its attack', () {
    // 1d20 = 20 + 9 hits defense 10 + agility 2; damage 1d6 = 4.
    final (engine, random) = start(
      json(preset: 'd20-lite'),
      dice: [20, 4],
      stats: const {
        'might': StatValue(2),
        'agility': StatValue(2),
        'wits': StatValue(2),
        'hp': StatValue(12, 12),
      },
    );

    engine.flee();

    expect(engine.state.stat('hp'), 8);
    expect(random.remaining, 0);
  });

  test('against several at once every enemy still standing strikes', () {
    final (engine, _) = start(
      json(
        combat: const {'fleeCost': 'round', 'simultaneous': true},
        enemies: [
          {'name': 'Gull', 'attack': 7, 'health': 4},
          {'name': 'Gull', 'attack': 7, 'health': 4},
        ],
      ),
    );

    final events = engine.flee();

    expect(events.whereType<CombatStrike>(), hasLength(2));
    expect(engine.state.stat('stamina'), 8);
  });

  test('the strike is no wound for wounded and no round for rounds', () {
    final (engine, _) = start(
      json(
        combat: const {
          'fleeCost': 'round',
          'wounded': 'stung',
          'rounds': {'after': 1, 'to': 'stung'},
        },
      ),
    );

    engine.flee();

    expect(engine.node.id, 'ran');
  });

  group('parse', () {
    String failure(Map<String, Object?> j) {
      try {
        Story.fromJson(j);
      } on StoryFormatException catch (e) {
        return '$e';
      }
      fail('expected a StoryFormatException');
    }

    test('only with flee, and only round or free', () {
      final noFlee = json();
      (((noFlee['nodes']! as Map)['a']! as Map)['combat']! as Map).remove(
        'flee',
      );
      expect(
        failure(noFlee),
        'nodes.a.combat.fleeCost: only applies to a fight with "flee"',
      );
      expect(
        failure(json(combat: const {'fleeCost': 'slow'})),
        'nodes.a.combat.fleeCost: expected "round" or "free"',
      );
    });
  });
}
