// Prints a story as a graph:
// `dart run gamebook_engine:story_graph <story.json> [--mermaid]`.
// Default output is Graphviz DOT: `... | dot -Tsvg > story.svg`.
import 'dart:io';

import 'package:gamebook_engine/graph.dart';
import 'package:gamebook_engine/story.dart';

/// Returns the exit code; the graph goes to [out], problems to [err].
int runGraph(List<String> args, StringSink out, StringSink err) {
  final paths = args.where((a) => !a.startsWith('--')).toList();
  if (paths.length != 1) {
    err.writeln('Usage: story_graph <story.json> [--mermaid]');
    return 2;
  }
  try {
    final story = Story.parse(File(paths.single).readAsStringSync());
    out.write(args.contains('--mermaid') ? toMermaid(story) : toDot(story));
    return 0;
  } on StoryFormatException catch (e) {
    err.writeln('${paths.single}: $e');
  } on FileSystemException catch (e) {
    err.writeln(e.message);
  }
  return 1;
}

void main(List<String> args) => exit(runGraph(args, stdout, stderr));
