import 'json_reader.dart';

final _name = RegExp(r'^[A-Za-z0-9_-]+(\.max|\.count)?$');

/// A `{stat}`, `{stat.max}` or (schema 8) `{item.count}` placeholder.
class _Placeholder {
  const _Placeholder(this.name);
  final String name;
}

/// Splits [source] into literal strings and placeholders. `{{` and `}}` are
/// literal braces. Anything else between braces that is not a stat name, or a
/// lone brace, is a [StoryFormatException] at [path].
List<Object> _tokens(String source, String path) {
  final out = <Object>[];
  final literal = StringBuffer();
  void flush() {
    if (literal.isNotEmpty) out.add(literal.toString());
    literal.clear();
  }

  var i = 0;
  while (i < source.length) {
    final c = source[i];
    final next = i + 1 < source.length ? source[i + 1] : '';
    if (c == '{' && next == '{') {
      literal.write('{');
      i += 2;
    } else if (c == '}' && next == '}') {
      literal.write('}');
      i += 2;
    } else if (c == '{') {
      final end = source.indexOf('}', i);
      if (end == -1) {
        throw StoryFormatException(path, 'unclosed "{" in "$source"');
      }
      final name = source.substring(i + 1, end);
      if (!_name.hasMatch(name)) {
        throw StoryFormatException(
          path,
          'bad placeholder "{$name}" (use {stat}, {stat.max} or {item.count}; '
          'write {{ for a brace)',
        );
      }
      flush();
      out.add(_Placeholder(name));
      i = end + 1;
    } else if (c == '}') {
      throw StoryFormatException(
        path,
        'stray "}" in "$source" (write }} for a brace)',
      );
    } else {
      literal.write(c);
      i++;
    }
  }
  flush();
  return out;
}

/// Throws if [source] has a bad placeholder or a stray brace.
void checkTemplate(String source, String path) => _tokens(source, path);

/// The stat ids [source] refers to, in order, without ".max".
List<String> placeholderStats(String source) => [
  for (final t in _tokens(source, ''))
    if (t is _Placeholder && !t.name.endsWith('.count'))
      t.name.replaceFirst(RegExp(r'\.max$'), ''),
];

/// The item ids [source] counts with `{item.count}` (schema 8), in order.
List<String> placeholderItems(String source) => [
  for (final t in _tokens(source, ''))
    if (t is _Placeholder && t.name.endsWith('.count'))
      t.name.substring(0, t.name.length - '.count'.length),
];

/// [source] with each placeholder replaced by `lookup(name)`; a placeholder
/// whose lookup is null stays as written.
String renderTemplate(String source, String? Function(String name) lookup) {
  final out = StringBuffer();
  for (final t in _tokens(source, '')) {
    if (t is _Placeholder) {
      out.write(lookup(t.name) ?? '{${t.name}}');
    } else {
      out.write(t);
    }
  }
  return out.toString();
}
