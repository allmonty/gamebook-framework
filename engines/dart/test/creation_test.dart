import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/quantity.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Map<String, Object?> creation([Object? picks]) => {
  'name': true,
  'picks': picks ?? _picks,
};

const _picks = [
  {
    'id': 'kit',
    'title': 'Kit',
    'count': 1,
    'options': [
      {
        'id': 'sword',
        'label': 'Sword',
        'effects': [
          {'give': 'sword'},
          {'stat': 'skill', 'add': 1},
        ],
      },
      {
        'id': 'bread',
        'label': 'Bread',
        'effects': [
          {'give': 'bread'},
        ],
      },
    ],
  },
];

Map<String, Object?> storyJson({
  Map<String, Object?>? rules,
  String text = 'Hello {name}.',
  int schema = 5,
}) => {
  'schema': schema,
  'id': 'c',
  'lang': 'en',
  'title': 'C',
  'rules': {
    'preset': 'fighting-fantasy',
    'creation': ?rules,
    'inventory': {'capacity': 1, 'pickup': 'choose'},
  },
  'items': {
    'sword': {'name': 'Sword'},
    'bread': {'name': 'Bread'},
  },
  'start': 'a',
  'nodes': {
    'a': {'text': text, 'ending': 'victory'},
  },
};

String error(Map<String, Object?> json) {
  try {
    Story.fromJson(json);
  } on StoryFormatException catch (e) {
    return e.toString();
  }
  fail('expected a StoryFormatException');
}

void main() {
  group('parse', () {
    test('reads the name flag and the groups', () {
      final c = Story.fromJson(storyJson(rules: creation())).rules.creation!;

      expect(c.name, isTrue);
      expect(c.picks.single.id, 'kit');
      expect(c.picks.single.options.map((o) => o.id), ['sword', 'bread']);
      expect(c.picks.single.options.first.effects, hasLength(2));
    });

    test('errors name the path', () {
      String bad(Map<String, Object?> group) => error(
        storyJson(
          rules: creation([
            {..._picks.single, ...group},
          ]),
        ),
      );

      expect(
        bad({'count': 3}),
        'rules.creation.picks[0].count: must be between 1 and the number '
        'of options (2)',
      );
      expect(
        bad({'count': 0}),
        startsWith('rules.creation.picks[0].count: must be between 1'),
      );
      expect(
        bad({'options': <Object?>[]}),
        'rules.creation.picks[0].options: needs at least one option',
      );
      expect(
        bad({
          'options': [
            {'id': 'a', 'label': 'A'},
            {'id': 'a', 'label': 'B'},
          ],
        }),
        'rules.creation.picks[0].options[1].id: duplicate option id "a"',
      );
      expect(
        error(storyJson(rules: creation([_picks.single, _picks.single]))),
        'rules.creation.picks[1].id: duplicate group id "kit"',
      );
    });

    test('needs schema 5', () {
      expect(
        error(storyJson(rules: creation(), schema: 4)),
        'rules.creation: needs "schema": 5',
      );
    });
  });

  group('starting a game', () {
    GameEngine start(
      Story story, {
      String? name,
      List<Effect> effects = const [],
    }) => GameEngine.newGame(
      story: story,
      rules: Rules.resolve(story.rules),
      random: ScriptedRandom(const []),
      stats: const {'skill': StatValue(8, 9), 'stamina': StatValue(20, 20)},
      name: name,
      creationEffects: effects,
    ).$1;

    test(
      'picked gives go straight to the pack, even when items are offered',
      () {
        final story = Story.fromJson(storyJson(rules: creation()));
        final effects =
            story.rules.creation!.picks.single.options.first.effects;

        final engine = start(story, name: 'Wren', effects: effects);

        expect(engine.state.inventory, {'sword'});
        expect(engine.state.offers, isEmpty);
        expect(engine.state.stat('skill'), 9);
      },
    );

    test('a pick that takes health to 0 stops the picks after it', () {
      final story = Story.fromJson(storyJson(rules: creation()));

      final engine = start(
        story,
        effects: const [
          StatChange('stamina', Quantity.value(-20)),
          StatChange('stamina', Quantity.value(5)),
        ],
      );

      expect(engine.state.stat('stamina'), 0);
      expect(engine.ending, Ending.death);
    });

    test('a pack too small drops the newest pick', () {
      final story = Story.fromJson(storyJson(rules: creation()));

      final engine = start(
        story,
        effects: const [GiveItem('sword'), GiveItem('bread')],
      );

      expect(engine.state.inventory, {'sword'});
    });

    test('the name is in the state, saved and shown in the text', () {
      final story = Story.fromJson(storyJson(rules: creation()));
      final engine = start(story, name: 'Wren');

      expect(engine.state.name, 'Wren');
      expect(GameState.fromJson(engine.state.toJson()).name, 'Wren');
      expect(engine.paragraphs, ['Hello Wren.']);
    });

    test('a save from before names has none', () {
      final json = start(
        Story.fromJson(storyJson(rules: creation())),
      ).state.toJson()..remove('name');

      expect(GameState.fromJson(json).name, isNull);
    });
  });

  group('validation', () {
    List<Issue> check(Map<String, Object?> json) =>
        validateStory(Story.fromJson(json));

    test('{name} is fine when the story asks for a name', () {
      expect(
        check(storyJson(rules: creation()))
            .where((i) => i.severity.name == 'error'),
        isEmpty,
      );
    });

    test('{name} without a name in creation is an unknown stat', () {
      final issues = check(storyJson(rules: {'picks': _picks}));

      expect(
        issues.map((i) => i.toString()),
        contains('error: nodes.a.text: unknown stat "name"'),
      );
    });

    test('option effects are checked like any other', () {
      final issues = check(
        storyJson(
          rules: creation([
            {
              ..._picks.single,
              'options': [
                {
                  'id': 'x',
                  'label': 'X',
                  'effects': [
                    {'give': 'nothing'},
                  ],
                },
              ],
              'count': 1,
            },
          ]),
        ),
      );

      expect(
        issues.map((i) => i.toString()),
        contains(
          'error: rules.creation.picks[0].options[0].effects[0]: '
          'unknown item "nothing"',
        ),
      );
    });
  });
}
