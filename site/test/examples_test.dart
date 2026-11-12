// Every example story must be valid with no warnings, exist in English and
// Portuguese, and the two must match structurally.
import 'dart:io';

import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

final _file = RegExp(r'^(.+)\.(en|pt)\.json$');

/// Example paths without language (`examples/home/rusty-door`), sorted.
List<String> examplePaths() => {
  for (final f in Directory('examples').listSync(recursive: true))
    if (f is File && _file.hasMatch(f.uri.pathSegments.last))
      f.path.replaceFirst(RegExp(r'\.(en|pt)\.json$'), ''),
}.toList()..sort();

Story _load(String path, String lang) =>
    Story.parse(File('$path.$lang.json').readAsStringSync());

void main() {
  final paths = examplePaths();

  test('there are examples', () => expect(paths, isNotEmpty));

  for (final path in paths) {
    group(path, () {
      test('exists in English and Portuguese', () {
        for (final lang in ['en', 'pt']) {
          expect(File('$path.$lang.json').existsSync(), isTrue, reason: lang);
        }
      });

      for (final lang in ['en', 'pt']) {
        test('$lang is valid with no warnings', () {
          final story = _load(path, lang);
          expect(story.lang, lang);
          Rules.resolve(story.rules);
          expect(validateStory(story).map((i) => '$i'), isEmpty);
        });
      }

      test('the translations match', () {
        final en = _load(path, 'en');
        final pt = _load(path, 'pt');
        expect(pt.id, en.id);
        expect(compareTranslations(en, pt).map((i) => '$i'), isEmpty);
      });
    });
  }
}
