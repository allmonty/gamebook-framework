import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/graph.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// Two roads that call a shop (`shop` returns), a road that can meet a wolf
/// through a table (the wolf's win returns), and a page that calls itself
/// (to test the depth limit).
Map<String, Object?> json({int schema = 8, Map<String, Object?>? extra}) => {
  'schema': schema,
  'id': 'ret',
  'lang': 'en',
  'title': 'Ret',
  'rules': {'preset': 'fighting-fantasy', 'undo': 3},
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A',
      'choices': [
        {'text': 'Shop', 'to': 'shop', 'call': true},
        {'text': 'B', 'to': 'b'},
        {
          'text': 'Ford',
          'call': true,
          'table': {
            'roll': '1d6',
            'outcomes': [
              {'upTo': 3, 'to': 'wolf'},
              {'upTo': 6, 'to': 'b'},
            ],
          },
        },
        {'text': 'Deeper', 'to': 'a', 'call': true},
      ],
    },
    'b': {
      'text': 'B',
      'choices': [
        {'text': 'Shop', 'to': 'shop', 'call': true},
        {'text': 'Back', 'return': true},
      ],
    },
    'shop': {
      'text': 'Shop',
      'choices': [
        {'text': 'Goodbye', 'return': true},
      ],
    },
    'wolf': {
      'text': 'Wolf',
      'combat': {
        'enemies': [
          {'name': 'Wolf', 'attack': 1, 'health': 2},
        ],
        'win': {'return': true},
        'flee': {'return': true},
      },
    },
    ...?extra,
  },
};

GameEngine play({List<int> dice = const [], Map<String, Object?>? j}) {
  final story = Story.fromJson(j ?? json());
  return GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: ScriptedRandom(dice),
    stats: const {
      'skill': StatValue(9, 12),
      'stamina': StatValue(12, 24),
      'luck': StatValue(8, 12),
    },
  ).$1;
}

void main() {
  test('a call remembers the page; a return enters it again', () {
    final engine = play()..choose(1); // to b
    engine.choose(0); // call the shop from b
    expect(engine.state.returnTo, ['b']);

    engine.choose(0); // goodbye

    expect(engine.node.id, 'b');
    expect(engine.state.visitsTo('b'), 2);
    expect(engine.state.returnTo, isEmpty);
  });

  test('a return with nothing remembered is locked', () {
    final engine = play()..choose(1); // b, reached without a call
    final back = engine.choices.firstWhere((c) => c.choice.returns);
    expect(back.locked, isTrue);
    expect(() => engine.choose(1), throwsStateError);
  });

  test('a call covers a table outcome, and a fight win can return', () {
    // The ford: 1 is the wolf. Hero 6+6+9 beats 1+1+1: the wolf (2) falls.
    final engine = play(dice: [1, 6, 6, 1, 1])..choose(2);
    expect(engine.node.id, 'wolf');
    expect(engine.state.returnTo, ['a']);

    engine.fight();

    expect(engine.node.id, 'a');
    expect(engine.state.returnTo, isEmpty);
  });

  test('a fight can flee back too', () {
    final engine = play(dice: [1])..choose(2);
    expect(engine.canFlee, isTrue);
    engine.flee();
    expect(engine.node.id, 'a');
  });

  test('calls nest, and a deeper one forgets the oldest page', () {
    final engine = play();
    for (var i = 0; i < GameEngine.maxReturns + 4; i++) {
      engine.choose(3); // a calls a
    }
    expect(engine.state.returnTo, hasLength(GameEngine.maxReturns));
  });

  test('undo brings back what was remembered', () {
    final engine = play()
      ..choose(0) // call the shop
      ..choose(0); // return to a
    expect(engine.state.returnTo, isEmpty);

    engine.undo();

    expect(engine.state.returnTo, ['a']);
  });

  group('saves', () {
    test('keep the pages to return to', () {
      final engine = play()..choose(0);
      final saved = GameState.fromJson(engine.state.toJson());
      expect(saved.returnTo, ['a']);
    });

    test('a page that is gone, or too many, do not fit', () {
      final story = Story.fromJson(json());
      final rules = Rules.resolve(story.rules);
      final state = play().state;
      expect(stateFits(state.copyWith(returnTo: ['a']), story, rules), isTrue);
      expect(
        stateFits(state.copyWith(returnTo: ['gone']), story, rules),
        isFalse,
      );
      expect(
        stateFits(
          state.copyWith(returnTo: List.filled(GameEngine.maxReturns + 1, 'a')),
          story,
          rules,
        ),
        isFalse,
      );
    });
  });

  group('parse', () {
    String failure(Map<String, Object?> extra, {int schema = 8}) {
      try {
        Story.fromJson(json(schema: schema, extra: extra));
      } on StoryFormatException catch (e) {
        return '$e';
      }
      fail('expected a StoryFormatException');
    }

    Map<String, Object?> page(Map<String, Object?> choice) => {
      'x': {
        'text': 'X',
        'choices': [choice],
      },
    };

    test('a choice cannot both call and return', () {
      expect(
        failure(page({'text': 'X', 'return': true, 'call': true})),
        'nodes.x.choices[0].call: a choice cannot both call and return',
      );
    });

    test('return must be true', () {
      expect(
        failure(page({'text': 'X', 'return': false})),
        'nodes.x.choices[0].return: must be true',
      );
    });

    test('a fight target is a node id or { "return": true }', () {
      expect(
        failure({
          'x': {
            'text': 'X',
            'combat': {
              'enemies': [
                {'name': 'R', 'attack': 1, 'health': 1},
              ],
              'win': {'return': false},
            },
          },
        }),
        'nodes.x.combat.win.return: expected a node id or { "return": true }',
      );
    });

    test('call and return need schema 8', () {
      expect(
        failure(const {}, schema: 7),
        'nodes.a.choices[0].call: needs "schema": 8',
      );
    });
  });

  test('the validator warns when a return can be reached with nothing to '
      'return to', () {
    final found = [
      for (final i in validateStory(Story.fromJson(json())))
        if (i.code == 'return-without-call') i.where,
    ];
    // b is reached from a without a call; the shop and the wolf are not.
    expect(found, ['nodes.b']);
  });

  test('the graph draws a return back to every page that calls', () {
    final edges = storyEdges(Story.fromJson(json()));
    expect(
      [
        for (final e in edges)
          if (e.from == 'shop') (e.to, e.kind),
      ],
      [('a', EdgeKind.back), ('b', EdgeKind.back)],
    );
  });
}
