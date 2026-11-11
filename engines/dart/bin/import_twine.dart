// Converts a Twine story to this format:
// `dart run gamebook_engine:import_twine <story.twee|story.html> <out-folder> [--lang en]`.
// Writes story.<lang>.json and builder.json into the folder and prints what
// could not be converted. Exits 1 if it cannot read the file, 2 on bad usage.
import 'dart:convert';
import 'dart:io';

import 'package:gamebook_engine/twine.dart';

/// Runs the importer over [args], reporting to [out]. Returns the exit code.
int runImportTwine(List<String> args, StringSink out) {
  final langAt = args.indexOf('--lang');
  final lang = langAt >= 0 && langAt + 1 < args.length
      ? args[langAt + 1]
      : 'en';
  final paths = [
    for (var i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') && (i == 0 || args[i - 1] != '--lang'))
        args[i],
  ];
  if (paths.length != 2 ||
      !RegExp(r'^[a-z]{2,3}(-[A-Z]{2})?$').hasMatch(lang)) {
    out.writeln(
      'Usage: import_twine <story.twee|story.html> <out-folder> [--lang en]',
    );
    return 2;
  }
  final TwineImport result;
  try {
    result = importTwine(File(paths[0]).readAsStringSync(), lang: lang);
  } on Object catch (e) {
    out.writeln('cannot import ${paths[0]}: $e');
    return 1;
  }
  const json = JsonEncoder.withIndent('  ');
  final dir = Directory(paths[1])..createSync(recursive: true);
  File('${dir.path}/story.$lang.json')
      .writeAsStringSync('${json.convert(result.story)}\n');
  File('${dir.path}/builder.json').writeAsStringSync(
    '${json.convert({
      'builder': 1,
      'source': lang,
      'nodes': {
        for (final MapEntry(key: id, value: (x, y)) in result.positions.entries) id: {'x': x.round(), 'y': y.round()},
      },
    })}\n',
  );
  final pages = (result.story['nodes']! as Map).length;
  out.writeln('wrote ${dir.path}/story.$lang.json ($pages pages)');
  for (final line in result.report) {
    out.writeln('- $line');
  }
  return 0;
}

void main(List<String> args) => exit(runImportTwine(args, stdout));
