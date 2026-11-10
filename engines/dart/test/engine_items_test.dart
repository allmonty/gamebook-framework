import 'dart:convert';

import 'package:gamebook_engine/combat.dart';
import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// hall -> ring (a fight; win -> won, flee -> hall). Items: a potion that heals
/// 6 and costs the round, a tonic that heals 2 for free in a fight, a scroll
/// that only works on a page, poison that kills, and a key with no use.
Story story(String preset, {Map<String, Object?>? enemy}) => Story.fromJson({
  'schema': 2,
  'id': 'items',
  'lang': 'en',
  'title': 'Items',
  'rules': {'preset': preset},
  'start': 'hall',
  'items': {
    'potion': {
      'name': 'Potion',
      'use': {
        'effects': [
          {'stat': preset == 'd20-lite' ? 'hp' : 'stamina', 'add': 6},
        ],
        'when': ['story', 'combat'],
      },
    },
    'tonic': {
      'name': 'Tonic',
      'use': {
        'effects': [
          {'stat': preset == 'd20-lite' ? 'hp' : 'stamina', 'add': 2},
        ],
        'when': ['combat'],
        'combatCost': 'free',
      },
    },
    'scroll': {
      'name': 'Scroll',
      'use': {
        'effects': [
          {'set': 'read'},
        ],
        'when': ['story'],
      },
    },
    'poison': {
      'name': 'Poison',
      'use': {
        'effects': [
          {'stat': preset == 'd20-lite' ? 'hp' : 'stamina', 'add': -99},
        ],
        'when': ['story', 'combat'],
      },
    },
    'key': {'name': 'Key'},
  },
  'nodes': {
    'hall': {
      'text': 'Hall',
      'choices': [
        {'text': 'Fight', 'to': 'ring'},
      ],
    },
    'ring': {
      'text': 'Ring',
      'combat': {
        'enemies': [
          enemy ?? {'name': 'Goblin', 'attack': 7, 'health': 6, 'defense': 11},
        ],
        'win': 'won',
        'flee': 'hall',
      },
    },
    'won': {'text': 'Won', 'ending': 'victory'},
  },
});

const bag = {'potion', 'tonic', 'scroll', 'poison', 'key'};

GameEngine engine(
  Story s, {
  int health = 10,
  int healthMax = 24,
  Set<String> items = bag,
  GameState? state,
  List<int> dice = const [],
}) {
  final ff = s.rules.preset == 'fighting-fantasy';
  return GameEngine(
    story: s,
    rules: Rules.resolve(s.rules),
    random: ScriptedRandom(dice),
    state:
        state ??
        GameState(
          node: 'hall',
          inventory: items,
          stats: ff
              ? {
                  'skill': const StatValue(9, 12),
                  'stamina': StatValue(health, healthMax),
                  'luck': const StatValue(8, 12),
                }
              : {
                  'might': const StatValue(3),
                  'agility': const StatValue(2),
                  'wits': const StatValue(1),
                  'hp': StatValue(health, healthMax),
                },
        ),
  );
}

GameEngine inFight(Story s, {int health = 10, List<int> dice = const []}) {
  final e = engine(s, health: health, dice: dice);
  e.choose(0);
  return e;
}

void main() {
  final ff = story('fighting-fantasy');

  group('canUse', () {
    test('on a page: only items that work in the story', () {
      final e = engine(ff);

      expect(e.canUse('potion'), isTrue);
      expect(e.canUse('scroll'), isTrue);
      expect(e.canUse('tonic'), isFalse, reason: 'combat only');
      expect(e.canUse('key'), isFalse, reason: 'has no use');
      expect(e.canUse('nope'), isFalse);
    });

    test('in a fight: only items that work in a fight', () {
      final e = inFight(ff);

      expect(e.canUse('potion'), isTrue);
      expect(e.canUse('tonic'), isTrue);
      expect(e.canUse('scroll'), isFalse, reason: 'story only');
      expect(e.canUse('key'), isFalse);
    });

    test('an item you do not hold cannot be used', () {
      expect(engine(ff, items: {}).canUse('potion'), isFalse);
    });

    test('nothing can be used once the game has ended', () {
      final e = engine(
        ff,
        state: const GameState(
          node: 'won',
          inventory: {'potion'},
          stats: {'stamina': StatValue(5, 24)},
        ),
      );
      expect(e.canUse('potion'), isFalse);
    });
  });

  group('on a page', () {
    test('applies the effects, consumes the item and reports it', () {
      final e = engine(ff, health: 10);

      final events = e.useItem('potion');

      expect(e.state.stat('stamina'), 16);
      expect(e.state.inventory, {'tonic', 'scroll', 'poison', 'key'});
      expect(events.first, isA<ItemUsed>());
      expect((events.first as ItemUsed).item, 'potion');
      expect(events.whereType<ItemLost>(), isEmpty);
      final change = events.whereType<StatChanged>().single;
      expect((change.stat, change.from, change.to), ('stamina', 10, 16));
      expect(e.node.id, 'hall', reason: 'using an item moves nowhere');
    });

    test('healing stops at the maximum', () {
      final e = engine(ff, health: 22, healthMax: 24);

      e.useItem('potion');

      expect(e.state.stat('stamina'), 24);
    });

    test('flags and other effects apply too', () {
      final e = engine(ff);

      e.useItem('scroll');

      expect(e.state.flags, {'read'});
    });

    test('an item that kills ends the game', () {
      final e = engine(ff);

      final events = e.useItem('poison');

      expect(e.ending, Ending.death);
      expect((events.last as Ended).ending, Ending.death);
    });

    test('using something that cannot be used throws', () {
      final e = engine(ff);

      expect(() => e.useItem('key'), throwsStateError);
      expect(() => e.useItem('tonic'), throwsStateError);
      expect(() => e.useItem('nope'), throwsStateError);
    });
  });

  group('in a fight, opposed mode', () {
    test('an item that costs the round lets the enemy strike', () {
      final e = inFight(ff, health: 10);

      final events = e.useItem('potion');

      // Healed 6, then the goblin wins the round automatically: -2.
      expect(e.state.stat('stamina'), 14);
      final strike = events.whereType<CombatStrike>().single.result;
      expect(strike.damageToPlayer, 2);
      expect(strike.enemyAttack, isNull, reason: 'no contest in opposed mode');
      expect(events.first, isA<ItemUsed>());
      expect(e.state.combat!.enemyHealth, [6]);
      expect(e.node.id, 'ring');
    });

    test('a free item does not', () {
      final e = inFight(ff, health: 10);

      final events = e.useItem('tonic');

      expect(e.state.stat('stamina'), 12);
      expect(events.whereType<CombatStrike>(), isEmpty);
    });

    test('the enemy may override its damage', () {
      final s = story(
        'fighting-fantasy',
        enemy: {'name': 'Ogre', 'attack': 9, 'health': 9, 'damage': '3'},
      );
      final e = inFight(s, health: 10);

      e.useItem('potion');

      expect(e.state.stat('stamina'), 13);
    });

    test('death by the strike ends the game', () {
      final s = story(
        'fighting-fantasy',
        enemy: {'name': 'Ogre', 'attack': 9, 'health': 9, 'damage': '20'},
      );
      final e = inFight(s, health: 10);

      final events = e.useItem('potion'); // 16 - 20 -> 0

      expect(e.state.stat('stamina'), 0);
      expect(e.ending, Ending.death);
      expect((events.last as Ended).ending, Ending.death);
      expect(
        events.whereType<CombatStrike>().single.result.outcome,
        CombatOutcome.lost,
      );
    });

    test('an item that kills the player means no strike', () {
      final e = inFight(ff, health: 10);

      final events = e.useItem('poison');

      expect(events.whereType<CombatStrike>(), isEmpty);
      expect(e.ending, Ending.death);
    });
  });

  group('in a fight, vs-defense mode', () {
    final d20 = story('d20-lite');

    test('the enemy rolls its attack against your defense and can hit', () {
      // Enemy d20 10 + attack 7 = 17 >= 10 + agility 2 = 12: hit for 1d6 = 4.
      final e = inFight(d20, dice: [10, 4]);

      final events = e.useItem('potion');

      final strike = events.whereType<CombatStrike>().single.result;
      expect(strike.enemyTotal, 17);
      expect(strike.enemyTarget, 12);
      expect(strike.damageToPlayer, 4);
      expect(e.state.stat('hp'), 12); // 10 + 6 - 4
    });

    test('or miss', () {
      // 2 + 7 = 9 < 12.
      final e = inFight(d20, dice: [2]);

      final strike = e
          .useItem('potion')
          .whereType<CombatStrike>()
          .single
          .result;

      expect(strike.damageToPlayer, 0);
      expect(e.state.stat('hp'), 16);
    });
  });

  test('a saved fight in progress survives using an item', () {
    final e = inFight(ff);
    final saved = jsonDecode(jsonEncode(e.state.toJson()));

    final restored = GameEngine(
      story: ff,
      rules: Rules.resolve(ff.rules),
      random: ScriptedRandom([]),
      state: GameState.fromJson(saved),
    );
    restored.useItem('tonic');

    expect(restored.combat, isNotNull);
    expect(restored.state.combat!.enemyHealth, [6]);
  });
}
