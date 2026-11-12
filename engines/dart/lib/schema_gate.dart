/// The schema-version gate (spec B2): a story may only use what its
/// `schema` has.
library;

import 'story.dart';

/// The lowest version above [Story.schema] the story needs, with the JSON
/// path of the first thing that needs it; null if its `schema` is enough.
/// [usesShowTitles] says whether the file had `showTitles`, which the model
/// cannot tell from its default.
(int, String)? firstNewerFeature(Story story, {required bool usesShowTitles}) {
  final gates = <(int, String? Function(Story))>[
    (2, _schema2),
    (3, _schema3),
    (4, _schema4),
    (5, _schema5),
    (6, (s) => usesShowTitles ? 'showTitles' : _schema6(s)),
    (7, _schema7),
    (8, _schema8),
  ];
  for (final (version, find) in gates) {
    if (version <= story.schema) continue;
    if (find(story) case final path?) return (version, path);
  }
  return null;
}

String? _schema2(Story story) {
  for (final MapEntry(:key, :value) in story.items.entries) {
    if (value.use != null) return 'items.$key.use';
  }
  return null;
}

String? _schema3(Story story) {
  if (story.rules.inventory != null) return 'rules.inventory';
  for (final MapEntry(:key, :value) in story.items.entries) {
    if (value.capacity != null) return 'items.$key.capacity';
  }
  return _firstEffect(story, (e) => e is TakeAll);
}

String? _schema4(Story story) {
  for (final MapEntry(:key, :value) in story.nodes.entries) {
    if (value.textIsList) return 'nodes.$key.text';
    for (var i = 0; i < value.choices.length; i++) {
      final choice = value.choices[i];
      if (choice.once) return 'nodes.$key.choices[$i].once';
      if (choice.table != null) return 'nodes.$key.choices[$i].table';
      if (_usesVisits(choice.condition)) return 'nodes.$key.choices[$i].if';
    }
  }
  return null;
}

String? _schema5(Story story) {
  final rules = story.rules;
  if (rules.creation != null) return 'rules.creation';
  if (story.journal.isNotEmpty) return 'journal';
  for (final MapEntry(:key, :value) in story.nodes.entries) {
    if (value.music != null) return 'nodes.$key.music';
    if (value.sound != null) return 'nodes.$key.sound';
  }
  if ((rules.undo ?? 0) != 0) return 'rules.undo';
  if (rules.combat?.luck != null) return 'rules.combat.luck';
  if (rules.combat?.mode == 'table') return 'rules.combat.mode';
  if (rules.combat?.table != null) return 'rules.combat.table';
  for (final MapEntry(:key, :value) in rules.stats.entries) {
    if (value.limit != null) return 'rules.stats.$key.limit';
  }
  for (final MapEntry(:key, :value) in story.items.entries) {
    if (value.bonus.isNotEmpty) return 'items.$key.bonus';
  }
  for (final MapEntry(:key, :value) in story.nodes.entries) {
    final at = 'nodes.$key';
    final enemies = value.combat?.enemies ?? const <Enemy>[];
    if (value.combat?.simultaneous ?? false) return '$at.combat.simultaneous';
    if (value.combat?.duel ?? false) return '$at.combat.duel';
    for (var i = 0; i < enemies.length; i++) {
      if (enemies[i].armor != 0) return '$at.combat.enemies[$i].armor';
    }
    for (var i = 0; i < value.parts.length; i++) {
      if (_comparesStat(value.parts[i].condition)) {
        return value.textIsList ? '$at.text[$i].if' : '$at.text.if';
      }
    }
    for (var i = 0; i < value.choices.length; i++) {
      if (_comparesStat(value.choices[i].condition)) {
        return '$at.choices[$i].if';
      }
    }
  }
  return _firstEffect(
    story,
    (e) =>
        e is UnlockEntry ||
        e is StatChange && (e.replace || !e.amount.isConstant),
  );
}

String? _schema6(Story story) {
  if (story.chapters.isNotEmpty) return 'chapters';
  for (final MapEntry(:key, :value) in story.nodes.entries) {
    if (value.title != null) return 'nodes.$key.title';
    if (value.note != null) return 'nodes.$key.note';
    if (value.chapter != null) return 'nodes.$key.chapter';
    if (value.draft) return 'nodes.$key.draft';
  }
  return null;
}

String? _schema7(Story story) {
  if (story.achievements.isNotEmpty) return 'achievements';
  return _firstEffect(story, (e) => e is Achieve);
}

String? _schema8(Story story) {
  if (story.coverAlt != null) return 'coverAlt';
  for (final MapEntry(:key, :value) in story.items.entries) {
    if (value.imageAlt != null) return 'items.$key.imageAlt';
  }
  for (final MapEntry(:key, :value) in story.nodes.entries) {
    if (value.imageAlt != null) return 'nodes.$key.imageAlt';
    if (value.ending == Ending.defeat) return 'nodes.$key.ending';
  }
  return null;
}

/// The path of the first effect anywhere in the story that passes [test].
String? _firstEffect(Story story, bool Function(Effect) test) {
  for (final (path, effects) in story.effectLists()) {
    for (var i = 0; i < effects.length; i++) {
      if (test(effects[i])) return '$path[$i]';
    }
  }
  return null;
}

/// Whether [condition] compares a stat with another stat (schema 5).
bool _comparesStat(Condition? condition) => switch (condition) {
  null => false,
  StatCompare(:final value) => !value.isConstant,
  All(:final conditions) ||
  Any(:final conditions) => conditions.any(_comparesStat),
  Not(:final condition) => _comparesStat(condition),
  _ => false,
};

/// Whether [condition] counts visits (schema 4).
bool _usesVisits(Condition? condition) => switch (condition) {
  null => false,
  VisitCount() => true,
  All(:final conditions) ||
  Any(:final conditions) => conditions.any(_usesVisits),
  Not(:final condition) => _usesVisits(condition),
  _ => false,
};
