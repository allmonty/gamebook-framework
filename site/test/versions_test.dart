// The versions page must keep up with the engine: a section for every
// schema version it supports, newest first, in both languages, and links
// that lead to built pages. So a new version cannot ship without saying, in
// English and Portuguese, what it lets an author write.
import 'dart:io';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_site/src/content/site_builder.dart';
import 'package:test/test.dart';

final _heading = RegExp(r'^## Vers(?:ion|ão) (\d+)$', multiLine: true);
final _href = RegExp(r'href="([^"#]+)[^"]*"');

/// The versions the page for [lang] has a section for, in page order.
List<int> sections(String lang) => [
  for (final m in _heading.allMatches(
    File('pages/$lang/versions.md').readAsStringSync(),
  ))
    int.parse(m[1]!),
];

void main() {
  final newestFirst = supportedSchemas.toList()..sort((a, b) => b - a);

  for (final lang in SiteBuilder.languages) {
    test('$lang has a section for every supported version, newest first', () {
      expect(sections(lang), newestFirst);
    });
  }

  test('every link on the page leads to a built page', () {
    final output = Directory.systemTemp.createTempSync('versions');
    addTearDown(() => output.deleteSync(recursive: true));
    SiteBuilder(source: Directory.current, output: output).build();
    for (final lang in SiteBuilder.languages) {
      final page = File('${output.path}/$lang/versions.html');
      for (final m in _href.allMatches(page.readAsStringSync())) {
        final target = m[1]!;
        if (target.contains('://')) continue;
        final file = File.fromUri(page.uri.resolve(target));
        expect(file.existsSync(), isTrue, reason: '$lang: $target');
      }
    }
  });
}
