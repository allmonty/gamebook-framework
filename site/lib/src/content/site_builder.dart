import 'dart:convert';
import 'dart:io';

import 'embed.dart';
import 'template.dart';

/// Builds the static site from the `site/` folder [source] into [output].
/// Every page exists once per language, at the same path under `<lang>/`.
class SiteBuilder {
  SiteBuilder({required this.source, required this.output});

  final Directory source;
  final Directory output;

  static const languages = ['en', 'pt'];

  void build() {
    if (output.existsSync()) output.deleteSync(recursive: true);
    output.createSync(recursive: true);
    _copyDir('css');
    _copyDir('assets');
    _write('index.html', fillTemplate(_read('templates/root.html'), const {}));
    for (final lang in languages) {
      _buildLanguage(lang);
    }
  }

  void _buildLanguage(String lang) {
    final strings = loadStrings(lang);
    _writePage(lang, 'index.html', strings, _read('templates/index.html'));
    _writePage(lang, 'play.html', strings, _read('templates/play.html'));
  }

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
    String body,
  ) {
    final depth = path.split('/').length;
    final values = {
      ...strings,
      'player.json': _playerJson(strings),
      'lang': lang,
      'root': '../' * depth,
      'path': path,
      'otherLang': lang == 'en' ? 'pt' : 'en',
    };
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

  String _read(String path) => File('${source.path}/$path').readAsStringSync();

  void _write(String path, String text) {
    File('${output.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  void _copyDir(String name) {
    for (final entity in Directory(
      '${source.path}/$name',
    ).listSync(recursive: true)) {
      if (entity is! File) continue;
      final relative = entity.path.substring(source.path.length + 1);
      File('${output.path}/$relative').parent.createSync(recursive: true);
      entity.copySync('${output.path}/$relative');
    }
  }
}
