// Checks story files:
// `dart run gamebook_engine:validate_story <dir|file>... [--strict] [--llm]`.
// --llm prints the problems as a message to paste back to the chatbot that
// wrote the story. Exits 1 if there are errors (or warnings with --strict),
// 2 on bad usage.
import 'dart:io';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';

// `story.schema.json` is the JSON Schema, not a story.
final _storyFile = RegExp(r'^story\.(?!schema\.)([A-Za-z-]+)\.json$');

/// Runs the validator over [args], writing the report to [out]. Returns the
/// process exit code.
int runValidator(List<String> args, StringSink out) {
  final strict = args.contains('--strict');
  final llm = args.contains('--llm');
  final paths = args.where((a) => !a.startsWith('--')).toList();
  final files = <File>[
    for (final path in paths)
      if (FileSystemEntity.isDirectorySync(path))
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => _storyFile.hasMatch(_name(f)))
      else
        File(path),
  ]..sort((a, b) => a.path.compareTo(b.path));
  if (paths.isEmpty || files.isEmpty) {
    out.writeln(
      'No story files found. '
      'Usage: validate_story <dir|file>... [--strict] [--llm]',
    );
    return 2;
  }

  var errors = 0;
  var warnings = 0;
  final byId = <String, List<Story>>{};

  final lines = <String>[];
  void report(String file, Iterable<Issue> issues) {
    for (final issue in issues) {
      // The chatbot knows its files by name, not by the author's paths.
      lines.add('${llm ? file.split('/').last : file}: $issue');
      issue.severity == Severity.error ? errors++ : warnings++;
    }
  }

  for (final file in files) {
    final Story story;
    try {
      story = Story.parse(file.readAsStringSync());
    } on StoryFormatException catch (e) {
      report(file.path, [Issue(Severity.error, e.path, e.message)]);
      continue;
    } on FileSystemException catch (e) {
      report(file.path, [Issue(Severity.error, '', e.message)]);
      continue;
    }
    final fileLang = _storyFile.firstMatch(_name(file))?.group(1);
    report(file.path, [
      if (fileLang != null && fileLang != story.lang)
        Issue(
          Severity.error,
          'lang',
          'is "${story.lang}" but the file name says "$fileLang"',
        ),
      ...validateStory(
        story,
        assetExists: (path) => File('${file.parent.path}/$path').existsSync(),
      ),
    ]);
    byId.putIfAbsent(story.id, () => []).add(story);
  }

  for (final MapEntry(:key, :value) in byId.entries) {
    for (final other in value.skip(1)) {
      report(key, compareTranslations(value.first, other));
    }
  }

  if (llm) {
    out.writeln(
      lines.isEmpty
          ? 'The validator found no problems.'
          : 'The validator found these problems in the story. Fix every one '
                'and reply with the whole corrected file, and nothing else.\n'
                '${[for (final l in lines) '- $l'].join('\n')}',
    );
  } else {
    lines.forEach(out.writeln);
    out.writeln(
      '${files.length} file(s): $errors error(s), $warnings warning(s).',
    );
  }
  return errors > 0 || (strict && warnings > 0) ? 1 : 0;
}

String _name(File f) => f.uri.pathSegments.last;

void main(List<String> args) => exit(runValidator(args, stdout));
