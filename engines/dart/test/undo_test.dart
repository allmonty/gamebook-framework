import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// a -> b -> c -> d (an ending). Each step costs 1 gold; `b` gives a coin and
/// has a once-only choice; `c` rolls a check; `d` ends the game.
Map<String, Object?> storyJson({Object? undo, int schema = 1}) => {
  'schema': schema,
  'id': 'u',
  'lang': 'en',
  'title': 'U',
  'rules': {
    'preset': 'fighting-fantasy',
    'undo': ?undo,
    'stats': {
      'gold': {'roll': '5'},
    },
  },
  'items': {
    'coin': {'name': 'Coin'},
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A',
      'choices': [
        {
          'text': 'On',
          'to': 'b',
          'effects': [
            {'stat': 'gold', 'add': -1},
          ],
        },
      ],
    },
    'b': {
      'text': 'B',
      'effects': [
        {'give': 'coin'},
      ],
      'choices': [
        {'text': 'Once', 'to': 'c', 'once': true},
        {'text': 'Back', 'to': 'a'},
      ],
    },
    'c': {
      'text': 'C',
      'choices': [
        {
          'text': 'Test',
          'check': {
            'roll': '1d6',
            'op': 'gte',
            'vs': 4,
            'pass': 'd',
            'fail': 'c',
          },
        },
      ],
    },
    'd': {'text': 'D', 'ending': 'victory'},
  },
};

GameEngine start({Object? undo = 2, List<int> dice = const []}) {
  final story = Story.fromJson(storyJson(undo: undo));
  return GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: ScriptedRandom(dice),
    stats: const {
      'skill': StatValue(9, 9),
      'stamina': StatValue(12, 12),
      'luck': StatValue(8, 8),
      'gold': StatValue(5),
    },
  ).$1;
}

void main() {
  group('parse', () {
    test('undo is a count, 0 by default', () {
      expect(Rules.resolve(Story.fromJson(storyJson(undo: 3)).rules).undo, 3);
      expect(Rules.resolve(Story.fromJson(storyJson()).rules).undo, 0);
    });

    test('errors name the path', () {
      String error(Map<String, Object?> json) {
        try {
          Rules.resolve(Story.fromJson(json).rules);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(error(storyJson(undo: -1)), 'rules.undo: must not be negative');
      expect(error(storyJson(undo: 'a')), 'rules.undo: expected an integer');
    });
  });

  group('going back', () {
    test('restores everything as it was before the choice', () {
      final engine = start()
        ..choose(0)
        ..choose(0);
      expect(engine.state.node, 'c');
      expect(engine.state.inventory, {'coin'});

      engine.undo();

      expect(engine.state.node, 'b');
      expect(
        engine.state.taken,
        isEmpty,
        reason: 'the once-only choice is back',
      );
      expect(engine.choices.map((c) => c.choice.text), ['Once', 'Back']);

      engine.undo();

      expect(engine.state.node, 'a');
      expect(engine.state.stat('gold'), 5);
      expect(engine.state.inventory, isEmpty);
      expect(engine.state.visits, {'a': 1});
      expect(engine.canUndo, isFalse);
    });

    test('keeps only the last N pages', () {
      final engine = start(undo: 1)
        ..choose(0)
        ..choose(0)
        ..undo();

      expect(engine.state.node, 'b');
      expect(engine.canUndo, isFalse);
      expect(engine.undo, throwsStateError);
    });

    test('is off unless the story asks for it', () {
      final engine = start(undo: null)..choose(0);

      expect(engine.canUndo, isFalse);
      expect(engine.undo, throwsStateError);
    });

    test('dice are not remembered: choosing again rolls again', () {
      final engine = start(dice: [1, 5])
        ..choose(0)
        ..choose(0);
      engine.choose(0); // fails with a 1 and stays on c
      expect(engine.state.node, 'c');

      engine.undo();
      engine.choose(0); // a 5 passes

      expect(engine.state.node, 'd');
    });

    test('the end of the game can be taken back', () {
      final engine = start(dice: [6])
        ..choose(0)
        ..choose(0)
        ..choose(0);
      expect(engine.ending, Ending.victory);

      engine.undo();

      expect(engine.ending, isNull);
      expect(engine.state.node, 'c');
    });

    test('a failed choice leaves no history', () {
      final engine = start();

      expect(() => engine.choose(7), throwsRangeError);
      expect(engine.canUndo, isFalse);
    });

    test('a fight is undone as a whole, not round by round', () {
      final story = Story.fromJson({
        'schema': 1,
        'id': 'f',
        'lang': 'en',
        'title': 'F',
        'rules': {'preset': 'fighting-fantasy', 'undo': 3},
        'start': 'a',
        'nodes': {
          'a': {
            'text': 'A',
            'choices': [
              {'text': 'Fight', 'to': 'ring'},
            ],
          },
          'ring': {
            'text': 'Ring',
            'combat': {
              'enemies': [
                {'name': 'Rat', 'attack': 7, 'health': 9},
              ],
              'win': 'a',
            },
          },
        },
      });
      final engine = GameEngine.newGame(
        story: story,
        rules: Rules.resolve(story.rules),
        random: ScriptedRandom([3, 3, 2, 2, 3, 3, 2, 2]),
        stats: const {
          'skill': StatValue(9, 9),
          'stamina': StatValue(12, 12),
          'luck': StatValue(8, 8),
        },
      ).$1;
      engine
        ..choose(0)
        ..fight()
        ..fight();
      expect(engine.state.combat!.enemyHealth, [5]);

      engine.undo();

      expect(engine.state.node, 'a');
      expect(engine.state.combat, isNull);
      expect(engine.state.stat('stamina'), 12);
    });
  });
}
