import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Map<String, Object?> storyJson({Object? luck, int schema = 5}) => {
  'schema': schema,
  'id': 'l',
  'lang': 'en',
  'title': 'L',
  'rules': {
    'preset': 'fighting-fantasy',
    'combat': {'luck': ?luck},
  },
  'start': 'ring',
  'nodes': {
    'ring': {
      'text': 'Ring',
      'combat': {
        'enemies': [
          {'name': 'Goblin', 'attack': 7, 'health': 4},
        ],
        'win': 'won',
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

GameEngine start(List<int> dice) {
  final story = Story.fromJson(storyJson(luck: {'stat': 'luck'}));
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
  group('parse', () {
    test('defaults are those of Fighting Fantasy', () {
      final luck = Rules.resolve(
        Story.fromJson(storyJson(luck: {'stat': 'luck'})).rules,
      ).combat!.luck!;

      expect(luck.stat, 'luck');
      expect(luck.roll.toString(), '2d6');
      expect((luck.lucky.dealt, luck.lucky.taken), (2, -1));
      expect((luck.unlucky.dealt, luck.unlucky.taken), (-1, 1));
    });

    test('everything can be overridden, a part at a time', () {
      final luck = Rules.resolve(
        Story.fromJson(
          storyJson(
            luck: {
              'stat': 'luck',
              'roll': '1d20',
              'lucky': {'dealt': 3},
              'unlucky': {'taken': 2},
            },
          ),
        ).rules,
      ).combat!.luck!;

      expect(luck.roll.toString(), '1d20');
      expect((luck.lucky.dealt, luck.lucky.taken), (3, -1));
      expect((luck.unlucky.dealt, luck.unlucky.taken), (-1, 2));
    });

    test('errors name the path', () {
      expect(
        error(storyJson(luck: {'stat': 'fate'})),
        'rules.combat.luck.stat: unknown stat "fate"',
      );
      expect(
        error(storyJson(luck: {'stat': 'luck', 'roll': 'abc'})),
        startsWith('rules.combat.luck.roll:'),
      );
      expect(
        error(
          storyJson(
            luck: {
              'stat': 'luck',
              'lucky': {'dealt': 'x'},
            },
          ),
        ),
        'rules.combat.luck.lucky.dealt: expected an integer',
      );
      expect(
        error(storyJson(luck: {'stat': 'luck', 'extra': 1})),
        startsWith('rules.combat.luck'),
      );
    });

    test('needs schema 5', () {
      expect(
        error(storyJson(luck: {'stat': 'luck'}, schema: 4)),
        'rules.combat.luck: needs "schema": 5',
      );
    });
  });

  group('state', () {
    test('the open test is saved with the fight', () {
      const state = GameState(
        node: 'ring',
        combat: CombatState(0, [2], LuckChance(enemy: 0, dealt: 2, taken: 1)),
      );

      final back = GameState.fromJson(state.toJson()).combat!;

      expect(back.luck!.dealt, 2);
      expect(back.luck!.taken, 1);
    });

    test('a fight saved before luck has no open test', () {
      final json = const GameState(
        node: 'ring',
        combat: CombatState(0, [2]),
      ).toJson();

      expect(GameState.fromJson(json).combat!.luck, isNull);
    });
  });

  group('engine', () {
    test('a round opens the test, testing it spends luck and can win', () {
      final engine = start([3, 3, 2, 2, 2, 3]);
      expect(engine.canTestLuck, isFalse);

      engine.fight();
      expect(engine.canTestLuck, isTrue);

      final events = engine.testLuck();

      expect(events.whereType<CombatLuck>().single.result.lucky, isTrue);
      expect(engine.state.stat('luck'), 7);
      expect(engine.state.node, 'won');
    });

    test('a second test needs another round', () {
      final engine = start([3, 3, 2, 2, 6, 6, 3, 3, 2, 2]);
      engine
        ..fight()
        ..testLuck();

      expect(engine.canTestLuck, isFalse);
      expect(engine.testLuck, throwsStateError);
    });

    test('a fight whose rules have no luck refuses a test', () {
      final story = Story.fromJson(storyJson());
      final engine = GameEngine.newGame(
        story: story,
        rules: Rules.resolve(story.rules),
        random: ScriptedRandom(const [3, 3, 2, 2]),
        stats: const {
          'skill': StatValue(9, 12),
          'stamina': StatValue(12, 24),
          'luck': StatValue(8, 12),
        },
      ).$1..fight();

      expect(engine.canTestLuck, isFalse);
      expect(engine.testLuck, throwsStateError);
    });

    test('the validator finds no problem in a luck story', () {
      final issues = validateStory(
        Story.fromJson(storyJson(luck: {'stat': 'luck'})),
      );

      expect(issues.where((i) => i.severity == Severity.error), isEmpty);
    });
  });
}
