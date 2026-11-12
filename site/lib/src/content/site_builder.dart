import 'dart:convert';
import 'dart:io';

import 'package:gamebook_engine/package.dart' show mediaTypes;

import 'chapter.dart';
import 'embed.dart';
import 'template.dart';

/// Builds the static site from the `site/` folder [source] into [output].
/// Every page exists once per language, at the same path under `<lang>/`.
class SiteBuilder {
  SiteBuilder({required this.source, required this.output});

  final Directory source;
  final Directory output;

  static const languages = ['en', 'pt'];

  /// Where the site is published: for the links that must be whole
  /// addresses (canonical, the other language, what a shared link shows).
  static const url = 'https://allmonty.github.io/gamebook-framework/';

  void build() {
    if (output.existsSync()) output.deleteSync(recursive: true);
    output.createSync(recursive: true);
    _copyDir('css');
    _copyDir('assets');
    // Example stories are embedded in the pages; only their pictures and
    // sounds are served as files, next to where the story says they are.
    _copyDir('examples', (path) => mediaTypes.any(path.endsWith));
    _publishFormatFiles();
    _write('index.html', fillTemplate(_read('templates/root.html'), const {}));
    for (final lang in languages) {
      _buildLanguage(lang);
    }
  }

  void _buildLanguage(String lang) {
    final strings = loadStrings(lang);
    _writePage(lang, 'index.html', strings, _read('templates/index.html'));
    _writePage(lang, 'play.html', strings, _read('templates/play.html'));
    _buildTutorial(lang, strings);
    _buildPages(lang, strings);
  }

  /// Every `content/<lang>/*.md` becomes `<lang>/tutorial/<slug>.html`, with
  /// a contents list and previous/next links; `tutorial/index.html` lists
  /// them all.
  void _buildTutorial(String lang, Map<String, String> strings) {
    final chapters = loadChapters(lang);
    _writePage(
      lang,
      'tutorial/index.html',
      strings,
      _read('templates/tutorial-index.html'),
      {'toc': _toc(chapters, null)},
    );
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      _writePage(
        lang,
        'tutorial/${chapter.slug}.html',
        strings,
        _read('templates/tutorial.html'),
        {
          'page.title': '${chapter.title} · ${strings['tutorial.title']}',
          'toc': _toc(chapters, chapter),
          'chapter.html': chapter.html,
          'pager': _pager(
            i == 0 ? null : chapters[i - 1],
            i == chapters.length - 1 ? null : chapters[i + 1],
            strings,
          ),
        },
      );
    }
  }

  /// Every `pages/<lang>/<name>.md` becomes `<lang>/<name>.html`: the pages
  /// that stand on their own, outside the tutorial (the format's versions,
  /// the starter games).
  void _buildPages(String lang, Map<String, String> strings) {
    final files =
        Directory('${source.path}/pages/$lang')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last.replaceFirst('.md', '');
      final page = renderChapter(
        name,
        file.readAsStringSync(),
        exampleLookup(lang),
      );
      _writePage(lang, '$name.html', strings, _read('templates/page.html'), {
        'page.title': '${page.title} · Gamebook Framework',
        'page.html': page.html,
      });
    }
  }

  /// The chapters of [lang], in file-name order.
  List<Chapter> loadChapters(String lang) {
    final dir = Directory('${source.path}/content/$lang');
    if (!dir.existsSync()) return const [];
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final file in files)
        renderChapter(
          file.uri.pathSegments.last.replaceFirst(RegExp(r'\.md$'), ''),
          file.readAsStringSync(),
          exampleLookup(lang),
        ),
    ];
  }

  static String _toc(List<Chapter> chapters, Chapter? current) => [
    '<ol class="toc-list">',
    for (final c in chapters)
      '<li><a href="${c.slug}.html"${identical(c, current) ? ' aria-current="page"' : ''}>'
          '${_html.convert(c.title)}</a></li>',
    '</ol>',
  ].join();

  static String _pager(
    Chapter? previous,
    Chapter? next,
    Map<String, String> strings,
  ) => [
    if (previous != null)
      '<a class="prev" href="${previous.slug}.html"><span class="label">${strings['tutorial.previous']}</span>${_html.convert(previous.title)}</a>',
    if (next != null)
      '<a class="next" href="${next.slug}.html"><span class="label">${strings['tutorial.next']}</span>${_html.convert(next.title)}</a>',
  ].join();

  /// The visitor-facing text for [lang], from `strings/<lang>.json`.
  Map<String, String> loadStrings(String lang) =>
      (jsonDecode(_read('strings/$lang.json')) as Map<String, Object?>).map(
        (key, value) => MapEntry(key, value! as String),
      );

  /// Wraps [body] in the layout and writes it to `<lang>/<path>`.
  void _writePage(
    String lang,
    String path,
    Map<String, String> strings,
    String body, [
    Map<String, String> extra = const {},
  ]) {
    final depth = path.split('/').length;
    final values = {
      ...strings,
      'player.json': _playerJson(strings),
      'lang': lang,
      'root': '../' * depth,
      'path': path,
      'otherLang': lang == 'en' ? 'pt' : 'en',
      'site.url': url,
      // Which part of the site this page is in, for the header's links.
      'nav.tutorial.current': _current(path, 'tutorial/'),
      'nav.play.current': _current(path, 'play.html'),
      'nav.starters.current': _current(path, 'starters.html'),
      ...extra,
    };
    // A chapter's title comes from its Markdown: made safe for an attribute.
    values['page.title.attr'] = _attribute.convert(values['page.title']!);
    final page = fillTemplate(_read('templates/layout.html'), {
      ...values,
      'content': fillTemplate(embedExamples(body, exampleLookup(lang)), values),
    });
    _write('$lang/$path', page);
  }

  /// Finds `<path>.<lang>.json` under [source].
  ExampleLookup exampleLookup(String lang) => (path) {
    final file = File('${source.path}/$path.$lang.json');
    return file.existsSync() ? file.readAsStringSync() : null;
  };

  /// The strings the player needs in the browser, safe inside a script tag.
  static String _playerJson(Map<String, String> strings) => jsonEncode({
    for (final MapEntry(:key, :value) in strings.entries)
      if (key.startsWith('player.')) key: value,
  }).replaceAll('</', r'<\/');

  static const _html = HtmlEscape();
  static const _attribute = HtmlEscape(HtmlEscapeMode.attribute);

  /// ` aria-current="..."` for the header link to [section]: `page` on that
  /// very page, `true` on a page inside it, nothing elsewhere.
  static String _current(String path, String section) =>
      path == section || path == '${section}index.html'
      ? ' aria-current="page"'
      : path.startsWith(section)
      ? ' aria-current="true"'
      : '';

  String _read(String path) => File('${source.path}/$path').readAsStringSync();

  void _write(String path, String text) {
    File('${output.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  /// The format's own files, at stable addresses on the site: what a story's
  /// `"$schema"` and an AI assistant reach for. They live in the repo,
  /// one level above the site's sources.
  void _publishFormatFiles() {
    final repo = '${source.path}/..';
    void copy(String from, String to) {
      File('${output.path}/$to').parent.createSync(recursive: true);
      File('$repo/$from').copySync('${output.path}/$to');
    }

    copy('llms.txt', 'llms.txt');
    copy('spec/llm-kit.md', 'llm-kit.md');
    copy('spec/story.schema.json', 'schema/story.schema.json');
    for (final preset in Directory('$repo/spec/presets').listSync()) {
      if (preset is File && preset.path.endsWith('.json')) {
        copy(
          'spec/presets/${preset.uri.pathSegments.last}',
          'presets/${preset.uri.pathSegments.last}',
        );
      }
    }
  }

  void _copyDir(String name, [bool Function(String path)? only]) {
    for (final entity in Directory(
      '${source.path}/$name',
    ).listSync(recursive: true)) {
      if (entity is! File || !(only?.call(entity.path) ?? true)) continue;
      final relative = entity.path.substring(source.path.length + 1);
      File('${output.path}/$relative').parent.createSync(recursive: true);
      entity.copySync('${output.path}/$relative');
    }
  }
}
