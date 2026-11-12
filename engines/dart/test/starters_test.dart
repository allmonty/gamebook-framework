// Every starter game in ../../starters is a game folder anyone can copy: it
// parses, has no errors and no warnings, its translations match English,
// random play never gets stuck or loops, and it packs.
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/simulate.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import '../bin/pack_game.dart';

final _storyFile = RegExp(r'^story\.([a-z]{2})\.json$');

void main() {
  final folders = [
    for (final d in Directory('../../starters').listSync())
      if (d is Directory) d.path,
  ]..sort();

  test('the starters are there', () {
    expect(folders.map((f) => f.split('/').last), [
      'blank',
      'custom-rules',
      'fighting-fantasy',
      'hub-and-shop',
      'percentile-mystery',
      'results-table',
    ]);
  });

  for (final folder in folders) {
    group(folder.split('/').last, () {
      final stories = {
        for (final f in Directory(folder).listSync())
          if (_storyFile.firstMatch(f.uri.pathSegments.last) case final m?)
            m[1]!: Story.parse(File(f.path).readAsStringSync()),
      };

      test('has an English story', () {
        expect(stories, contains('en'));
      });

      for (final MapEntry(key: lang, value: story) in stories.entries) {
        test('$lang has no errors and no warnings', () {
          expect(story.lang, lang);
          Rules.resolve(story.rules);
          expect(validateStory(story).map((i) => '$i'), isEmpty);
        });

        if (lang != 'en') {
          test('$lang matches English', () {
            expect(
              compareTranslations(stories['en']!, story).map((i) => '$i'),
              isEmpty,
            );
          });
        }
      }

      test('random play never gets stuck or loops', () {
        final report = simulate(stories['en']!, games: 300, random: Random(1));
        expect(report.rate(Outcome.stuck), 0);
        expect(report.rate(Outcome.endless), 0);
        expect(report.unreachedEndings, isEmpty);
      });

      test('packs', () {
        final packed = packFolder(folder);
        expect(packed.id, stories['en']!.id);
        expect(packed.skipped, isEmpty);
      });
    });
  }
}
