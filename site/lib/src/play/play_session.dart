import 'dart:math';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/story.dart';

import 'views.dart';

/// Plays one story: the use cases the UI calls, and the [view] it draws.
class PlaySession {
  PlaySession._(this.story, this.rules, this._random);

  /// Starts a new game with freshly rolled stats. Throws
  /// `StoryFormatException` if the rules cannot be resolved.
  factory PlaySession.start(Story story, {required Random random}) {
    final session = PlaySession._(story, Rules.resolve(story.rules), random);
    session.restart();
    return session;
  }

  final Story story;
  final Rules rules;
  final Random _random;
  late GameEngine _engine;

  /// Starts over from the first page with new stats.
  void restart() {
    final (engine, _) = GameEngine.newGame(
      story: story,
      rules: rules,
      random: _random,
      stats: rules.rollStats(_random),
    );
    _engine = engine;
  }

  /// Takes the choice at [index] (a [ChoiceItem.index]).
  void choose(int index) => _engine.choose(index);

  PageView get view => PageView(
    storyTitle: story.title,
    title: story.showTitles ? _engine.node.title : null,
    image: _engine.node.image,
    paragraphs: _engine.paragraphs,
    choices: [for (final c in _engine.choices) _choice(c)],
    stats: [for (final s in rules.stats) _stat(s)],
    ending: _engine.ending,
  );

  ChoiceItem _choice(ChoiceView c) => ChoiceItem(
    index: c.index,
    text: c.text,
    kind: c.choice.check != null
        ? ChoiceKind.check
        : c.choice.table != null
        ? ChoiceKind.table
        : ChoiceKind.plain,
    locked: c.locked,
    lockedText: c.locked ? c.choice.lockedText : null,
    needs: [for (final u in c.unmet) _requirement(u)],
  );

  Requirement _requirement(Unmet unmet) => switch (unmet.condition) {
    HasItem(:final item) => Requirement(
      RequirementKind.item,
      story.items[item]?.name ?? item,
      negated: unmet.negated,
    ),
    FlagSet(:final flag) => Requirement(
      RequirementKind.flag,
      flag,
      negated: unmet.negated,
    ),
    Visited(:final node) => Requirement(
      RequirementKind.visited,
      node,
      negated: unmet.negated,
    ),
    VisitCount(:final node, :final op, :final value) => Requirement(
      RequirementKind.visits,
      node,
      negated: unmet.negated,
      op: op,
      target: value,
    ),
    StatCompare(:final stat, :final op) => Requirement(
      RequirementKind.stat,
      _label(stat),
      negated: unmet.negated,
      op: op,
      target: unmet.target,
    ),
    // explain() never returns these: it breaks them into their leaves.
    All() || Any() || Not() => throw StateError('not a leaf condition'),
  };

  StatPill _stat(StatRules rule) {
    final state = _engine.state;
    return StatPill(
      id: rule.id,
      label: rule.label,
      value: state.stat(rule.id),
      max: state.stats[rule.id]?.max,
      bonus: state.bonusOf(rule.id),
    );
  }

  String _label(String stat) =>
      rules.stats.where((s) => s.id == stat).firstOrNull?.label ?? stat;
}
