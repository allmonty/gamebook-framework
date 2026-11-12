import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// d20-lite with Might floored at [min]; page `a` applies [effects] and
/// offers a gauntlet (-4 Might).
Story floored({
  int? min = -3,
  int schema = 1,
  Map<String, Object?> might = const {},
  List<Map<String, Object?>> effects = const [],
}) => Story.fromJson({
  'schema': schema,
  'id': 'floor',
  'lang': 'en',
  'title': 'Floor',
  'rules': {
    'preset': 'd20-lite',
    'stats': {
      'might': {'min': ?min, ...might},
    },
  },
  'items': {
    'gauntlet': {
      'name': 'Gauntlet',
      'bonus': {'might': -4},
    },
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'Might {might}.',
      'effects': effects,
      'choices': [
        {
          'text': 'Wear it',
          'to': 'a',
          'effects': [
            {'give': 'gauntlet'},
          ],
        },
      ],
    },
  },
});

String failure(Story Function() build) {
  try {
    final story = build();
    Rules.resolve(story.rules);
  } on StoryFormatException catch (e) {
    return '$e';
  }
  fail('expected a StoryFormatException');
}

GameEngine play(Story story, {int might = 2}) => GameEngine.newGame(
  story: story,
  rules: Rules.resolve(story.rules),
  random: ScriptedRandom(const []),
  stats: {
    'might': StatValue(might, null, -3),
    'agility': const StatValue(2),
    'wits': const StatValue(2),
    'hp': const StatValue(12, 12),
  },
).$1;

void main() {
  group('parse', () {
    test('a min may be negative; without one it is 0', () {
      final rules = Rules.resolve(floored().rules);
      expect(rules.stats.firstWhere((s) => s.id == 'might').min, -3);
      expect(rules.stats.firstWhere((s) => s.id == 'wits').min, 0);
    });

    test('the health stat cannot have a min', () {
      expect(
        failure(
          () => Story.fromJson({
            'schema': 1,
            'id': 'hp',
            'lang': 'en',
            'title': 'HP',
            'rules': {
              'preset': 'd20-lite',
              'stats': {
                'hp': {'min': -1},
              },
            },
            'start': 'a',
            'nodes': {
              'a': {'text': 'A', 'ending': 'victory'},
            },
          }),
        ),
        'rules.stats.hp.min: the health stat cannot have a min',
      );
    });

    test('a min must be below the limit', () {
      expect(
        failure(() => floored(min: 5, might: {'limit': 5})),
        'rules.stats.might.min: must be below the limit (5)',
      );
    });
  });

  group('playing', () {
    test('effects stop at the min, not at 0', () {
      final engine = play(
        floored(
          effects: [
            {'stat': 'might', 'add': -10},
          ],
        ),
      );
      expect(engine.state.stat('might'), -3);
      expect(engine.paragraphs.single, 'Might -3.');
    });

    test('a bonus stops at the min, and the stat itself is kept', () {
      final engine = play(floored())..choose(0);
      expect(engine.state.stat('might'), -2);

      final low = play(floored(), might: 0)..choose(0);
      expect(low.state.stat('might'), -3);
      expect(low.state.stats['might']!.value, 0);
    });

    test('a creation roll below the min is raised to it', () {
      final story = floored(might: {'roll': '1d4-6'});
      final stats = Rules.resolve(story.rules)
          .rollStats(ScriptedRandom([1, 1, 1, 1, 1]));
      expect(stats['might']!.value, -3);
    });
  });

  group('saves', () {
    test('keep the min', () {
      final saved = StatValue.fromJson(const StatValue(-2, null, -3).toJson());
      expect((saved.value, saved.min), (-2, -3));
      expect(StatValue.fromJson({'value': 4, 'max': null}).min, 0);
    });

    test('a save whose floor differs from the story does not fit', () {
      final story = floored();
      final state = play(story).state;
      final stale = state.copyWith(
        stats: {...state.stats, 'might': const StatValue(2)},
      );
      expect(stateFits(state, story, Rules.resolve(story.rules)), isTrue);
      expect(stateFits(stale, story, Rules.resolve(story.rules)), isFalse);
    });
  });
}
