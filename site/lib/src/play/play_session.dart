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

  /// Uses a carried item (a [PackItem.usable] one).
  void useItem(String id) => _engine.useItem(id);

  /// Takes the offered item, leaving [replacing] behind when the pack is full.
  void takeOffer({String? replacing}) =>
      _engine.resolveOffer(take: true, replacing: replacing);

  /// Leaves the offered item where it is.
  void leaveOffer() => _engine.resolveOffer(take: false);

  PageView get view => PageView(
    storyTitle: story.title,
    title: story.showTitles ? _engine.node.title : null,
    image: _engine.node.image,
    paragraphs: _engine.paragraphs,
    // The engine refuses choices until the offer is settled, so hide them.
    choices: _engine.offer != null
        ? const []
        : [for (final c in _engine.choices) _choice(c)],
    stats: [for (final s in rules.stats) _stat(s)],
    pack: PackView(
      items: [for (final id in _engine.state.inventory) _item(id)],
      used: _engine.slotsUsed,
      capacity: _engine.capacity,
    ),
    offer: _offer(),
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

  PackItem _item(String id) {
    final item = story.items[id];
    return PackItem(
      id: id,
      name: item?.name ?? id,
      description: item?.description,
      bonus: [
        for (final MapEntry(:key, :value) in (item?.bonus ?? {}).entries)
          (_label(key), value),
      ],
      usable: _engine.canUse(id),
      room: item?.capacity,
    );
  }

  OfferView? _offer() {
    final id = _engine.offer;
    if (id == null) return null;
    return OfferView(
      item: _item(id),
      swapFrom: _engine.canHold(id)
          ? const []
          : [
              for (final carried in _engine.state.inventory)
                if (!_engine.isContainer(carried)) _item(carried),
            ],
      more: _engine.moreOffers,
    );
  }

  String _label(String stat) =>
      rules.stats.where((s) => s.id == stat).firstOrNull?.label ?? stat;
}
