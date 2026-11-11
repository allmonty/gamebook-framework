import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Rules rulesOf(Story story) => Rules.resolve(story.rules);

Map<String, StatValue> stats({int skill = 9, int stamina = 12, int luck = 8}) =>
    {
      'skill': StatValue(skill, 12),
      'stamina': StatValue(stamina, 24),
      'luck': StatValue(luck, 12),
    };

(GameEngine, List<GameEvent>) start(
  Story story, {
  Random? random,
  Map<String, StatValue>? initial,
}) => GameEngine.newGame(
  story: story,
  rules: rulesOf(story),
  random: random ?? ScriptedRandom([]),
  stats: initial ?? stats(),
);

Story rustyDoor() =>
    Story.parse(File('test/fixtures/rusty-door.en.json').readAsStringSync());

/// A small story with a heal-once well, a fight with a way out, and a lethal
/// check.
Story arena() => Story.fromJson(
  jsonDecode('''
{
  "schema": 1, "id": "arena", "lang": "en", "title": "Arena",
  "rules": { "preset": "fighting-fantasy" },
  "start": "hall",
  "nodes": {
    "hall": { "text": "Hall",
      "choices": [
        { "text": "Drink", "to": "well" },
        { "text": "Fight", "to": "ring" },
        { "text": "Hidden door", "to": "hall",
          "if": { "stat": "luck", "gte": 99 }, "hideIfLocked": true },
        { "text": "Poison", "check": { "roll": "1d6", "op": "gte", "vs": 1,
          "pass": "hall", "fail": "hall", "effects": [ { "stat": "stamina", "add": -99 } ] } }
      ] },
    "well": { "text": "Well", "once": true, "effects": [ { "stat": "stamina", "add": 3 } ],
      "choices": [ { "text": "Back", "to": "hall" } ] },
    "ring": { "text": "Ring",
      "combat": { "enemies": [ { "name": "Goblin", "attack": 7, "health": 4 } ],
        "win": "prize", "flee": "hall" } },
    "prize": { "text": "Prize", "effects": [ { "give": "medal" } ], "ending": "victory" }
  },
  "items": { "medal": { "name": "Medal" } }
}
''') as Map<String, Object?>,
);

void main() {
  test('a condition that fails with nothing to name still locks', () {
    final story = Story.fromJson({
      'schema': 1,
      'id': 'c',
      'lang': 'en',
      'title': 'C',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'a',
      'nodes': {
        'a': {
          'text': 'A',
          'choices': [
            {
              'text': 'Never',
              'to': 'won',
              'if': {'any': <Object?>[]},
            },
            {
              'text': 'Never either',
              'to': 'won',
              'if': {
                'not': {'all': <Object?>[]},
              },
            },
          ],
        },
        'won': {'text': 'Won', 'ending': 'victory'},
      },
    });
    final (engine, _) = start(story);
    expect([for (final c in engine.choices) c.locked], [true, true]);
    expect(() => engine.choose(0), throwsStateError);
  });

  group('draft pages (schema 6)', () {
    Story drafted() => Story.fromJson(
      jsonDecode('''
{
  "schema": 6, "id": "d", "lang": "en", "title": "D",
  "rules": { "preset": "fighting-fantasy" },
  "start": "hall",
  "nodes": {
    "hall": { "text": "Hall", "choices": [
      { "text": "Cellar", "to": "cellar" }, { "text": "Ring", "to": "ring" } ] },
    "cellar": { "draft": true, "text": "Dark.", "effects": [ { "set": "dark" } ],
      "choices": [ { "text": "Back", "to": "hall" } ], "ending": "victory" },
    "ring": { "draft": true,
      "combat": { "enemies": [ { "name": "Rat", "attack": 1, "health": 1 } ], "win": "hall" } }
  }
}
''') as Map<String, Object?>,
    );

    test('entering one applies its effects and offers nothing', () {
      final (engine, _) = start(drafted());
      engine.choose(0);

      expect(engine.node.id, 'cellar');
      expect(engine.state.flags, {'dark'});
      expect(engine.paragraphs, ['Dark.']);
      expect(engine.choices, isEmpty);
      expect(engine.ending, isNull);
      expect(() => engine.choose(0), throwsStateError);
    });

    test('a draft fight does not start', () {
      final (engine, _) = start(drafted());
      engine.choose(1);

      expect(engine.combat, isNull);
      expect(engine.state.combat, isNull);
      expect(() => engine.fight(), throwsStateError);
    });
  });

  group('rusty door walkthrough', () {
    final story = rustyDoor();

    test('starts on the first node', () {
      final (engine, events) = start(story);

      expect(engine.node.id, 'cellar');
      expect(events.single, isA<NodeEntered>());
      expect(engine.ending, isNull);
      expect(engine.choices.map((c) => c.index), [0, 1]);
    });

    test('a locked choice shows why and cannot be taken', () {
      final (engine, _) = start(story);
      engine.choose(1);

      final unlock = engine.choices.first;
      expect(unlock.locked, isTrue);
      expect((unlock.unmet.single.condition as HasItem).item, 'rusty-key');
      expect(() => engine.choose(0), throwsStateError);
    });

    test('picking up the key unlocks the door and the game is won', () {
      final (engine, _) = start(story);

      final pickup = engine.choose(0);
      expect(pickup.whereType<ItemGained>().single.item, 'rusty-key');
      engine.choose(0); // back to the cellar
      engine.choose(1); // to the door
      expect(engine.choices.first.locked, isFalse);

      final events = engine.choose(0);

      expect(engine.node.id, 'treasure');
      expect(engine.ending, Ending.victory);
      expect(events.last, isA<Ended>());
      expect((events.last as Ended).ending, Ending.victory);
      expect(engine.choices, isEmpty);
      expect(() => engine.choose(0), throwsStateError);
    });

    test('a check that passes goes to pass, with the dice in the events', () {
      final (engine, _) = start(story, random: ScriptedRandom([6, 6]));
      engine.choose(1);

      final events = engine.choose(1); // skill 9 + 12 >= 15

      final rolled = events.whereType<CheckRolled>().single.result;
      expect(rolled.passed, isTrue);
      expect(rolled.total, 21);
      expect(engine.node.id, 'treasure');
    });

    test('a check that fails goes to fail and its node effects apply', () {
      final (engine, _) = start(story, random: ScriptedRandom([1, 1]));
      engine.choose(1);

      final events = engine.choose(1);

      expect(engine.node.id, 'foot');
      expect(engine.state.stat('stamina'), 10);
      final change = events.whereType<StatChanged>().single;
      expect((change.stat, change.from, change.to), ('stamina', 12, 10));
    });

    test(
      'dying from node effects ends the game even on a node with choices',
      () {
        final (engine, _) = start(
          story,
          random: ScriptedRandom([1, 1]),
          initial: stats(stamina: 2),
        );
        engine.choose(1);

        final events = engine.choose(1);

        expect(engine.node.id, 'foot');
        expect(engine.ending, Ending.death);
        expect((events.last as Ended).ending, Ending.death);
        expect(engine.choices, isEmpty);
      },
    );

    test('a saved state restores to the same place', () {
      final (engine, _) = start(story);
      engine.choose(0);
      final saved = jsonDecode(jsonEncode(engine.state.toJson()));

      final restored = GameEngine(
        story: story,
        rules: rulesOf(story),
        random: ScriptedRandom([]),
        state: GameState.fromJson(saved),
      );

      expect(restored.node.id, 'shelves');
      expect(restored.state.inventory, {'rusty-key'});
      restored.choose(0);
      expect(restored.node.id, 'cellar');
    });
  });

  group('node rules', () {
    final story = arena();

    test('a once node applies its effects only the first time', () {
      final (engine, _) = start(story, initial: stats(stamina: 10));

      engine.choose(0);
      expect(engine.state.stat('stamina'), 13);
      engine.choose(0); // back to the hall
      engine.choose(0); // the well again
      expect(engine.state.stat('stamina'), 13);
      expect(engine.state.visited, containsAll(['hall', 'well']));
    });

    test('hideIfLocked drops a locked choice from the list', () {
      final (engine, _) = start(story);

      expect(engine.choices.map((c) => c.index), [0, 1, 3]);
    });

    test('check effects apply after the roll, whichever way it went', () {
      final (engine, _) = start(story, random: ScriptedRandom([3]));

      final events = engine.choose(3);

      expect(events.whereType<CheckRolled>().single.result.passed, isTrue);
      expect(engine.state.stat('stamina'), 0);
      expect(engine.ending, Ending.death);
    });
  });

  group('fights', () {
    final story = arena();

    GameEngine atRing({List<int> dice = const [], int stamina = 12}) {
      final (engine, _) = start(
        story,
        random: ScriptedRandom(dice),
        initial: stats(stamina: stamina),
      );
      engine.choose(1);
      return engine;
    }

    test('entering the page starts a fight with no choices to pick', () {
      final engine = atRing();

      expect(engine.combat, isNotNull);
      expect(engine.canFlee, isTrue);
      expect(engine.choices, isEmpty);
      expect(engine.state.combat!.enemyHealth, [4]);
      expect(() => engine.choose(0), throwsStateError);
    });

    test(
      'rounds are fought until the enemy falls, then the win page opens',
      () {
        // Two rounds: player 6+6+9 beats goblin 1+1+7, twice (2 damage each).
        final engine = atRing(dice: [6, 6, 1, 1, 6, 6, 1, 1]);

        final first = engine.fight();
        expect(first.whereType<CombatRound>().single.result.damageToEnemy, 2);
        expect(engine.node.id, 'ring');

        final second = engine.fight();

        expect(engine.node.id, 'prize');
        expect(engine.state.combat, isNull);
        expect(second.whereType<ItemGained>().single.item, 'medal');
        expect((second.last as Ended).ending, Ending.victory);
      },
    );

    test('fleeing goes to the flee page and drops the fight', () {
      final engine = atRing();

      final events = engine.flee();

      expect(engine.node.id, 'hall');
      expect(engine.state.combat, isNull);
      expect(events.first, isA<NodeEntered>());
      expect(() => engine.fight(), throwsStateError);
    });

    test('losing the last stamina ends the game in death', () {
      final engine = atRing(dice: [1, 1, 6, 6], stamina: 2);

      final events = engine.fight();

      expect(engine.state.stat('stamina'), 0);
      expect(engine.ending, Ending.death);
      expect((events.last as Ended).ending, Ending.death);
      expect(() => engine.fight(), throwsStateError);
    });

    test('fighting outside a fight is an error', () {
      final (engine, _) = start(story);
      expect(() => engine.fight(), throwsStateError);
      expect(() => engine.flee(), throwsStateError);
    });

    test('re-entering the fight after fleeing starts it fresh', () {
      final engine = atRing(dice: [6, 6, 1, 1]);
      engine.fight();
      expect(engine.state.combat!.enemyHealth, [2]);
      engine.flee();
      engine.choose(1);

      expect(engine.state.combat!.enemyHealth, [4]);
    });
  });

  group('a shop with stat quantities and a gold limit', () {
    Story shop() => Story.fromJson({
      'schema': 5,
      'id': 'shop',
      'lang': 'en',
      'title': 'Shop',
      'rules': {
        'preset': 'fighting-fantasy',
        'stats': {
          'gold': {'roll': '5', 'limit': 12},
          'price': {'roll': '4'},
        },
      },
      'start': 'stall',
      'nodes': {
        'stall': {
          'text': 'Gold {gold} of {gold.max}. Price {price}.',
          'choices': [
            {
              'text': 'Buy a lamp',
              'to': 'stall',
              'if': {
                'stat': 'gold',
                'gte': {'stat': 'price'},
              },
              'effects': [
                {
                  'stat': 'gold',
                  'add': {'stat': 'price', 'times': -1},
                },
                {'stat': 'price', 'add': 2},
              ],
            },
            {
              'text': 'Find a purse',
              'to': 'stall',
              'effects': [
                {'stat': 'gold', 'add': 100},
              ],
            },
            {
              'text': 'Spend it all',
              'to': 'stall',
              'effects': [
                {'stat': 'gold', 'set': 0},
              ],
            },
          ],
        },
      },
    });

    GameEngine open() {
      final s = shop();
      return GameEngine.newGame(
        story: s,
        rules: rulesOf(s),
        random: ScriptedRandom([]),
        stats: {
          ...stats(),
          'gold': const StatValue(5, 12),
          'price': const StatValue(4),
        },
      ).$1;
    }

    test('a purchase compares one stat with another and pays from it', () {
      final e = open();
      expect(e.choices.first.locked, isFalse);

      e.choose(0);

      expect(e.state.stat('gold'), 1);
      expect(e.state.stat('price'), 6);
      expect(e.choices.first.locked, isTrue, reason: '1 < 6');
      expect(e.choices.first.unmet.single.target, 6);
    });

    test('the limit caps what you can carry, and set empties it', () {
      final e = open();

      e.choose(1);
      expect(e.state.stat('gold'), 12);
      e.choose(2);
      expect(e.state.stat('gold'), 0);
    });

    test('the text shows the value and the limit', () {
      final e = open();

      expect(e.paragraphs.single, 'Gold 5 of 12. Price 4.');
    });
  });

  group('page text and placeholders', () {
    Story inn({int schema = 4}) => Story.fromJson({
      'schema': schema,
      'id': 'inn',
      'lang': 'en',
      'title': 'Inn',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'bar',
      'nodes': {
        'bar': {
          'text': [
            'The innkeeper looks you over.',
            {
              'if': {'flag': 'met'},
              'text': '"Back again?" he says.',
            },
            {
              'if': {'stat': 'stamina', 'lte': 12},
              'text':
                  'You look tired: {stamina} of {stamina.max}.\n\nSit down.',
            },
            'Luck {luck}, skill {skill}, mana {mana}, {{braces}}.',
          ],
          'choices': [
            {
              'text': 'Greet him',
              'to': 'bar',
              'effects': [
                {'set': 'met'},
                {'stat': 'stamina', 'add': 5},
              ],
            },
            {'text': 'Pay {luck} crowns', 'to': 'bar'},
          ],
        },
      },
    });

    GameEngine play({Story? story, int stamina = 12}) {
      final s = story ?? inn();
      return GameEngine.newGame(
        story: s,
        rules: rulesOf(s),
        random: ScriptedRandom([]),
        stats: {...stats(luck: 6), 'stamina': StatValue(stamina, 24)},
      ).$1;
    }

    test('shows the plain parts and those whose condition holds', () {
      final e = play();

      expect(e.paragraphs, [
        'The innkeeper looks you over.',
        'You look tired: 12 of 24.',
        'Sit down.',
        'Luck 6, skill 9, mana {mana}, {braces}.',
      ]);
    });

    test('follows the state: flags and stats change the page', () {
      final e = play()..choose(0); // met, +5 stamina

      expect(e.paragraphs, [
        'The innkeeper looks you over.',
        '"Back again?" he says.',
        'Luck 6, skill 9, mana {mana}, {braces}.',
      ]);
    });

    test('a part with a false condition is simply left out', () {
      expect(play(stamina: 20).paragraphs, hasLength(2));
    });

    test('choice text gets the same placeholders', () {
      final e = play();

      expect(e.choices.map((c) => c.text), ['Greet him', 'Pay 6 crowns']);
      expect(e.choices.last.choice.text, 'Pay {luck} crowns');
    });

    test('a story before schema 4 keeps its braces', () {
      final s = Story.fromJson({
        'schema': 3,
        'id': 'old',
        'lang': 'en',
        'title': 'Old',
        'rules': {'preset': 'fighting-fantasy'},
        'start': 'a',
        'nodes': {
          'a': {
            'text': 'Keep {luck} as it is.',
            'choices': [
              {'text': 'Go {skill}', 'to': 'a'},
            ],
          },
        },
      });
      final e = play(story: s);

      expect(e.paragraphs, ['Keep {luck} as it is.']);
      expect(e.choices.single.text, 'Go {skill}');
    });
  });

  group('random tables', () {
    Story searching() => Story.fromJson({
      'schema': 4,
      'id': 'table',
      'lang': 'en',
      'title': 'Table',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'rubble',
      'nodes': {
        'rubble': {
          'text': 'Rubble',
          'choices': [
            {
              'text': 'Search',
              'table': {
                'roll': '1d6',
                'outcomes': [
                  {'upTo': 2, 'to': 'nothing'},
                  {
                    'upTo': 5,
                    'to': 'coins',
                    'effects': [
                      {'stat': 'luck', 'add': 2},
                    ],
                  },
                  {'upTo': 6, 'to': 'gem'},
                ],
              },
            },
          ],
        },
        'nothing': {'text': 'Nothing', 'ending': 'death'},
        'coins': {'text': 'Coins', 'ending': 'victory'},
        'gem': {'text': 'Gem', 'ending': 'victory'},
      },
    });

    (GameEngine, List<GameEvent>) roll(int face) {
      final s = searching();
      final (e, _) = GameEngine.newGame(
        story: s,
        rules: rulesOf(s),
        random: ScriptedRandom([face]),
        stats: stats(luck: 5),
      );
      return (e, e.choose(0));
    }

    test('each range leads to its own page', () {
      for (final (face, page) in [
        (1, 'nothing'),
        (2, 'nothing'),
        (3, 'coins'),
        (5, 'coins'),
        (6, 'gem'),
      ]) {
        expect(roll(face).$1.node.id, page, reason: 'rolled $face');
      }
    });

    test('the outcome effects apply and the roll is reported', () {
      final (e, events) = roll(4);

      expect(e.state.stat('luck'), 7);
      final rolled = events.whereType<TableRolled>().single.roll;
      expect(rolled.dice, [4]);
      expect(rolled.total, 4);
    });

    test('the other outcomes leave the stats alone', () {
      expect(roll(6).$1.state.stat('luck'), 5);
    });
  });

  group('visit counts', () {
    test('start at one for the first page', () {
      final (e, _) = start(rustyDoor());

      expect(e.state.visitsTo('cellar'), 1);
      expect(e.state.visitsTo('door'), 0);
    });

    test('go up each time a page is entered again', () {
      final (e, _) = start(rustyDoor(), random: ScriptedRandom([1, 1, 1, 1]));
      expect(e.state.visitsTo('door'), 0);

      e.choose(1); // door
      expect(e.state.visitsTo('door'), 1);
      e.choose(1); // kick: fails (1+1+9 < 15), foot
      e.choose(0); // try something else: door again
      e.choose(1); // kick: fails, foot
      e.choose(0); // door a third time

      expect(e.state.visitsTo('door'), 3);
      expect(e.state.visitsTo('foot'), 2);
      expect(e.state.visitsTo('cellar'), 1);
      expect(e.state.visited, containsAll(['cellar', 'door', 'foot']));
    });

    test('a page that links to itself counts each time', () {
      final s = Story.fromJson({
        'schema': 4,
        'id': 'loop',
        'lang': 'en',
        'title': 'Loop',
        'rules': {'preset': 'fighting-fantasy'},
        'start': 'a',
        'nodes': {
          'a': {
            'text': 'x',
            'choices': [
              {'text': 'Again', 'to': 'a'},
              {
                'text': 'Enough',
                'to': 'b',
                'if': {'visits': 'a', 'gte': 3},
              },
            ],
          },
          'b': {'text': 'y', 'ending': 'victory'},
        },
      });
      final (e, _) = GameEngine.newGame(
        story: s,
        rules: rulesOf(s),
        random: ScriptedRandom([]),
        stats: stats(),
      );

      expect(e.choices.last.locked, isTrue);
      e.choose(0);
      expect(e.choices.last.locked, isTrue);
      e.choose(0);
      expect(e.choices.last.locked, isFalse);
      e.choose(1);

      expect(e.state.visitsTo('a'), 3);
      expect(e.ending, Ending.victory);
    });

    test('are saved and restored', () {
      final (e, _) = start(rustyDoor());
      e.choose(0);
      e.choose(0);
      final saved = jsonDecode(jsonEncode(e.state.toJson()));

      final restored = GameEngine(
        story: e.story,
        rules: e.rules,
        random: ScriptedRandom([]),
        state: GameState.fromJson(saved),
      );

      expect(restored.state.visitsTo('cellar'), 2);
      expect(restored.state.visitsTo('shelves'), 1);
    });
  });

  group('once-only choices', () {
    Story searching() => Story.fromJson({
      'schema': 4,
      'id': 'once',
      'lang': 'en',
      'title': 'Once',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'yard',
      'nodes': {
        'yard': {
          'text': 'Yard',
          'choices': [
            {
              'text': 'Search the rubble',
              'to': 'yard',
              'once': true,
              'effects': [
                {'stat': 'luck', 'add': 1},
              ],
            },
            {
              'text': 'Try the lock',
              'once': true,
              'check': {
                'roll': '1d6',
                'op': 'gte',
                'vs': 6,
                'pass': 'inside',
                'fail': 'yard',
              },
            },
            {'text': 'Wait', 'to': 'yard'},
            {'text': 'Go to the shed', 'to': 'shed'},
          ],
        },
        'shed': {
          'text': 'Shed',
          'choices': [
            {'text': 'Search the shelves', 'to': 'shed', 'once': true},
            {'text': 'Back', 'to': 'yard'},
          ],
        },
        'inside': {'text': 'Inside', 'ending': 'victory'},
      },
    });

    GameEngine play({List<int> dice = const []}) {
      final s = searching();
      return GameEngine.newGame(
        story: s,
        rules: rulesOf(s),
        random: ScriptedRandom(dice),
        stats: stats(luck: 5),
      ).$1;
    }

    List<String> texts(GameEngine e) => [
      for (final c in e.choices) c.choice.text,
    ];

    test('is shown until taken, then gone', () {
      final e = play();
      expect(texts(e), contains('Search the rubble'));

      e.choose(0);

      expect(texts(e), ['Try the lock', 'Wait', 'Go to the shed']);
      expect(e.state.stat('luck'), 6);
    });

    test('cannot be taken twice', () {
      final e = play()..choose(0);

      expect(() => e.choose(0), throwsStateError);
      expect(e.state.stat('luck'), 6, reason: 'effects did not repeat');
    });

    test('counts once taken even if the dice went badly', () {
      final e = play(dice: [1]);

      e.choose(1); // the lock: fails, back to the yard

      expect(texts(e), isNot(contains('Try the lock')));
    });

    test('other choices stay, and each page keeps its own', () {
      final e = play()..choose(0);

      e.choose(2); // wait
      expect(texts(e), contains('Wait'));
      e.choose(3); // to the shed
      expect(texts(e), ['Search the shelves', 'Back']);
      e.choose(0);
      expect(texts(e), ['Back']);
      e.choose(1);
      expect(texts(e), isNot(contains('Search the rubble')));
    });

    test('is remembered by a saved game', () {
      final e = play()..choose(0);
      final saved = jsonDecode(jsonEncode(e.state.toJson()));
      final s = searching();

      final restored = GameEngine(
        story: s,
        rules: rulesOf(s),
        random: ScriptedRandom([]),
        state: GameState.fromJson(saved),
      );

      expect(texts(restored), isNot(contains('Search the rubble')));
    });
  });
}
