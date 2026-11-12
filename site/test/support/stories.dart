import 'dart:convert';
import 'dart:io';

import 'package:gamebook_engine/story.dart';

/// The story of a conformance play case, e.g. `locked-choice`.
Story conformanceStory(String name) {
  final file = File('../conformance/cases/play/$name.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return Story.fromJson(json['story']);
}

/// A story from inline JSON with the boilerplate filled in.
Story storyOf(Map<String, Object?> nodes, {Map<String, Object?>? extra}) =>
    Story.fromJson({
      'schema': 7,
      'id': 'test',
      'lang': 'en',
      'title': 'Test',
      'rules': {'preset': 'fighting-fantasy'},
      'start': nodes.keys.first,
      'nodes': nodes,
      ...?extra,
    });

/// A story file of the site, e.g. `examples/home/rusty-door.en.json`.
Story storyFile(String path) => Story.parse(File(path).readAsStringSync());
