import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Map<String, Object?> storyJson({
  bool simultaneous = true,
  bool luck = true,
  int schema = 1,
}) => {
  'schema': schema,
  'id': 'g',
  'lang': 'en',
  'title': 'G',
  'rules': {
    'preset': 'fighting-fantasy',
    'combat': {
      'luck': ?(luck ? {'stat': 'luck'} : null),
    },
  },
  'items': {
    'potion': {
      'name': 'Potion',
      'use': {
        'effects': [
          {'stat': 'stamina', 'add': 3},
        ],
        'when': ['combat'],
      },
    },
  },
  'start': 'ring',
  'nodes': {
    'ring': {
      'text': 'Ring',
      'combat': {
        'enemies': [
          {'name': 'A', 'attack': 7, 'health': 2},
          {'name': 'B', 'attack': 5, 'health': 2},
        ],
        'win': 'won',
        'simultaneous': ?(simultaneous ? true : null),
      },
    },
    'won': {'text': 'Won', 'ending': 'victory'},
  },
};

GameEngine start(List<int> dice) {
  final story = Story.fromJson(storyJson());
  return GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: ScriptedRandom(dice),
    stats: {
      'skill': const StatValue(9, 12),
      'stamina': const StatValue(12, 24),
      'luck': const StatValue(8, 12),
    },
  ).$1;
}

void main() {
  test('simultaneous is read', () {
    expect(
      Story.fromJson(storyJson()).nodes['ring']!.combat!.simultaneous,
      isTrue,
    );
    expect(
      Story.fromJson(storyJson(simultaneous: false))
          .nodes['ring']!
          .combat!
          .simultaneous,
      isFalse,
    );
  });

  test('every enemy fights, and the player picks the target', () {
    // Player 15; A 11 loses (wounded for 2 and killed); B 9 loses.
    final engine = start([3, 3, 2, 2, 2, 2]);

    final events = engine.fight(target: 0);

    final round = events.whereType<CombatGroupRound>().single.result;
    expect(round.target.name, 'A');
    expect(round.attacks.map((a) => a.enemy.name), ['A', 'B']);
    expect(engine.state.combat!.enemyHealth, [0, 2]);
    expect(engine.canTestLuck, isFalse, reason: 'the target died');
  });

  test('the fight is won when every enemy is down', () {
    final engine = start([3, 3, 2, 2, 2, 2, 3, 3, 2, 2]);
    engine.fight(target: 0);

    final events = engine.fight(target: 1);

    expect(engine.state.node, 'won');
    expect(
      events.whereType<CombatGroupRound>().single.result.attacks,
      hasLength(1),
    );
  });

  test('a target is required and must be alive', () {
    final engine = start([3, 3, 2, 2, 2, 2]);

    expect(engine.fight, throwsStateError);
    expect(() => engine.fight(target: 5), throwsStateError);
    engine.fight(target: 0);
    expect(() => engine.fight(target: 0), throwsStateError);
  });

  test('an item that costs the round lets every living enemy strike', () {
    final story = Story.fromJson(storyJson());
    final engine = GameEngine(
      story: story,
      rules: Rules.resolve(story.rules),
      random: ScriptedRandom(const []),
      state: const GameState(
        node: 'ring',
        stats: {
          'skill': StatValue(9, 12),
          'stamina': StatValue(10, 24),
          'luck': StatValue(8, 12),
        },
        inventory: {'potion'},
        combat: CombatState(0, [2, 2]),
      ),
    );

    final events = engine.useItem('potion');

    final strikes = events.whereType<CombatStrike>().toList();
    expect(strikes.map((s) => s.result.enemy.name), ['A', 'B']);
    // +3 from the potion, then a flat 2 from each enemy.
    expect(engine.state.stat('stamina'), 9);
  });

  test('the strikes stop when the player dies', () {
    final story = Story.fromJson(storyJson());
    final engine = GameEngine(
      story: story,
      rules: Rules.resolve(story.rules),
      random: ScriptedRandom(const []),
      state: GameState(
        node: 'ring',
        stats: const {
          'skill': StatValue(9, 12),
          'stamina': StatValue(1, 24),
          'luck': StatValue(8, 12),
        },
        inventory: const {'potion'},
        combat: const CombatState(0, [2, 2]),
      ),
    );

    final events = engine.useItem('potion');

    // +3 gives 4 health; A wounds for 2, B wounds for 2.
    expect(engine.ending, Ending.death);
    expect(events.whereType<CombatStrike>(), hasLength(2));
  });
}
