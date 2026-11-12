import 'dart:io';

import 'package:gamebook_site/src/content/site_builder.dart';
import 'package:test/test.dart';

void main() {
  late Directory output;
  setUp(() => output = Directory.systemTemp.createTempSync('site_build'));
  tearDown(() => output.deleteSync(recursive: true));

  test('builds every page in every language from the real sources', () {
    SiteBuilder(source: Directory.current, output: output).build();
    for (final lang in SiteBuilder.languages) {
      for (final name in ['index.html', 'play.html']) {
        final page = File('${output.path}/$lang/$name').readAsStringSync();
        expect(page, contains('<html lang="$lang">'), reason: name);
        expect(page, isNot(contains('{{')), reason: name);
        expect(page, contains('class="gb-embed"'), reason: name);
      }
    }
    expect(File('${output.path}/index.html').existsSync(), isTrue);
    expect(File('${output.path}/css/site.css').existsSync(), isTrue);
  });

  test('every language has the same string keys', () {
    final builder = SiteBuilder(source: Directory.current, output: output);
    final keys = {
      for (final lang in SiteBuilder.languages)
        lang: builder.loadStrings(lang).keys.toSet(),
    };
    expect(keys['pt'], keys['en']);
  });
}
