import 'dart:convert';

import 'story.dart';
import 'validate.dart';

/// A Twine passage, as read from Twee or a published Twine file.
class _Passage {
  _Passage(this.name, this.text, this.tags, this.position);

  final String name;
  final String text;
  final Set<String> tags;

  /// Twine's card position, if it has one.
  final (double, double)? position;
}

/// A Twine story turned into this format: the story file
/// as JSON, card positions for the Builder, and a report of everything that
/// could not be converted and was left out or guessed.
class TwineImport {
  const TwineImport(this.story, this.positions, this.report);

  final Map<String, Object?> story;

  /// Page id to Twine's (x, y), for `builder.json`.
  final Map<String, (double, double)> positions;
  final List<String> report;
}

/// Reads Twine's text format (Twee 3) or a published Twine 2 HTML file and
/// converts it: passages become pages (their names kept as titles), links
/// become choices, passages without links become endings (victory, unless
/// tagged `death`). Twine code (macros, variables) has no equivalent here;
/// it stays in the text and is reported. [lang] is the language of the story.
TwineImport importTwine(String source, {String lang = 'en'}) {
  final html = source.contains('<tw-storydata');
  final (title, start, passages) = html ? _fromHtml(source) : _fromTwee(source);
  final report = <String>[];
  if (passages.isEmpty) throw const FormatException('no passages found');

  // Passage names become ids: readable slugs, unique.
  final ids = <String, String>{};
  for (final p in passages) {
    var id = _slug(p.name);
    for (var n = 2; ids.containsValue(id); n++) {
      id = '${_slug(p.name)}-$n';
    }
    ids[p.name] = id;
  }

  final nodes = <String, Object?>{};
  final positions = <String, (double, double)>{};
  for (final p in passages) {
    final id = ids[p.name]!;
    final links = _links(p.text);
    final choices = <Map<String, Object?>>[];
    for (final (text, target) in links) {
      final to = ids[target];
      if (to == null) {
        report.add(
          '"${p.name}": the link to "$target" leads to no passage; left out',
        );
        continue;
      }
      if (choices.any((c) => c['to'] == to && c['text'] == text)) continue;
      choices.add({'text': text, 'to': to});
    }
    var text = _withoutLinks(p.text);
    if (_code.hasMatch(text)) {
      report.add(
        '"${p.name}": Twine code (macros or variables) has no equivalent; '
        'it is kept in the text to rewrite by hand',
      );
    }
    if (text.isEmpty) text = p.name;
    final node = <String, Object?>{'title': p.name, 'text': text};
    if (choices.isNotEmpty) {
      node['choices'] = choices;
    } else {
      final death = p.tags.contains('death');
      node['ending'] = death ? 'death' : 'victory';
      if (!death && !p.tags.contains('victory')) {
        report.add(
          '"${p.name}": no links, so it is an ending; taken as a victory '
          '(tag it "death" in Twine, or change it here)',
        );
      }
    }
    nodes[id] = node;
    if (p.position case final at?) positions[id] = at;
  }

  final startId = ids[start] ?? ids['Start'] ?? ids[passages.first.name]!;
  if (start != null && !ids.containsKey(start)) {
    report.add('the start passage "$start" is missing; starting at "$startId"');
  }
  final story = <String, Object?>{
    'schema': 6,
    'id': _slug(title).toLowerCase(),
    'lang': lang,
    'title': title,
    'rules': {'preset': 'fighting-fantasy'},
    'start': startId,
    'nodes': nodes,
  };
  // What the validator says is part of the report: a converted story must be
  // checked, not trusted.
  for (final issue in validateStory(Story.fromJson(story))) {
    report.add('$issue');
  }
  return TwineImport(story, positions, report);
}

final _code = RegExp(r'<<|\(\w+:|\$\w|_\w+\s*to\b');
final _link = RegExp(r'\[\[(.+?)\]\]');

/// The links of a passage as (text, target), in order:
/// `[[target]]`, `[[text->target]]`, `[[target<-text]]`, `[[text|target]]`.
List<(String, String)> _links(String text) => [
  for (final m in _link.allMatches(text))
    switch (m[1]!) {
      final l when l.contains('->') => (
        l.substring(0, l.lastIndexOf('->')).trim(),
        l.substring(l.lastIndexOf('->') + 2).trim(),
      ),
      final l when l.contains('<-') => (
        l.substring(l.indexOf('<-') + 2).trim(),
        l.substring(0, l.indexOf('<-')).trim(),
      ),
      final l when l.contains('|') => (
        l.substring(0, l.lastIndexOf('|')).trim(),
        l.substring(l.lastIndexOf('|') + 1).trim(),
      ),
      final l => (l.trim(), l.trim()),
    },
];

/// The passage's text with its links taken out: a line that is only links
/// goes; a link inside a sentence leaves its words.
String _withoutLinks(String text) {
  final lines = [
    for (final line in text.split('\n'))
      if (line.replaceAll(_link, '').trim().isNotEmpty || !_link.hasMatch(line))
        line.replaceAllMapped(_link, (m) {
          final l = m[1]!;
          return l.contains('->')
              ? l.substring(0, l.lastIndexOf('->'))
              : l.contains('<-')
              ? l.substring(l.indexOf('<-') + 2)
              : l.contains('|')
              ? l.substring(0, l.lastIndexOf('|'))
              : l;
        }),
  ];
  return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String _slug(String name) {
  final slug = name
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'passage' : slug;
}

const _special = {
  'StoryTitle',
  'StoryData',
  'StoryInit',
  'StoryCaption',
  'StoryMenu',
  'StoryBanner',
  'StorySubtitle',
  'StoryAuthor',
  'PassageReady',
  'PassageDone',
  'PassageHeader',
  'PassageFooter',
};

/// Twee 3: `:: Name [tags] {"position":"x,y"}` then the passage's text.
(String, String?, List<_Passage>) _fromTwee(String source) {
  final header = RegExp(r'^::\s*(.*?)\s*(\[[^\]]*\])?\s*(\{.*\})?\s*$');
  var title = 'Untitled';
  String? start;
  final passages = <_Passage>[];
  String? name;
  Set<String> tags = {};
  (double, double)? position;
  final body = StringBuffer();

  void flush() {
    if (name == null) return;
    final text = body.toString().trim();
    if (name == 'StoryTitle') {
      title = text;
    } else if (name == 'StoryData') {
      try {
        start = (jsonDecode(text) as Map<String, Object?>)['start'] as String?;
      } on Object {
        // A StoryData that is not JSON names no start.
      }
    } else if (!_special.contains(name) &&
        !tags.contains('script') &&
        !tags.contains('stylesheet')) {
      passages.add(_Passage(name, text, tags, position));
    }
    body.clear();
  }

  for (final line in const LineSplitter().convert(source)) {
    final m = line.startsWith('::') ? header.firstMatch(line) : null;
    if (m == null) {
      body.writeln(line);
      continue;
    }
    flush();
    name = m[1]!;
    final rawTags = m[2];
    tags = rawTags == null
        ? {}
        : rawTags
              .substring(1, rawTags.length - 1)
              .split(RegExp(r'\s+'))
              .where((t) => t.isNotEmpty)
              .toSet();
    position = null;
    if (m[3] case final meta?) {
      try {
        final at = (jsonDecode(meta) as Map<String, Object?>)['position'];
        if (at is String && at.contains(',')) {
          final [x, y] = at.split(',').map(double.parse).toList();
          position = (x, y);
        }
      } on Object {
        // Metadata that is not JSON is ignored.
      }
    }
  }
  flush();
  return (title, start, passages);
}

/// A published Twine 2 file: `<tw-storydata>` with `<tw-passagedata>`.
(String, String?, List<_Passage>) _fromHtml(String source) {
  String? attr(String tag, String name) =>
      RegExp('$name="([^"]*)"').firstMatch(tag)?.group(1);
  final data = RegExp(r'<tw-storydata[^>]*>').firstMatch(source)![0]!;
  final startPid = attr(data, 'startnode');
  String? start;
  final passages = <_Passage>[];
  final passage = RegExp(
    r'<tw-passagedata([^>]*)>(.*?)</tw-passagedata>',
    dotAll: true,
  );
  for (final m in passage.allMatches(source)) {
    final tag = m[1]!;
    final name = _unescape(attr(tag, 'name') ?? '');
    final tags = (attr(tag, 'tags') ?? '')
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toSet();
    if (attr(tag, 'pid') == startPid) start = name;
    final at = attr(tag, 'position')?.split(',');
    passages.add(
      _Passage(
        name,
        _unescape(m[2]!).trim(),
        tags,
        at != null && at.length == 2
            ? (double.tryParse(at[0]) ?? 0, double.tryParse(at[1]) ?? 0)
            : null,
      ),
    );
  }
  return (_unescape(attr(data, 'name') ?? 'Untitled'), start, passages);
}

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
