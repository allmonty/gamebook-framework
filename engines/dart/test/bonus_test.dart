import 'dart:convert';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// A smith who gives a sword (+2 Skill) and a cursed ring (-1 Luck) and a
/// door that needs Skill 10, and a fight.
Story story({Map<String, Object?>? swordBonus, String pickup = 'auto'}) =>
    Story.fromJson({
      'schema': 5,
      'id': 'smith',
      'lang': 'en',
      'title': 'Smith',
      'rules': {
        'preset': 'fighting-fantasy',
        'inventory': {'pickup': pickup},
      },
      'items': {
        'sword': {
          'name': 'Sword',
          'bonus': swordBonus ?? {'skill': 2},
        },
        'ring': {
          'name': 'Ring',
          'bonus': {'luck': -1, 'skill': 1},
        },
      },
      'start': 'forge',
      'nodes': {
        'forge': {
          'text': 'Skill {skill}. Luck {luck}.',
          'choices': [
            {
              'text': 'Take the sword',
              'to': 'forge',
              'effects': [
                {'give': 'sword'},
              ],
            },
            {
              'text': 'Take the ring',
              'to': 'forge',
              'effects': [
                {'give': 'ring'},
              ],
            },
            {
              'text': 'Drop the sword',
              'to': 'forge',
              'effects': [
                {'take': 'sword'},
              ],
            },
            {
              'text': 'Open the door',
              'to': 'inside',
              'if': {'stat': 'skill', 'gte': 10},
            },
            {
              'text': 'Test your skill',
              'check': {
                'roll': '2d6',
                'add': 'skill',
                'op': 'gte',
                'vs': 15,
                'pass': 'inside',
                'fail': 'forge',
              },
            },
            {'text': 'Fight', 'to': 'ring'},
          ],
        },
        'ring': {
          'text': 'A rat.',
          'combat': {
            'enemies': [
              {'name': 'Rat', 'attack': 7, 'health': 6},
            ],
            'win': 'inside',
          },
        },
        'inside': {'text': 'In', 'ending': 'victory'},
      },
    });

GameEngine start({Story? s, List<int> dice = const []}) {
  final st = s ?? story();
  return GameEngine.newGame(
    story: st,
    rules: Rules.resolve(st.rules),
    random: ScriptedRandom(dice),
    stats: const {
      'skill': StatValue(9, 9),
      'stamina': StatValue(12, 12),
      'luck': StatValue(8, 8),
    },
  ).$1;
}

void main() {
  group('parse', () {
    test('a bonus is a map of stat to integer, none by default', () {
      final s = story();

      expect(s.items['sword']!.bonus, {'skill': 2});
      expect(s.items['ring']!.bonus, {'luck': -1, 'skill': 1});
    });

    test('errors name the path', () {
      String error(Object? bonus, {int schema = 5}) {
        final json = {
          'schema': schema,
          'id': 'x',
          'lang': 'en',
          'title': 'x',
          'rules': {'preset': 'fighting-fantasy'},
          'items': {
            'a': {'name': 'A', 'bonus': bonus},
          },
          'start': 'n',
          'nodes': {
            'n': {'text': 't', 'ending': 'victory'},
          },
        };
        try {
          Story.fromJson(json);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(error({'skill': 1.5}), 'items.a.bonus.skill: expected an integer');
      expect(error({'skill': 'a'}), 'items.a.bonus.skill: expected an integer');
      expect(error({'bad id': 1}), startsWith('items.a.bonus: invalid id'));
      expect(
        error({'skill': 1}, schema: 4),
        'items.a.bonus: needs "schema": 5',
      );
    });
  });

  group('while the item is carried', () {
    test('the stat is higher everywhere, and the base is untouched', () {
      final e = start();

      e.choose(0); // the sword

      expect(e.state.stat('skill'), 11);
      expect(
        e.state.stats['skill']!.value,
        9,
        reason: 'the stat itself is unchanged',
      );
      expect(e.state.stats['skill']!.max, 9);
      expect(e.state.bonusOf('skill'), 2);
      expect(e.state.bonusOf('luck'), 0);
    });

    test('conditions see it', () {
      final e = start();
      expect(e.choices[3].locked, isTrue, reason: 'skill 9 < 10');

      e.choose(0);

      expect(e.choices[3].locked, isFalse, reason: 'skill 11');
    });

    test('checks add it, and a bonus can be negative', () {
      final e = start(dice: [2, 2]); // 4 + 9 = 13 < 15 without the sword
      e.choose(0);
      e.choose(1); // sword (+2) and ring (+1 skill, -1 luck)

      final events = e.choose(4);

      final result = events.whereType<CheckRolled>().single.result;
      expect(result.added, 12);
      expect(result.total, 16);
      expect(result.passed, isTrue);
      expect(e.state.stat('luck'), 7);
    });

    test('combat uses it', () {
      final e = start(dice: [3, 3, 3, 3]); // 6 + skill vs 6 + 7
      e.choose(0);
      e.choose(5);

      final round = e.fight().whereType<CombatRound>().single.result;

      expect(round.playerTotal, 17, reason: '6 + 9 + 2');
    });

    test('text placeholders show the value with the bonus', () {
      final e = start();
      expect(e.paragraphs.single, 'Skill 9. Luck 8.');

      e.choose(1);

      expect(e.paragraphs.single, 'Skill 10. Luck 7.');
    });

    test('a bonus never takes the value below 0, and the base is kept', () {
      final e = start(s: story(swordBonus: {'luck': -20}));

      e.choose(0);

      expect(e.state.stat('luck'), 0);
      expect(e.state.stats['luck']!.value, 8);
      expect(e.paragraphs.single, 'Skill 9. Luck 0.');

      e.choose(2);

      expect(e.state.stat('luck'), 8);
    });

    test('losing the item takes the bonus away', () {
      final e = start();
      e.choose(0);
      expect(e.state.stat('skill'), 11);

      e.choose(2);

      expect(e.state.stat('skill'), 9);
      expect(e.state.statBonus, isEmpty);
    });

    test('an item that is only offered gives nothing until taken', () {
      final e = start(s: story(pickup: 'choose'));
      e.choose(0);
      expect(e.state.offers, ['sword']);
      expect(e.state.stat('skill'), 9);

      e.resolveOffer(take: true);

      expect(e.state.stat('skill'), 11);
    });

    test('a saved game gets its bonuses back', () {
      final e = start();
      e.choose(0);
      final saved = jsonDecode(jsonEncode(e.state.toJson()));
      expect(saved.toString(), isNot(contains('statBonus')));

      final s = story();
      final restored = GameEngine(
        story: s,
        rules: Rules.resolve(s.rules),
        random: ScriptedRandom([]),
        state: GameState.fromJson(saved),
      );

      expect(restored.state.stat('skill'), 11);
    });
  });

  group('validation', () {
    List<String> errorsOf(Story s) => [
      for (final i in validateStory(s))
        if (i.severity == Severity.error) i.toString(),
    ];

    test('a bonus must name a stat of the story', () {
      expect(errorsOf(story(swordBonus: {'charm': 1})), [
        'error: items.sword.bonus.charm: unknown stat "charm"',
      ]);
    });

    test('a bonus to the health stat is not allowed', () {
      expect(errorsOf(story(swordBonus: {'stamina': 3})), [
        'error: items.sword.bonus.stamina: a bonus to the health stat is not allowed',
      ]);
    });

    test('a good story has no errors', () {
      expect(errorsOf(story()), isEmpty);
    });
  });
}
