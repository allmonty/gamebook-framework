import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import '../bin/llm_kit.dart';

void main() {
  test('spec/llm-kit.md is up to date (run llm_kit if this fails)', () {
    final out = StringBuffer();
    expect(runLlmKit(['--check'], out), 0, reason: '$out');
  });

  final kit = buildKit();

  test('holds the instructions and the whole reference, in order', () {
    final headings = [
      '# Gamebook Framework: kit for LLMs',
      '## Instructions for the model',
      '## Mistakes that most often make a story invalid',
      '## Part B. Technical reference',
      for (var i = 1; i <= 14; i++) '### B$i. ',
    ];
    var at = 0;
    for (final heading in headings) {
      final found = kit.indexOf('\n$heading', at);
      expect(found, greaterThan(at), reason: heading);
      at = found;
    }
  });

  test('its complete example is a valid story', () {
    final section = kit.substring(kit.indexOf('### B12.'));
    final start = section.indexOf('```json\n') + '```json\n'.length;
    final story = Story.parse(
      section.substring(start, section.indexOf('```', start)),
    );
    expect(
      validateStory(story).where((i) => i.severity == Severity.error),
      isEmpty,
    );
  });
}
