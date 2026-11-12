import 'dart:io';

import 'package:gamebook_engine/story.dart';
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
        expect(
          page,
          contains('href="https://buymeacoffee.com/allmonty"'),
          reason: name,
        );
      }
    }
    expect(File('${output.path}/index.html').existsSync(), isTrue);
    expect(File('${output.path}/css/site.css').existsSync(), isTrue);
  });

  test('publishes the format files, and every site link in llms.txt '
      'leads to a built file', () {
    SiteBuilder(source: Directory.current, output: output).build();
    for (final path in [
      'llms.txt',
      'llm-kit.md',
      'schema/story.schema.json',
      'presets/fighting-fantasy.json',
      'presets/d20-lite.json',
    ]) {
      expect(File('${output.path}/$path').existsSync(), isTrue, reason: path);
    }
    const site = 'https://allmonty.github.io/gamebook-framework/';
    final links = RegExp(
      r'\]\((https://allmonty\.github\.io/gamebook-framework/[^)\s]+)\)',
    ).allMatches(File('../llms.txt').readAsStringSync());
    expect(links, isNotEmpty);
    for (final m in links) {
      final path = m[1]!.substring(site.length).split('#').first;
      expect(File('${output.path}/$path').existsSync(), isTrue, reason: path);
    }
  });

  test("copies the examples' media, and only their media", () {
    SiteBuilder(source: Directory.current, output: output).build();
    final folder = '${output.path}/examples/02-pages-and-choices';
    expect(File('$folder/images/hall.png').existsSync(), isTrue);
    expect(File('$folder/images/draw_hall.dart').existsSync(), isFalse);
    expect(File('$folder/two-doors.en.json').existsSync(), isFalse);
  });

  test('every language has the same chapters, each with a page', () {
    final builder = SiteBuilder(source: Directory.current, output: output)
      ..build();
    final slugs = {
      for (final lang in SiteBuilder.languages)
        lang: builder.loadChapters(lang).map((c) => c.slug).toList(),
    };
    expect(slugs['en'], isNotEmpty);
    expect(slugs['pt'], slugs['en']);
    for (final slug in slugs['en']!) {
      final page = File('${output.path}/en/tutorial/$slug.html');
      // Unfilled placeholders already fail the build; a chapter may teach a
      // literal `{{`, so check the page was assembled instead.
      expect(page.readAsStringSync(), contains('<article class="prose">'));
    }
  });

  test('a page names its address, its other language and where it is', () {
    SiteBuilder(source: Directory.current, output: output).build();
    String page(String path) => File('${output.path}/$path').readAsStringSync();
    const site = SiteBuilder.url;

    final chapter = page('pt/tutorial/05-dice.html');
    expect(
      chapter,
      contains('<link rel="canonical" href="${site}pt/tutorial/05-dice.html">'),
    );
    expect(
      chapter,
      contains(
        '<link rel="alternate" hreflang="en" '
        'href="${site}en/tutorial/05-dice.html">',
      ),
    );
    expect(chapter, contains('<meta property="og:title" content="Dados '));
    expect(chapter, contains('lang="en" aria-label="English (EN)"'));
    // Inside the tutorial, not on the playground.
    expect(chapter, contains('tutorial/index.html" aria-current="true">'));
    expect(chapter, contains('play.html">'));

    expect(
      page('en/tutorial/index.html'),
      contains('tutorial/index.html" aria-current="page">'),
    );
    expect(page('en/play.html'), contains('play.html" aria-current="page">'));
    expect(
      page('en/index.html'),
      isNot(contains('<a href="../en/play.html" aria')),
    );
  });

  test('the starters page plays every starter, in both languages', () {
    SiteBuilder(source: Directory.current, output: output).build();
    final folders = [
      for (final d in Directory(
        '../starters',
      ).listSync().whereType<Directory>())
        d.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    ];
    expect(folders.length, greaterThanOrEqualTo(8));
    for (final lang in SiteBuilder.languages) {
      final page = File('${output.path}/$lang/starters.html')
          .readAsStringSync();
      for (final folder in folders) {
        // A new starter cannot be added without being shown.
        expect(
          page,
          contains('data-example="../starters/$folder/story"'),
          reason: '$lang $folder',
        );
        expect(page, contains('tree/main/starters/$folder"'), reason: folder);
      }
      // The embedded story is the one in the page's language.
      expect(page, contains('"lang":"$lang"'));
      expect(page, isNot(contains('"lang":"${lang == 'en' ? 'pt' : 'en'}"')));
      expect(page, contains('starters.html" aria-current="page">'));
    }
  });

  test('a string placed in an HTML attribute cannot break out of it', () {
    final inAttribute = RegExp(r'="[^"]*\{\{([\w.-]+)\}\}');
    final keys = {
      for (final file in Directory('templates').listSync().whereType<File>())
        for (final m in inAttribute.allMatches(file.readAsStringSync())) m[1]!,
    };
    expect(keys, contains('page.description'));
    final builder = SiteBuilder(source: Directory.current, output: output);
    for (final lang in SiteBuilder.languages) {
      final strings = builder.loadStrings(lang);
      for (final key in keys) {
        expect(
          strings[key] ?? '',
          isNot(matches(RegExp('["<&]'))),
          reason: '$lang $key',
        );
      }
    }
  });

  test('every language has the same string keys', () {
    final builder = SiteBuilder(source: Directory.current, output: output);
    final keys = {
      for (final lang in SiteBuilder.languages)
        lang: builder.loadStrings(lang).keys.toSet(),
    };
    expect(keys['pt'], keys['en']);
    for (final ending in Ending.values) {
      expect(keys['en'], contains('player.ending.${ending.name}'));
    }
  });
}
