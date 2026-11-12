import 'package:gamebook_engine/combat.dart';
import 'package:gamebook_engine/json_reader.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Rules rules(String preset) =>
    Rules.resolve(RulesSpec.fromJson(JsonObject({'preset': preset}, '')));

Combat combat(List<Map<String, Object?>> enemies) =>
    Combat.fromJson(JsonObject({'enemies': enemies, 'win': 'w'}, ''));

GameState ff({int skill = 9, int stamina = 12, Combat? fight}) => GameState(
  node: 'n',
  stats: {
    'skill': StatValue(skill, 12),
    'stamina': StatValue(stamina, 24),
    'luck': const StatValue(8, 12),
  },
).withCombat(fight == null ? null : startCombat(fight));

const goblin = {'name': 'Goblin', 'attack': 7, 'health': 4};

void main() {
  group('opposed (Fighting Fantasy)', () {
    final r = rules('fighting-fantasy');

    test('the higher total wounds the other side', () {
      final fight = combat([goblin]);
      // Player 3+3+9 = 15 against goblin 2+2+7 = 11.
      final script = ScriptedRandom([3, 3, 2, 2]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: script,
      );

      expect(round.playerTotal, 15);
      expect(round.enemyTotal, 11);
      expect(round.damageToEnemy, 2);
      expect(round.damageToPlayer, 0);
      expect(round.state.combat!.enemyHealth, [2]);
      expect(round.state.stat('stamina'), 12);
      expect(round.outcome, CombatOutcome.ongoing);
      expect(script.remaining, 0);
    });

    test('losing the round costs the player stamina', () {
      final fight = combat([goblin]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([1, 1, 6, 6]),
      );

      expect(round.damageToPlayer, 2);
      expect(round.state.stat('stamina'), 10);
      expect(round.state.combat!.enemyHealth, [4]);
    });

    test('equal totals hurt nobody', () {
      final fight = combat([
        {'name': 'x', 'attack': 9, 'health': 4},
      ]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([3, 4, 3, 4]),
      );

      expect(round.damageToEnemy + round.damageToPlayer, 0);
      expect(round.state.stat('stamina'), 12);
    });

    test('an enemy can override the damage it deals', () {
      final fight = combat([
        {...goblin, 'damage': '3'},
      ]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([1, 1, 6, 6]),
      );

      expect(round.damageToPlayer, 3);
    });

    test('killing the last enemy wins', () {
      final fight = combat([
        {...goblin, 'health': 2},
      ]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([6, 6, 1, 1]),
      );

      expect(round.state.combat!.enemyHealth, [0]);
      expect(round.outcome, CombatOutcome.won);
    });

    test('killing a non-last enemy moves on to the next one', () {
      final fight = combat([
        {...goblin, 'health': 2},
        goblin,
      ]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([6, 6, 1, 1]),
      );

      expect(round.outcome, CombatOutcome.ongoing);
      expect(round.state.combat!.enemy, 1);
      expect(round.state.combat!.enemyHealth, [0, 4]);
    });

    test('the player dies at 0 stamina and never goes below', () {
      final fight = combat([goblin]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(stamina: 1, fight: fight),
        random: ScriptedRandom([1, 1, 6, 6]),
      );

      expect(round.state.stat('stamina'), 0);
      expect(round.outcome, CombatOutcome.lost);
    });

    test('enemy health never goes below 0 (overkill)', () {
      final fight = combat([
        {...goblin, 'health': 1},
      ]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([6, 6, 1, 1]),
      );

      expect(round.state.combat!.enemyHealth, [0]);
    });
  });

  group('vs-defense (d20-lite)', () {
    final r = rules('d20-lite');
    final fight = combat([
      {'name': 'Rat', 'attack': 2, 'health': 5, 'defense': 11},
    ]);
    GameState hero({int hp = 10}) => GameState(
      node: 'n',
      stats: {
        'might': const StatValue(3),
        'agility': const StatValue(2),
        'wits': const StatValue(1),
        'hp': StatValue(hp, 20),
      },
    ).withCombat(startCombat(fight));

    test('a hit damages the enemy, then the enemy attacks', () {
      // Player d20 8+3 = 11 >= 11 hits, damage 4; rat d20 8+2 = 10 vs 12 misses.
      final script = ScriptedRandom([8, 4, 8]);
      final round = fightRound(
        rules: r,
        combat: fight,
        state: hero(),
        random: script,
      );

      expect(round.playerTotal, 11);
      expect(round.playerTarget, 11);
      expect(round.damageToEnemy, 4);
      expect(round.state.combat!.enemyHealth, [1]);
      expect(round.enemyTotal, 10);
      expect(round.enemyTarget, 12);
      expect(round.damageToPlayer, 0);
      expect(script.remaining, 0);
    });

    test('a miss then a hit damages only the player', () {
      // Player 7+3 = 10 misses; rat 10+2 = 12 >= 12 hits for 3.
      final round = fightRound(
        rules: r,
        combat: fight,
        state: hero(),
        random: ScriptedRandom([7, 10, 3]),
      );

      expect(round.damageToEnemy, 0);
      expect(round.damageToPlayer, 3);
      expect(round.state.stat('hp'), 7);
    });

    test('a dead enemy does not attack back', () {
      final lone = combat([
        {'name': 'Rat', 'attack': 2, 'health': 3, 'defense': 11},
      ]);
      final script = ScriptedRandom([10, 5]);
      final round = fightRound(
        rules: r,
        combat: lone,
        state: hero().withCombat(startCombat(lone)),
        random: script,
      );

      expect(round.outcome, CombatOutcome.won);
      expect(round.enemyAttack, isNull);
      expect(round.enemyTotal, isNull);
      expect(script.remaining, 0);
    });

    test('the player can die from the counter-attack', () {
      final round = fightRound(
        rules: r,
        combat: fight,
        state: hero(hp: 2),
        random: ScriptedRandom([1, 20, 6]),
      );

      expect(round.state.stat('hp'), 0);
      expect(round.outcome, CombatOutcome.lost);
    });

    test('an enemy without a defense is a story bug', () {
      final bad = combat([
        {'name': 'Rat', 'attack': 2, 'health': 5},
      ]);
      expect(
        () => fightRound(
          rules: r,
          combat: bad,
          state: hero().withCombat(startCombat(bad)),
          random: ScriptedRandom([10]),
        ),
        throwsStateError,
      );
    });
  });

  group('armor', () {
    final r = rules('fighting-fantasy');

    RoundResult round(Map<String, Object?> enemy, List<int> faces) {
      final fight = combat([enemy]);
      return fightRound(
        rules: r,
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom(faces),
      );
    }

    test('takes points off every wound the player deals', () {
      // Player 15 against 11 wounds for 2; armor 1 leaves 1.
      final result = round({...goblin, 'armor': 1}, [3, 3, 2, 2]);

      expect(result.damageToEnemy, 1);
      expect(result.state.combat!.enemyHealth, [3]);
    });

    test('never turns a wound into healing', () {
      final result = round({...goblin, 'armor': 5}, [3, 3, 2, 2]);

      expect(result.damageToEnemy, 0);
      expect(result.state.combat!.enemyHealth, [4]);
    });

    test('does not soften the wounds the enemy deals', () {
      final result = round({...goblin, 'armor': 3}, [1, 1, 6, 6]);

      expect(result.damageToPlayer, 2);
    });

    test('applies in vs-defense fights too', () {
      final fight = combat([
        {'name': 'Rat', 'attack': 2, 'health': 5, 'defense': 11, 'armor': 1},
      ]);
      final hero = GameState(
        node: 'n',
        stats: {
          'might': const StatValue(3),
          'agility': const StatValue(2),
          'wits': const StatValue(1),
          'hp': const StatValue(10, 20),
        },
      ).withCombat(startCombat(fight));

      final result = fightRound(
        rules: rules('d20-lite'),
        combat: fight,
        state: hero,
        random: ScriptedRandom([8, 4, 8]),
      );

      expect(result.damageToEnemy, 3);
    });

    test('is 0 by default, must not be negative', () {
      expect(Enemy.fromJson(goblin, 'e').armor, 0);
      expect(
        () => Enemy.fromJson({...goblin, 'armor': -1}, 'e'),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'e.armor: must not be negative',
          ),
        ),
      );
      Map<String, Object?> json(int schema) => {
        'schema': schema,
        'id': 'x',
        'lang': 'en',
        'title': 'x',
        'rules': {'preset': 'fighting-fantasy'},
        'start': 'n',
        'nodes': {
          'n': {
            'text': 't',
            'combat': {
              'enemies': [
                {...goblin, 'armor': 1},
              ],
              'win': 'w',
            },
          },
          'w': {'text': 't', 'ending': 'victory'},
        },
      };
      expect(Story.fromJson(json(1)).nodes['n']!.combat!.enemies[0].armor, 1);
    });
  });

  group('luck in a fight', () {
    final r = Rules.resolve(
      RulesSpec.fromJson(
        JsonObject({
          'preset': 'fighting-fantasy',
          'combat': {
            'luck': {'stat': 'luck'},
          },
        }, 'rules'),
      ),
    );
    final fight = combat([
      goblin,
      {...goblin, 'name': 'Second'},
    ]);

    /// Plays one round: the dice give [player] and [enemy] totals of 2-12.
    RoundResult round(List<int> faces, {GameState? from}) => fightRound(
      rules: r,
      combat: fight,
      state: from ?? ff(fight: fight),
      random: ScriptedRandom(faces),
    );

    LuckResult luckTest(RoundResult round, List<int> faces) => testFightLuck(
      rules: r,
      combat: fight,
      state: round.state,
      random: ScriptedRandom(faces),
    );

    test('a round that hurts someone and goes on opens a test', () {
      final won = round([3, 3, 2, 2]);

      expect(won.state.combat!.luck!.enemy, 0);
      expect(won.state.combat!.luck!.dealt, 2);
      expect(won.state.combat!.luck!.taken, 0);
      expect(round([1, 1, 6, 6]).state.combat!.luck!.taken, 2);
    });

    test(
      'no test after a round that hurt nobody, killed or ended the fight',
      () {
        expect(round([3, 3, 4, 4]).state.combat!.luck, isNull);
        // The goblin has 4 health and dies from 2 + 2.
        final hurt = round([3, 3, 2, 2]);
        final killed = fightRound(
          rules: r,
          combat: fight,
          state: hurt.state.withCombat(CombatState(0, const [2, 4])),
          random: ScriptedRandom([3, 3, 2, 2]),
        );
        expect(killed.state.combat!.enemy, 1);
        expect(killed.state.combat!.luck, isNull);
        final single = combat([goblin]);
        final over = fightRound(
          rules: r,
          combat: single,
          state: ff(fight: single).withCombat(CombatState(0, const [2])),
          random: ScriptedRandom([3, 3, 2, 2]),
        );
        expect(over.outcome, CombatOutcome.won);
        expect(over.state.combat!.luck, isNull);
      },
    );

    test('no test is offered when the rules have no luck', () {
      final plain = fightRound(
        rules: rules('fighting-fantasy'),
        combat: fight,
        state: ff(fight: fight),
        random: ScriptedRandom([3, 3, 2, 2]),
      );

      expect(plain.state.combat!.luck, isNull);
    });

    test('lucky: the blow lands harder, and the luck stat drops', () {
      // Roll 5 against luck 8.
      final result = luckTest(round([3, 3, 2, 2]), [2, 3]);

      expect(result.lucky, isTrue);
      expect(result.roll.total, 5);
      expect(result.target, 8);
      expect(result.enemyLoss, 2);
      expect(result.state.combat!.enemyHealth, [0, 4]);
      expect(result.state.combat!.enemy, 1, reason: 'the goblin died');
      expect(result.state.combat!.luck, isNull);
      expect(result.state.stat('luck'), 7);
    });

    test('unlucky: the blow is weaker, but never below 0 and never healing past full', () {
      final result = luckTest(round([3, 3, 2, 2]), [6, 6]);

      expect(result.lucky, isFalse);
      expect(result.enemyLoss, -1);
      expect(result.state.combat!.enemyHealth, [3, 4]);
      expect(result.state.stat('luck'), 7);
    });

    test('lucky: a wound taken is smaller; unlucky: larger', () {
      final hit = round([1, 1, 6, 6]);

      final lucky = luckTest(hit, [1, 1]);
      expect(lucky.playerLoss, -1);
      expect(lucky.state.stat('stamina'), 11);

      final unlucky = luckTest(hit, [6, 6]);
      expect(unlucky.playerLoss, 1);
      expect(unlucky.state.stat('stamina'), 9);
    });

    test(
      'an unlucky test can kill the player; a lucky one can win the fight',
      () {
        final hit = round([1, 1, 6, 6], from: ff(stamina: 3, fight: fight));
        final dead = luckTest(hit, [6, 6]);
        expect(dead.outcome, CombatOutcome.lost);
        expect(dead.state.stat('stamina'), 0);

        final single = combat([goblin]);
        final strike = fightRound(
          rules: r,
          combat: single,
          state: ff(fight: single).withCombat(CombatState(0, const [3])),
          random: ScriptedRandom([3, 3, 2, 2]),
        );
        expect(strike.state.combat!.luck!.dealt, 2);
        final win = testFightLuck(
          rules: r,
          combat: single,
          state: strike.state,
          random: ScriptedRandom([1, 1]),
        );
        expect(win.outcome, CombatOutcome.won);
        expect(win.state.combat!.enemyHealth, [0]);
      },
    );

    test('testing with nothing open is a story bug', () {
      expect(
        () => testFightLuck(
          rules: r,
          combat: fight,
          state: ff(fight: fight),
          random: ScriptedRandom([1, 1]),
        ),
        throwsStateError,
      );
    });

    test('an item that costs the round closes the test', () {
      final strike = enemyStrike(
        rules: r,
        combat: fight,
        state: round([3, 3, 2, 2]).state,
        random: ScriptedRandom([6, 6]),
      );

      expect(strike.state.combat!.luck, isNull);
    });
  });

  group('several enemies at once', () {
    Combat pack({bool defense = false}) => Combat.fromJson(
      JsonObject({
        'enemies': [
          {'name': 'A', 'attack': 7, 'health': 4, if (defense) 'defense': 11},
          {'name': 'B', 'attack': 5, 'health': 4, if (defense) 'defense': 11},
        ],
        'win': 'w',
        'simultaneous': true,
      }, ''),
    );

    group('opposed', () {
      final r = rules('fighting-fantasy');

      GroupRoundResult play(List<int> faces, {int target = 0, int? stamina}) {
        final fight = pack();
        return groupRound(
          rules: r,
          combat: fight,
          state: ff(stamina: stamina ?? 12, fight: fight),
          random: ScriptedRandom(faces),
          target: target,
        );
      }

      test('the player rolls once and every enemy rolls its own', () {
        // Player 3+3+9 = 15; A 2+2+7 = 11 (loses, player wounds A for 2);
        // B 2+2+5 = 9 (loses to the player, but is not the target).
        final result = play([3, 3, 2, 2, 2, 2]);

        expect(result.playerTotal, 15);
        expect(result.attacks.map((a) => a.total), [11, 9]);
        expect(result.damageToEnemy, 2);
        expect(result.damageToPlayer, 0);
        expect(result.state.combat!.enemyHealth, [2, 4]);
      });

      test('an enemy that is not the target wounds the player if it wins', () {
        // Player 2+9 = 11; A 1+1+7 = 9 (target, loses, wounded for 2);
        // B 6+6+5 = 17 wins and wounds for 2.
        final result = play([1, 1, 1, 1, 6, 6]);

        expect(result.damageToEnemy, 2);
        expect(result.damageToPlayer, 2);
        expect(result.state.stat('stamina'), 10);
        expect(result.attacks[1].damageToPlayer, 2);
      });

      test('wounds from several enemies add up', () {
        // Player 2+9 = 11; A 6+6+7 = 25 and B 6+6+5 = 17 both win.
        final result = play([1, 1, 6, 6, 6, 6]);

        expect(result.damageToPlayer, 4);
        expect(result.state.stat('stamina'), 8);
        expect(result.damageToEnemy, 0);
      });

      test('the dead do not fight, and killing all of them wins', () {
        final fight = pack();
        final hurt = ff(fight: fight).withCombat(const CombatState(0, [2, 0]));
        final result = groupRound(
          rules: r,
          combat: fight,
          state: hurt,
          random: ScriptedRandom([3, 3, 2, 2]),
          target: 0,
        );

        expect(result.attacks.single.enemy.name, 'A');
        expect(result.outcome, CombatOutcome.won);
      });

      test('the player can die from the combined wounds', () {
        final result = play([1, 1, 6, 6, 6, 6], stamina: 3);

        expect(result.outcome, CombatOutcome.lost);
        expect(result.state.stat('stamina'), 0);
      });

      test('armor applies to the target', () {
        final fight = Combat.fromJson(
          JsonObject({
            'enemies': [
              {'name': 'A', 'attack': 7, 'health': 4, 'armor': 1},
            ],
            'win': 'w',
            'simultaneous': true,
          }, ''),
        );
        final result = groupRound(
          rules: r,
          combat: fight,
          state: ff(fight: fight),
          random: ScriptedRandom([3, 3, 2, 2]),
          target: 0,
        );

        expect(result.damageToEnemy, 1);
      });

      test('a dead or unknown target is a story bug', () {
        final fight = pack();
        expect(
          () => groupRound(
            rules: r,
            combat: fight,
            state: ff(fight: fight).withCombat(const CombatState(0, [0, 4])),
            random: ScriptedRandom([1, 1]),
            target: 0,
          ),
          throwsStateError,
        );
      });
    });

    group('vs-defense', () {
      final r = rules('d20-lite');
      GameState hero() => GameState(
        node: 'n',
        stats: {
          'might': const StatValue(3),
          'agility': const StatValue(2),
          'wits': const StatValue(1),
          'hp': const StatValue(10, 20),
        },
      ).withCombat(startCombat(pack(defense: true)));

      test('the player hits the target, then every living enemy attacks', () {
        // Player 8+3 = 11 >= 11 hits for 4: A dies and does not attack.
        // B: 10+5 = 15 >= 12 hits for its damage (1d6 = 3).
        final result = groupRound(
          rules: r,
          combat: pack(defense: true),
          state: hero(),
          random: ScriptedRandom([8, 4, 10, 3]),
          target: 0,
        );

        expect(result.damageToEnemy, 4);
        expect(result.attacks.map((a) => a.enemy.name), ['B']);
        expect(result.damageToPlayer, 3);
        expect(result.state.combat!.enemyHealth, [0, 4]);
        expect(result.outcome, CombatOutcome.ongoing);
      });

      test('a miss lets both enemies attack', () {
        // Player 7+3 = 10 misses; A 1+7 = 8 misses; B 1+5 = 6 misses.
        final result = groupRound(
          rules: r,
          combat: pack(defense: true),
          state: hero(),
          random: ScriptedRandom([7, 1, 1]),
          target: 1,
        );

        expect(result.damageToEnemy, 0);
        expect(result.attacks, hasLength(2));
        expect(result.damageToPlayer, 0);
      });
    });

    test(
      'luck: the test is on the target, and a lucky kill of the last wins',
      () {
        final r = Rules.resolve(
          RulesSpec.fromJson(
            JsonObject({
              'preset': 'fighting-fantasy',
              'combat': {
                'luck': {'stat': 'luck'},
              },
            }, 'rules'),
          ),
        );
        final fight = pack();
        final start = ff(fight: fight).withCombat(const CombatState(0, [0, 4]));
        // Player 15; B (index 1) 9: wounded for 2, B is the target.
        final round = groupRound(
          rules: r,
          combat: fight,
          state: start,
          random: ScriptedRandom([3, 3, 2, 2]),
          target: 1,
        );
        expect(round.state.combat!.luck!.enemy, 1);

        final lucky = testFightLuck(
          rules: r,
          combat: fight,
          state: round.state,
          random: ScriptedRandom([1, 1]),
        );

        expect(lucky.outcome, CombatOutcome.won);
        expect(lucky.state.combat!.enemyHealth, [0, 0]);
        expect(
          lucky.state.combat!.enemy,
          0,
          reason: 'the order does not matter',
        );
      },
    );
  });

  test('startCombat puts every enemy at full health', () {
    final state = startCombat(
      combat([
        goblin,
        {...goblin, 'health': 9},
      ]),
    );
    expect(state.enemy, 0);
    expect(state.enemyHealth, [4, 9]);
  });
}
