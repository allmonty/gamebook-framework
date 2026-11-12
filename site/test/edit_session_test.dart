import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_site/src/play/edit_session.dart';
import 'package:test/test.dart';

String _rustyDoor() {
  final json = jsonDecode(
    File('../conformance/cases/play/locked-choice.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return const JsonEncoder.withIndent('  ').convert(json['story']);
}

void main() {
  test('a valid story has no errors and can be played', () {
    final edit = EditSession(_rustyDoor(), Random(1));
    expect(edit.hasErrors, isFalse);
    expect(edit.play!.view.storyTitle, 'The Rusty Door');
  });

  test('broken JSON is one error and nothing to play', () {
    final edit = EditSession(_rustyDoor(), Random(1))..update('{oops');
    expect(edit.issues.single.error, isTrue);
    expect(edit.issues.single.message, contains('invalid JSON'));
    expect(edit.play, isNull);
  });

  test('a choice to a missing page is an error at its path', () {
    final edit = EditSession(_rustyDoor(), Random(1))
      ..update(_rustyDoor().replaceFirst('"to": "shelves"', '"to": "shelf"'));
    final error = edit.issues.firstWhere((i) => i.error);
    expect(error.where, contains('nodes.cellar'));
    expect(error.message, contains('shelf'));
    expect(edit.play, isNull);
  });

  test('a format error names the JSON path', () {
    final edit = EditSession(
      _rustyDoor().replaceFirst('"title": "The Rusty Door"', '"titel": "x"'),
      Random(1),
    );
    expect(edit.issues.single.error, isTrue);
    expect(edit.play, isNull);
  });

  test('an edit restarts the game with the new text; reset restores it', () {
    final edit = EditSession(
      _rustyDoor(),
      Random(1),
    )..update(_rustyDoor().replaceFirst('"The Rusty Door"', '"The Iron Door"'));
    expect(edit.play!.view.storyTitle, 'The Iron Door');
    edit.reset();
    expect(edit.play!.view.storyTitle, 'The Rusty Door');
    expect(edit.source, edit.original);
  });

  test('warnings carry their code', () {
    final story = _rustyDoor().replaceFirst(
      '"nodes": {',
      '"nodes": {\n    "attic": { "text": "Dust.", "ending": "death" },',
    );
    final edit = EditSession(story, Random(1));
    final warning = edit.issues.singleWhere((i) => !i.error);
    expect(warning.code, 'unreachable');
    expect(warning.where, 'nodes.attic');
    expect(edit.play, isNotNull, reason: 'warnings do not stop play');
  });
}
