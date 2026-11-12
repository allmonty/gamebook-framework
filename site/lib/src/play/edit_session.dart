import 'dart:math';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';

import 'play_session.dart';

/// One problem found in the story text, at a JSON path like
/// `nodes.door.choices[0].to` (empty for the whole file).
class IssueView {
  const IssueView({
    required this.error,
    required this.where,
    required this.message,
    this.code,
  });

  final bool error;

  /// A warning's code from spec B16, like `unreachable`; null for errors.
  final String? code;
  final String where;
  final String message;
}

/// Editing a story's JSON: every [update] re-checks the text and, when it
/// has no errors, starts a fresh game of it in [play].
class EditSession {
  EditSession(this.original, this._random) {
    update(original);
  }

  /// The text the editor started with; [reset] goes back to it.
  final String original;
  final Random _random;

  String source = '';
  List<IssueView> issues = const [];

  /// A game of the current text; null while the text has errors.
  PlaySession? play;

  bool get hasErrors => issues.any((i) => i.error);

  void update(String text) {
    source = text;
    try {
      final story = Story.parse(text);
      issues = [
        for (final issue in validateStory(story))
          IssueView(
            error: issue.severity == Severity.error,
            where: issue.where,
            message: issue.message,
            code: issue.code,
          ),
      ];
      play = hasErrors ? null : PlaySession.start(story, random: _random);
    } on StoryFormatException catch (e) {
      issues = [IssueView(error: true, where: e.path, message: e.message)];
      play = null;
    } on Object catch (e) {
      // Whatever a story from a stranger breaks, the page says so and lives.
      issues = [IssueView(error: true, where: '', message: '$e')];
      play = null;
    }
  }

  void reset() => update(original);
}
