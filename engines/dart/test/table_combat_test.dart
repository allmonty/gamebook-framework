import 'package:gamebook_engine/combat.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

List<List<int>> results(int enemy, int player) => [
  for (var i = 0; i < 10; i++) [enemy + i, player],
];

/// Three bands: ratio up to -3, up to 3, above. The enemy loses `base + roll`
/// and the player `player`.
Map<String, Object?> combatRules({
  List<Object?>? table,
  String? roll,
  Object? luck,
}) => {
  'mode': 'table',
  'attackStat': 'skill',
  'roll': ?roll,
  'luck': ?luck,
  'table':
      table ??
      [
        {'upTo': -3, 'results': results(0, 4)},
        {'upTo': 3, 'results': results(1, 2)},
        {'results': results(3, 0)},
      ],
};

Map<String, Object?> storyJson({
  Map<String, Object?>? combat,
  int schema = 5,
  Map<String, Object?>? enemy,
  bool simultaneous = false,
}) => {
  'schema': schema,
  'id': 't',
  'lang': 'en',
  'title': 'T',
  'rules': {'preset': 'fighting-fantasy', 'combat': combat ?? combatRules()},
  'start': 'ring',
  'nodes': {
    'ring': {
      'text': 'Ring',
      'combat': {
        'enemies': [
          enemy ?? {'name': 'Gnoll', 'attack': 9, 'health': 12},
        ],
        'win': 'won',
        'simultaneous': ?(simultaneous ? true : null),
      },
    },
    'won': {'text': 'Won', 'ending': 'victory'},
  },
};

String error(Map<String, Object?> json) {
  try {
    Rules.resolve(Story.fromJson(json).rules);
  } on StoryFormatException catch (e) {
    return e.toString();
  }
  fail('expected a StoryFormatException');
}

GameState hero({int skill = 9, int stamina = 12, Combat? fight}) => GameState(
  node: 'ring',
  stats: {
    'skill': StatValue(skill, 12),
    'stamina': StatValue(stamina, 24),
    'luck': const StatValue(8, 12),
  },
).withCombat(fight == null ? null : startCombat(fight));

void main() {
  final story = Story.fromJson(storyJson());
  final fight = story.nodes['ring']!.combat!;
  final rules = Rules.resolve(story.rules);

  RoundResult round(List<int> faces, {int skill = 9, Combat? against}) =>
      fightRound(
        rules: rules,
        combat: against ?? fight,
        state: hero(skill: skill, fight: against ?? fight),
        random: ScriptedRandom(faces),
      );

  group('parse', () {
    test('reads the rows and defaults the roll to 1d10-1', () {
      final cr = rules.combat!;

      expect(cr.mode, CombatMode.table);
      expect(cr.attackRoll.toString(), '1d10-1');
      expect(cr.attackStat, 'skill');
      expect(cr.table, hasLength(3));
      expect(cr.table[0].upTo, -3);
      expect(cr.table[2].upTo, isNull);
      expect(cr.table[1].results[4], (5, 2));
    });

    test('errors name the path', () {
      String bad(Map<String, Object?> combat) =>
          error(storyJson(combat: combat));

      expect(
        bad(combatRules(roll: '1d6')),
        'rules.combat.roll: must be able to give 0 and nothing lower '
        '(like 1d10-1)',
      );
      expect(
        bad(combatRules(table: <Object?>[])),
        'rules.combat.table: missing',
      );
      expect(
        bad(
          combatRules(
            table: [
              {'upTo': 0, 'results': results(0, 0)},
              {'upTo': 0, 'results': results(0, 0)},
              {'results': results(0, 0)},
            ],
          ),
        ),
        'rules.combat.table[1].upTo: must be higher than the row above',
      );
      expect(
        bad(
          combatRules(
            table: [
              {'upTo': 0, 'results': results(0, 0)},
              {'upTo': 5, 'results': results(0, 0)},
            ],
          ),
        ),
        'rules.combat.table[1].upTo: the last row has no "upTo"',
      );
      expect(
        bad(
          combatRules(
            table: [
              {'results': results(0, 0)},
              {'results': results(0, 0)},
            ],
          ),
        ),
        'rules.combat.table[0].upTo: missing',
      );
      expect(
        bad(
          combatRules(
            table: [
              {'results': results(0, 0).take(9).toList()},
            ],
          ),
        ),
        startsWith('rules.combat.table[0].results: needs 10 results'),
      );
      expect(
        bad(
          combatRules(
            table: [
              {
                'results': [
                  ...results(0, 0).take(9),
                  [1],
                ],
              },
            ],
          ),
        ),
        'rules.combat.table[0].results[9]: expected [enemy loss, player loss]',
      );
      expect(
        bad(combatRules(luck: {'stat': 'luck'})),
        'rules.combat.luck: cannot be combined with "table" mode',
      );
    });

    test('needs schema 5', () {
      expect(
        error(storyJson(schema: 4)),
        'rules.combat.mode: needs "schema": 5',
      );
    });
  });

  group('a round', () {
    test('the ratio picks the row, the roll picks the result', () {
      // Ratio 9 - 9 = 0: the middle row. Face 5 is index 4: [5, 2].
      final result = round([5]);

      expect(result.ratio, 0);
      expect(result.playerTotal, 4);
      expect(result.damageToEnemy, 5);
      expect(result.damageToPlayer, 2);
      expect(result.state.combat!.enemyHealth, [7]);
      expect(result.state.stat('stamina'), 10);
      expect(result.outcome, CombatOutcome.ongoing);
    });

    test('a ratio at a band edge belongs to the lower band', () {
      expect(round([1], skill: 6).ratio, -3);
      expect(round([1], skill: 6).damageToPlayer, 4);
      expect(round([1], skill: 12).ratio, 3);
      expect(round([1], skill: 12).damageToPlayer, 2);
    });

    test('above every upTo takes the last row', () {
      final result = round([1], skill: 20);

      expect(result.ratio, 11);
      expect((result.damageToEnemy, result.damageToPlayer), (3, 0));
    });

    test('a bonus to the attack stat moves the ratio', () {
      final bonus = hero(fight: fight).withBonus({'skill': 4});
      final result = fightRound(
        rules: rules,
        combat: fight,
        state: bonus,
        random: ScriptedRandom([1]),
      );

      expect(result.ratio, 4);
    });

    test('armor reduces the enemy loss', () {
      final armored = Story.fromJson(
        storyJson(
          enemy: {'name': 'Gnoll', 'attack': 9, 'health': 12, 'armor': 2},
        ),
      ).nodes['ring']!.combat!;

      expect(round([5], against: armored).damageToEnemy, 3);
    });

    test('the fight ends when the enemy or the player is down', () {
      final weak = Story.fromJson(
        storyJson(enemy: {'name': 'Gnoll', 'attack': 9, 'health': 5}),
      ).nodes['ring']!.combat!;
      expect(round([5], against: weak).outcome, CombatOutcome.won);

      final dying = fightRound(
        rules: rules,
        combat: fight,
        state: hero(stamina: 2, fight: fight),
        random: ScriptedRandom([1]),
      );
      expect(dying.outcome, CombatOutcome.lost);
      expect(dying.state.stat('stamina'), 0);
    });

    test('an item that costs the round lets the enemy hit with the table', () {
      // Ratio 0, face 1: the player loses 2; the enemy's loss is ignored.
      final strike = enemyStrike(
        rules: rules,
        combat: fight,
        state: hero(fight: fight),
        random: ScriptedRandom([1]),
      );

      expect(strike.damageToPlayer, 2);
      expect(strike.state.combat!.enemyHealth, [12]);
    });
  });

  group('duels beside another mode', () {
    Map<String, Object?> mixedJson({
      Object? table = true,
      bool duel = true,
      bool simultaneous = false,
      int schema = 5,
      Object? roll,
    }) => {
      'schema': schema,
      'id': 'd',
      'lang': 'en',
      'title': 'D',
      'rules': {
        'preset': 'fighting-fantasy',
        'combat': {
          'luck': {'stat': 'luck'},
          if (table != null) 'table': combatRules()['table'],
          'roll': ?roll,
        },
      },
      'start': 'ring',
      'nodes': {
        'ring': {
          'text': 'Ring',
          'combat': {
            'enemies': [
              {'name': 'Gnoll', 'attack': 9, 'health': 12},
            ],
            'win': 'won',
            'duel': ?(duel ? true : null),
            'simultaneous': ?(simultaneous ? true : null),
          },
        },
        'won': {'text': 'Won', 'ending': 'victory'},
      },
    };

    final mixed = Story.fromJson(mixedJson());
    final mixedRules = Rules.resolve(mixed.rules);
    final duel = mixed.nodes['ring']!.combat!;
    final plain = Story.fromJson(mixedJson(duel: false)).nodes['ring']!.combat!;

    RoundResult play(Combat fight, List<int> faces) => fightRound(
      rules: mixedRules,
      combat: fight,
      state: hero(fight: fight),
      random: ScriptedRandom(faces),
    );

    test('the mode stays, and the table is there for duels', () {
      expect(mixedRules.combat!.mode, CombatMode.opposed);
      expect(mixedRules.combat!.table, hasLength(3));
      expect(mixedRules.combat!.tableRoll.toString(), '1d10-1');
      expect(mixedRules.combat!.luck, isNotNull);
    });

    test('a duel is resolved by the table', () {
      // Ratio 0: face 5 is index 4, the middle row gives [5, 2].
      final result = play(duel, [5]);

      expect(result.ratio, 0);
      expect((result.damageToEnemy, result.damageToPlayer), (5, 2));
    });

    test('another fight in the same story uses the mode', () {
      // Opposed: player 3+3+9 = 15 against 2+2+9 = 13, damage 2.
      final result = play(plain, [3, 3, 2, 2]);

      expect(result.ratio, isNull);
      expect(result.damageToEnemy, 2);
    });

    test('no test of luck is offered in a duel', () {
      expect(play(duel, [5]).state.combat!.luck, isNull);
      expect(play(plain, [3, 3, 2, 2]).state.combat!.luck, isNotNull);
    });

    test('an item that costs the round is struck back with the table', () {
      final strike = enemyStrike(
        rules: mixedRules,
        combat: duel,
        state: hero(fight: duel),
        random: ScriptedRandom([1]),
      );

      expect(strike.damageToPlayer, 2);
    });

    test('errors name the path, and a duel needs schema 5', () {
      expect(
        error(mixedJson(table: null, roll: '1d10-1')),
        'rules.combat.table: missing',
      );
      expect(
        error(mixedJson(schema: 4)),
        'rules.combat.luck: needs "schema": 5',
      );
      final noLuck = mixedJson(schema: 4);
      ((noLuck['rules']! as Map)['combat']! as Map).remove('luck');
      expect(error(noLuck), 'rules.combat.table: needs "schema": 5');
    });

    test('the validator wants a table, and no groups', () {
      List<String> issues(Map<String, Object?> json) => [
        for (final i in validateStory(Story.fromJson(json))) i.toString(),
      ];

      expect(
        issues(mixedJson(table: null)),
        contains(
          'error: nodes.ring.combat.duel: needs a results table in rules.combat',
        ),
      );
      expect(
        issues(mixedJson(simultaneous: true)),
        contains(
          'error: nodes.ring.combat.simultaneous: '
          'a results table cannot be used against a group',
        ),
      );
      expect(issues(mixedJson()).where((i) => i.startsWith('error')), isEmpty);
    });
  });

  group('validation', () {
    test('a table cannot be used against a group', () {
      final issues = validateStory(
        Story.fromJson(storyJson(simultaneous: true)),
      );

      expect(
        issues.map((i) => i.toString()),
        contains(
          'error: nodes.ring.combat.simultaneous: '
          'a results table cannot be used against a group',
        ),
      );
    });

    test('enemies need no defense', () {
      final issues = validateStory(Story.fromJson(storyJson()));

      expect(issues.where((i) => i.severity == Severity.error), isEmpty);
    });
  });
}
