import 'dart:math';

import 'package:gamebook_engine/effect.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/rules_spec.dart';
import 'package:gamebook_engine/state.dart';

import 'views.dart';

/// Character creation (spec B4): rolled stats with rerolls, the hero's name,
/// and pick groups. The game starts from a finished draft.
class HeroDraft {
  HeroDraft(this.rules, this._random)
    : rerollsLeft = rules.rerolls,
      stats = rules.rollStats(_random);

  final Rules rules;
  final Random _random;
  Map<String, StatValue> stats;
  int rerollsLeft;
  String name = '';
  final Map<String, Set<String>> _picked = {};

  bool get asksName => rules.creation?.name ?? false;
  List<PickGroup> get _groups => rules.creation?.picks ?? const [];

  /// Rolls every stat again; the last roll is kept.
  void reroll() {
    if (rerollsLeft == 0) throw StateError('no rerolls left');
    rerollsLeft--;
    stats = rules.rollStats(_random);
  }

  /// Picks or unpicks [option] of [group]. A full group ignores new picks.
  void toggle(String group, String option) {
    final picked = _picked.putIfAbsent(group, () => {});
    final count = _groups.firstWhere((g) => g.id == group).count;
    if (!picked.remove(option) && picked.length < count) picked.add(option);
  }

  /// Every group has exactly its count, and the hero is named if asked.
  bool get ready =>
      (!asksName || name.trim().isNotEmpty) &&
      _groups.every((g) => (_picked[g.id]?.length ?? 0) == g.count);

  /// The effects of the picks, group by group and option by option in file
  /// order (spec B4), whatever order the player clicked them in.
  List<Effect> get effects => [
    for (final group in _groups)
      for (final option in group.options)
        if (_picked[group.id]?.contains(option.id) ?? false) ...option.effects,
  ];

  CreationView get view => CreationView(
    stats: [
      for (final s in rules.stats)
        StatPill(
          id: s.id,
          label: s.label,
          value: stats[s.id]!.value,
          max: stats[s.id]!.max,
        ),
    ],
    rerollsLeft: rerollsLeft,
    asksName: asksName,
    name: name,
    groups: [
      for (final g in _groups)
        PickGroupView(
          id: g.id,
          title: g.title,
          count: g.count,
          options: [
            for (final o in g.options)
              PickOptionView(
                id: o.id,
                label: o.label,
                description: o.description,
                picked: _picked[g.id]?.contains(o.id) ?? false,
              ),
          ],
        ),
    ],
    ready: ready,
  );
}
