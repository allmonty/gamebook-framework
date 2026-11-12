import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// a (music theme) -> b (same music, a sound) -> c (stop) -> d (ending).
Map<String, Object?> storyJson({int schema = 1}) => {
  'schema': schema,
  'id': 'au',
  'lang': 'en',
  'title': 'Au',
  'rules': {'preset': 'fighting-fantasy', 'undo': 3},
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A',
      'music': 'audio/theme.wav',
      'choices': [
        {'text': 'On', 'to': 'b'},
      ],
    },
    'b': {
      'text': 'B',
      'music': 'audio/theme.wav',
      'sound': 'audio/door.wav',
      'choices': [
        {'text': 'On', 'to': 'c'},
      ],
    },
    'c': {
      'text': 'C',
      'music': 'stop',
      'choices': [
        {'text': 'On', 'to': 'd'},
      ],
    },
    'd': {'text': 'D', 'ending': 'victory'},
  },
};

GameEngine start() {
  final story = Story.fromJson(storyJson());
  return GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: ScriptedRandom(const []),
    stats: const {
      'skill': StatValue(9, 9),
      'stamina': StatValue(12, 12),
      'luck': StatValue(8, 8),
    },
  ).$1;
}

void main() {
  test('music and sound are read', () {
    final story = Story.fromJson(storyJson());

    expect(story.nodes['b']!.music, 'audio/theme.wav');
    expect(story.nodes['b']!.sound, 'audio/door.wav');
    expect(story.nodes['d']!.music, isNull);
  });

  group('playing', () {
    test('a page starts its music, which goes on across pages', () {
      final engine = start();
      expect(engine.state.music, 'audio/theme.wav');

      final events = engine.choose(0);

      expect(events.whereType<MusicChanged>(), isEmpty, reason: 'same music');
      expect(engine.state.music, 'audio/theme.wav');
    });

    test('a sound plays each time its page is entered', () {
      final engine = start();

      final events = engine.choose(0);

      expect(events.whereType<SoundPlayed>().single.file, 'audio/door.wav');
    });

    test('"stop" stops the music', () {
      final engine = start()..choose(0);

      final events = engine.choose(0);

      expect(engine.state.music, isNull);
      expect(events.whereType<MusicChanged>().single.file, isNull);
    });

    test('the first page tells what plays', () {
      final story = Story.fromJson(storyJson());
      final events = GameEngine.newGame(
        story: story,
        rules: Rules.resolve(story.rules),
        random: ScriptedRandom(const []),
        stats: const {
          'skill': StatValue(9, 9),
          'stamina': StatValue(12, 12),
          'luck': StatValue(8, 8),
        },
      ).$2;

      expect(events.whereType<MusicChanged>().single.file, 'audio/theme.wav');
    });

    test('the music is saved, and going back restores it', () {
      final engine = start()
        ..choose(0)
        ..choose(0);
      expect(GameState.fromJson(engine.state.toJson()).music, isNull);
      engine.undo();

      expect(engine.state.music, 'audio/theme.wav');
      expect(
        GameState.fromJson(engine.state.toJson()).music,
        'audio/theme.wav',
      );
    });

    test('a save from before audio has no music', () {
      final json = start().state.toJson()..remove('music');

      expect(GameState.fromJson(json).music, isNull);
    });
  });

  group('validation', () {
    List<String> issues(bool Function(String) exists) => [
      for (final i in validateStory(
        Story.fromJson(storyJson()),
        assetExists: exists,
      ))
        i.toString(),
    ];

    test('a missing file is an error, and "stop" needs none', () {
      final found = issues((path) => path == 'audio/theme.wav');

      expect(found, [
        'error: nodes.b.sound: sound file not found: audio/door.wav',
      ]);
    });

    test('all files present is clean', () {
      expect(issues((_) => true), isEmpty);
    });
  });
}
