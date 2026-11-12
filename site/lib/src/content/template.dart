/// Thrown when a page cannot be built, naming what is missing.
class BuildException implements Exception {
  BuildException(this.message);
  final String message;

  @override
  String toString() => 'BuildException: $message';
}

final _placeholder = RegExp(r'\{\{([\w.-]+)\}\}');

/// Fills `{{name}}` placeholders from [values]. A placeholder without a value
/// fails the build, so a missing translation never ships as `{{name}}`.
/// Inserted values are not scanned again.
String fillTemplate(String template, Map<String, String> values) =>
    template.replaceAllMapped(_placeholder, (match) {
      final name = match[1]!;
      return values[name] ?? (throw BuildException('no value for {{$name}}'));
    });
