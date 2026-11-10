import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Map<String, Object?> storyJson({
  Map<String, Object?>? journal,
  int schema = 5,
  String lang = 'en',
  List<Object?> effects = const [
    {'journal': 'note'},
  ],
}) => {
  'schema': schema,
  'id': 'j',
  'lang': lang,
  'title': 'J',
  'rules': {'preset': 'fighting-fantasy'},
  'journal':
      journal ??
      {
        'note': {'title': 'A note', 'text': 'Left under the door.'},
        'map': {'title': 'A map', 'text': 'Torn at the edge.'},
      },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A',
      'effects': effects,
      'choices': [
        {
          'text': 'On',
          'to': 'b',
          'effects': [
            {'journal': 'map'},
            {'journal': 'note'},
          ],
        },
      ],
    },
    'b': {'text': 'B', 'ending': 'victory'},
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

GameEngine start([Story? story]) {
  final s = story ?? Story.fromJson(storyJson());
  return GameEngine.newGame(
    story: s,
    rules: Rules.resolve(s.rules),
    random: ScriptedRandom(const []),
    stats: const {
      'skill': StatValue(9, 9),
      'stamina': StatValue(12, 12),
      'luck': StatValue(8, 8),
    },
  ).$1;
}

void main() {
  group('parse', () {
    test('entries have a title and a text', () {
      final story = Story.fromJson(storyJson());

      expect(story.journal.keys, ['note', 'map']);
      expect(story.journal['note']!.title, 'A note');
      expect(story.journal['note']!.text, 'Left under the door.');
    });

    test('errors name the path', () {
      expect(
        error(
          storyJson(
            journal: {
              'note': {'title': 'A note'},
            },
          ),
        ),
        'journal.note.text: missing',
      );
      expect(
        error(
          storyJson(
            journal: {
              'Bad Id': {'title': 'x', 'text': 'y'},
            },
          ),
        ),
        startsWith('journal: invalid id'),
      );
    });

    test('needs schema 5, in the journal or in an effect', () {
      expect(error(storyJson(schema: 4)), 'journal: needs "schema": 5');
      expect(
        error({...storyJson(schema: 4), 'journal': null}..remove('journal')),
        'nodes.a.effects[0]: needs "schema": 5',
      );
    });
  });

  group('playing', () {
    test('an entry is unlocked once, in order', () {
      final engine = start();
      expect(engine.state.journal, ['note']);

      final events = engine.choose(0);

      expect(engine.state.journal, ['note', 'map']);
      expect(events.whereType<JournalUnlocked>().map((e) => e.entry), [
        'map',
      ], reason: 'the note was already unlocked');
    });

    test('the page that unlocks an entry tells the player', () {
      final events = GameEngine.newGame(
        story: Story.fromJson(storyJson()),
        rules: Rules.resolve(Story.fromJson(storyJson()).rules),
        random: ScriptedRandom(const []),
        stats: const {
          'skill': StatValue(9, 9),
          'stamina': StatValue(12, 12),
          'luck': StatValue(8, 8),
        },
      ).$2;

      expect(events.whereType<JournalUnlocked>().single.entry, 'note');
    });

    test('is saved, and a save from before journals has none', () {
      final state = start().state;

      expect(GameState.fromJson(state.toJson()).journal, ['note']);
      expect(
        GameState.fromJson(state.toJson()..remove('journal')).journal,
        isEmpty,
      );
    });

    test('applyEffect does nothing the second time', () {
      const state = GameState(node: 'a', journal: ['note']);

      expect(applyEffect(const UnlockEntry('note'), state), same(state));
    });
  });

  group('validation', () {
    List<String> issues(Map<String, Object?> json) => [
      for (final i in validateStory(Story.fromJson(json))) i.toString(),
    ];

    test('an unknown entry is an error', () {
      expect(
        issues(
          storyJson(
            effects: [
              {'journal': 'ghost'},
            ],
          ),
        ),
        contains('error: nodes.a.effects[0]: unknown journal entry "ghost"'),
      );
    });

    test('an entry that is never unlocked is a warning', () {
      expect(
        issues(
          storyJson(
            journal: {
              'note': {'title': 'A note', 'text': 'x'},
              'map': {'title': 'A map', 'text': 'y'},
              'lost': {'title': 'Lost', 'text': 'z'},
            },
          ),
        ),
        contains('warning: journal.lost: is never unlocked'),
      );
    });

    test('translations must have the same entries', () {
      final en = Story.fromJson(storyJson());
      final pt = Story.fromJson(
        storyJson(
          lang: 'pt',
          journal: {
            'note': {'title': 'Um bilhete', 'text': 'x'},
          },
        ),
      );

      expect(
        compareTranslations(en, pt).map((i) => i.message),
        contains('journal entry "map" exists in en but not in pt'),
      );
    });
  });
}
