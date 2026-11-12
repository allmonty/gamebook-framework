import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// Fighting Fantasy with every-page [rules] and a `tick` stat. Pages: `a`
/// (start, applies [start]) leads to `b`, then `c`, then back to `b`; `ring`
/// is a fight.
Map<String, Object?> json(
  List<Map<String, Object?>> rules, {
  List<Map<String, Object?>> start = const [],
  List<Map<String, Object?>> onB = const [],
  int schema = 8,
  bool hidden = true,
}) => {
  'schema': schema,
  'id': 'ep',
  'lang': 'en',
  'title': 'EP',
  'rules': {
    'preset': 'fighting-fantasy',
    'stats': {
      'tick': {'label': 'Tick', 'roll': '0', 'hidden': hidden},
    },
    'everyPage': rules,
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A',
      'effects': start,
      'choices': [
        {'text': 'B', 'to': 'b'},
        {'text': 'Ring', 'to': 'ring'},
      ],
    },
    'b': {
      'text': 'B',
      'effects': onB,
      'choices': [
        {'text': 'C', 'to': 'c'},
      ],
    },
    'c': {
      'text': 'C',
      'choices': [
        {'text': 'B', 'to': 'b'},
      ],
    },
    'ring': {
      'text': 'A rat.',
      'combat': {
        'enemies': [
          {'name': 'Rat', 'attack': 1, 'health': 2},
        ],
        'win': 'c',
      },
    },
  },
};

GameEngine play(Map<String, Object?> j, {int stamina = 10}) {
  final story = Story.fromJson(j);
  return GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: ScriptedRandom(const []),
    stats: {
      'skill': const StatValue(9, 12),
      'stamina': StatValue(stamina, 24),
      'luck': const StatValue(8, 12),
      'tick': const StatValue(0),
    },
  ).$1;
}

Map<String, Object?> add(String stat, int amount) => {
  'stat': stat,
  'add': amount,
};

void main() {
  test('a rule runs on every page entered, the start page included', () {
    final engine = play(
      json([
        {
          'effects': [add('tick', 1)],
        },
      ]),
    );
    expect(engine.state.stat('tick'), 1);
    engine
      ..choose(0)
      ..choose(0)
      ..choose(0); // back to b
    expect(engine.state.stat('tick'), 4);
  });

  test('a calm rule skips pages with a fight', () {
    final engine = play(
      json([
        {
          'calm': true,
          'effects': [add('stamina', 1)],
        },
      ]),
    );
    expect(engine.state.stat('stamina'), 11);

    engine.choose(1); // the ring

    expect(engine.state.stat('stamina'), 11);
  });

  test('a rule with a condition runs only while it holds', () {
    final engine = play(
      json(
        [
          {
            'if': {'flag': 'fever'},
            'effects': [add('stamina', -1)],
          },
        ],
        onB: [
          {'set': 'fever'},
        ],
      ),
    );
    engine.choose(0); // b catches the fever
    expect(engine.state.stat('stamina'), 10);
    engine.choose(0); // c: it drains
    expect(engine.state.stat('stamina'), 9);
  });

  test('the rules come before the page: a counter of 3 lasts the next three '
      'pages', () {
    final engine = play(
      json(
        [
          {
            'if': {'stat': 'tick', 'gte': 1},
            'effects': [add('tick', -1)],
          },
        ],
        start: [
          {'stat': 'tick', 'set': 3},
        ],
      ),
    );
    final seen = [engine.state.stat('tick')];
    for (var i = 0; i < 3; i++) {
      engine.choose(0);
      seen.add(engine.state.stat('tick'));
    }
    expect(seen, [3, 2, 1, 0]);
  });

  test('rules apply in list order, each seeing the one before', () {
    final engine = play(
      json([
        {
          'effects': [add('tick', 1)],
        },
        {
          'if': {'stat': 'tick', 'eq': 1},
          'effects': [add('stamina', 5)],
        },
      ]),
    );
    expect(engine.state.stat('stamina'), 15);
  });

  test('a rule that kills ends the game, and the page applies nothing', () {
    final engine = play(
      json(
        [
          {
            'effects': [add('stamina', -1)],
          },
        ],
        onB: [
          {'set': 'reached'},
        ],
      ),
      stamina: 2,
    );
    engine.choose(0);
    expect(engine.ending, Ending.death);
    expect(engine.state.flags, isNot(contains('reached')));
  });

  group('parse', () {
    test('a hidden stat is still a stat', () {
      final rules = Rules.resolve(Story.fromJson(json(const [])).rules);
      expect(rules.stats.firstWhere((s) => s.id == 'tick').hidden, isTrue);
      expect(rules.stats.firstWhere((s) => s.id == 'skill').hidden, isFalse);
    });

    for (final (path, j) in [
      (
        'rules.everyPage',
        json([
          {
            'effects': [add('tick', 1)],
          },
        ], schema: 7),
      ),
      ('rules.stats.tick.hidden', json(const [], schema: 7)),
    ]) {
      test('$path needs schema 8', () {
        expect(
          () => Story.fromJson(j),
          throwsA(
            isA<StoryFormatException>().having(
              (e) => '$e',
              'message',
              '$path: needs "schema": 8',
            ),
          ),
        );
      });
    }
  });
}
