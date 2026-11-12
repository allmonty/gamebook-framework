import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// A scorpion that stings (`wounded`) and slips away after [after] rounds.
/// Opposed rounds roll 2d6 for the hero, then 2d6 for the scorpion; the loser
/// takes 2.
Story scorpion({bool wounded = true, int after = 2}) => Story.fromJson({
  'schema': 8,
  'id': 'scorpion',
  'lang': 'en',
  'title': 'Scorpion',
  'rules': {'preset': 'fighting-fantasy'},
  'items': {
    'potion': {
      'name': 'Potion',
      'use': {
        'effects': [
          {'stat': 'stamina', 'add': 1},
        ],
        'when': ['combat'],
        'combatCost': 'round',
      },
    },
    'charm': {
      'name': 'Charm',
      'use': {
        'effects': [
          {'stat': 'luck', 'add': 1},
        ],
        'when': ['combat'],
        'combatCost': 'free',
      },
    },
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A',
      'effects': [
        {'give': 'potion'},
        {'give': 'charm'},
      ],
      'choices': [
        {'text': 'Fight', 'to': 'pit'},
      ],
    },
    'pit': {
      'text': 'A scorpion.',
      'combat': {
        'enemies': [
          {'name': 'Scorpion', 'attack': 7, 'health': 6},
        ],
        'win': 'won',
        'wounded': ?(wounded ? 'stung' : null),
        'rounds': {'after': after, 'to': 'slow'},
      },
    },
    'won': {'text': 'Won', 'ending': 'victory'},
    'stung': {'text': 'Stung', 'ending': 'defeat'},
    'slow': {'text': 'Gone', 'ending': 'defeat'},
  },
});

(GameEngine, ScriptedRandom) atPit(
  List<int> dice, {
  Story? story,
  int stamina = 12,
}) {
  final s = story ?? scorpion();
  final random = ScriptedRandom(dice);
  final (engine, _) = GameEngine.newGame(
    story: s,
    rules: Rules.resolve(s.rules),
    random: random,
    stats: {
      'skill': const StatValue(9, 12),
      'stamina': StatValue(stamina, 24),
      'luck': const StatValue(8, 12),
    },
  );
  engine.choose(0);
  return (engine, random);
}

// Hero 2+2+9 = 13 against 6+6+7 = 19: the hero is wounded.
const _wound = [1, 1, 6, 6];
// Hero 6+6+9 = 21 against 1+1+7 = 9: the scorpion is hurt.
const _hit = [6, 6, 1, 1];
// Hero 3+3+9 = 15 against 4+4+7 = 15: nobody is hurt.
const _tie = [3, 3, 4, 4];

void main() {
  test('the first wound ends the fight on the wounded page', () {
    final (engine, random) = atPit(_wound);

    engine.fight();

    expect(engine.node.id, 'stung');
    expect(engine.state.stat('stamina'), 10);
    expect(engine.state.combat, isNull);
    expect(random.remaining, 0);
  });

  test('rounds without a wound keep the fight going and are counted', () {
    final (engine, _) = atPit([..._hit], story: scorpion(after: 5));

    engine.fight();

    expect(engine.node.id, 'pit');
    expect(engine.state.combat!.round, 1);
  });

  test('the round limit ends the fight once enough rounds are played', () {
    final (engine, _) = atPit([..._tie, ..._hit]);

    engine.fight();
    expect(engine.node.id, 'pit');
    engine.fight();

    expect(engine.node.id, 'slow');
  });

  test('a wound comes before the round limit', () {
    final (engine, _) = atPit(_wound, story: scorpion(after: 1));

    engine.fight();

    expect(engine.node.id, 'stung');
  });

  test('death comes before a wound', () {
    final (engine, _) = atPit(_wound, stamina: 2);

    engine.fight();

    expect(engine.ending, Ending.death);
    expect(engine.node.id, 'pit');
  });

  test('without wounded, a wound is just a wound', () {
    final (engine, _) = atPit(_wound, story: scorpion(wounded: false));

    engine.fight();

    expect(engine.node.id, 'pit');
    expect(engine.state.stat('stamina'), 10);
  });

  test('an item that costs the round counts as a round, its strike as a '
      'wound', () {
    final (engine, _) = atPit(const []);

    engine.useItem('potion');

    // +1 from the potion, -2 from the strike.
    expect(engine.state.stat('stamina'), 11);
    expect(engine.node.id, 'stung');
  });

  test('an item that costs the round counts towards the limit', () {
    final (engine, _) = atPit(_tie, story: scorpion(wounded: false));

    engine.fight();
    engine.useItem('potion');

    expect(engine.node.id, 'slow');
  });

  test('a free item counts as neither', () {
    final (engine, _) = atPit(const [], story: scorpion(after: 1));

    engine.useItem('charm');

    expect(engine.node.id, 'pit');
    expect(engine.state.combat!.round, 0);
  });

  group('the round count is saved', () {
    test('and read back', () {
      final (engine, _) = atPit(_hit, story: scorpion(after: 5));
      engine.fight();

      final saved = GameState.fromJson(engine.state.toJson());

      expect(saved.combat!.round, 1);
    });

    test('a save from before schema 8 has played no rounds', () {
      final json = const GameState(
        node: 'pit',
        stats: {},
        combat: CombatState(0, [6]),
      ).toJson();
      (json['combat']! as Map<String, Object?>).remove('round');

      expect(GameState.fromJson(json).combat!.round, 0);
    });
  });
}
