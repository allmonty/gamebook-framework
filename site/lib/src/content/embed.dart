import 'dart:convert';

import 'template.dart';

/// Returns the raw JSON of the example at [path] (e.g.
/// `examples/03-items/locked-door`) in the page's language, or null.
typedef ExampleLookup = String? Function(String path);

final _gamebookBlock = RegExp(r'^```gamebook\n(.+?)\n```$', multiLine: true);

/// Replaces every fenced `gamebook` block naming an example with an embed that
/// carries the example's JSON, for the browser to turn into a player.
String embedExamples(String markdown, ExampleLookup lookup) =>
    markdown.replaceAllMapped(_gamebookBlock, (match) {
      final path = match[1]!.trim();
      final raw =
          lookup(path) ?? (throw BuildException('example not found: $path'));
      return '\n${exampleEmbed(path, raw)}\n';
    });

/// The HTML of one embed. The JSON is re-encoded on one line, so Markdown
/// keeps the block whole, and `</` is escaped so it cannot close the script.
String exampleEmbed(String path, String rawJson) {
  final Object? story;
  try {
    story = jsonDecode(rawJson);
  } on FormatException catch (e) {
    throw BuildException('example $path is not valid JSON: ${e.message}');
  }
  final json = jsonEncode(story).replaceAll('</', r'<\/');
  return '<div class="gb-embed" data-example="${_attribute.convert(path)}">'
      '<script type="application/json">$json</script></div>';
}

const _attribute = HtmlEscape(HtmlEscapeMode.attribute);
