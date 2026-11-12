/// The schema-version gate (spec B2): a story may only use what its
/// `schema` has. Version 1 has everything there is so far. A later version
/// adds its check to [_gates]: the version, and a finder that returns the
/// JSON path of the first thing in a story that needs it.
library;

import 'story.dart';

const _gates = <(int, String? Function(Story))>[];

/// The lowest version above [Story.schema] the story needs, with the JSON
/// path of the first thing that needs it; null if its `schema` is enough.
(int, String)? firstNewerFeature(Story story) {
  for (final (version, find) in _gates) {
    if (version <= story.schema) continue;
    if (find(story) case final path?) return (version, path);
  }
  return null;
}
