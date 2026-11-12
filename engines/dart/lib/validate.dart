import 'dice.dart';
import 'quantity.dart';
import 'rules.dart';
import 'story.dart';
import 'text.dart';

enum Severity { error, warning }

/// One problem found in a story. [where] is a JSON-style path.
class Issue {
  const Issue(this.severity, this.where, this.message, {this.code});

  final Severity severity;
  final String where;
  final String message;

  /// For warnings, what kind it is (spec B16, the same in every engine that
  /// claims the lint tier); null for errors.
  final String? code;

  @override
  String toString() => '${severity.name}: $where: $message';
}

/// Checks everything the parser cannot: cross-references, dice strings, rules
/// against the nodes that use them, reachability. [assetExists] takes a path
/// from the story (relative to its game folder); null skips the image checks.
List<Issue> validateStory(
  Story story, {
  bool Function(String path)? assetExists,
}) => _Validator(story, assetExists).run();

/// Warnings for where [other] (a translation) differs structurally from
/// [reference]: node ids, choice counts, item ids, stat ids, flags and chapters
/// (ids, and the chapter of each node) must match.
List<Issue> compareTranslations(Story reference, Story other) {
  final issues = <Issue>[];
  // [at] is where the id is declared (B16), so a tool can point at it.
  void diff(String what, String at, Set<String> a, Set<String> b) {
    for (final id in a.difference(b)) {
      issues.add(
        Issue(
          Severity.warning,
          '$at.$id',
          '$what "$id" exists in ${reference.lang} but not in ${other.lang}',
          code: 'translation-missing',
        ),
      );
    }
    for (final id in b.difference(a)) {
      issues.add(
        Issue(
          Severity.warning,
          '$at.$id',
          '$what "$id" exists in ${other.lang} but not in ${reference.lang}',
          code: 'translation-extra',
        ),
      );
    }
  }

  diff('node', 'nodes', reference.nodes.keys.toSet(), other.nodes.keys.toSet());
  diff('item', 'items', reference.items.keys.toSet(), other.items.keys.toSet());
  diff('stat', 'rules.stats', _statIds(reference), _statIds(other));
  diff(
    'journal entry',
    'journal',
    reference.journal.keys.toSet(),
    other.journal.keys.toSet(),
  );
  diff('flag', 'flags', _flags(reference), _flags(other));
  diff(
    'achievement',
    'achievements',
    reference.achievements.keys.toSet(),
    other.achievements.keys.toSet(),
  );
  diff(
    'chapter',
    'chapters',
    reference.chapters.keys.toSet(),
    other.chapters.keys.toSet(),
  );
  for (final id in reference.nodes.keys.toSet().intersection(
    other.nodes.keys.toSet(),
  )) {
    final textA = reference.nodes[id]!.parts.length;
    final textB = other.nodes[id]!.parts.length;
    if (textA != textB) {
      issues.add(
        Issue(
          Severity.warning,
          'nodes.$id',
          'has $textA text parts in ${reference.lang} but $textB in ${other.lang}',
          code: 'translation-text-parts',
        ),
      );
    }
    final chapterA = reference.nodes[id]!.chapter;
    final chapterB = other.nodes[id]!.chapter;
    if (chapterA != chapterB) {
      issues.add(
        Issue(
          Severity.warning,
          'nodes.$id',
          'is in chapter ${chapterA ?? 'none'} in ${reference.lang} but '
              '${chapterB ?? 'none'} in ${other.lang}',
          code: 'translation-chapter',
        ),
      );
    }
    final a = reference.nodes[id]!.choices.length;
    final b = other.nodes[id]!.choices.length;
    if (a != b) {
      issues.add(
        Issue(
          Severity.warning,
          'nodes.$id',
          'has $a choices in ${reference.lang} but $b in ${other.lang}',
          code: 'translation-choices',
        ),
      );
    }
  }
  return issues;
}

Set<String> _statIds(Story story) {
  try {
    return Rules.resolve(story.rules).stats.map((s) => s.id).toSet();
  } on StoryFormatException {
    return story.rules.stats.keys.toSet();
  }
}

Set<String> _flags(Story story) {
  final v = _Validator(story, null)..run();
  return {...v.flagsSet, ...v.flagsRead.keys};
}

class _Validator {
  _Validator(this.story, this.assetExists);

  final Story story;
  final bool Function(String path)? assetExists;
  final issues = <Issue>[];
  Rules? rules;

  final itemsGiven = <String>{};
  final usableItems = <String>{};
  final itemsTaken = <String, String>{};
  final itemsRequired = <String, String>{};
  final flagsSet = <String>{};
  final flagsRead = <String, String>{};
  final entriesUnlocked = <String>{};
  final achievementsEarned = <String>{};

  void error(String where, String message) =>
      issues.add(Issue(Severity.error, where, message));

  void warn(String where, String code, String message) =>
      issues.add(Issue(Severity.warning, where, message, code: code));

  List<Issue> run() {
    try {
      rules = Rules.resolve(story.rules);
    } on StoryFormatException catch (e) {
      error(e.path, e.message);
    }
    if (!story.nodes.containsKey(story.start)) {
      error('start', 'unknown node "${story.start}"');
    }
    _creation();
    _image('cover', story.cover);
    for (final MapEntry(:key, :value) in story.items.entries) {
      _image('items.$key.image', value.image);
      if (value.capacity != null && rules?.inventory.capacity == null) {
        warn(
          'items.$key.capacity',
          'capacity-without-pack',
          'adds pack room but the story has no inventory capacity',
        );
      }
      for (final stat in value.bonus.keys) {
        _stat('items.$key.bonus.$stat', stat);
        if (stat == rules?.health) {
          error(
            'items.$key.bonus.$stat',
            'a bonus to the health stat is not allowed',
          );
        }
      }
      if (value.use case final use?) {
        _effects('items.$key.use.effects', use.effects);
        usableItems.add(key);
      }
    }
    for (final MapEntry(:key, :value) in story.nodes.entries) {
      _node(key, value);
    }
    _summaries();
    _reachability();
    return issues;
  }

  /// The effects of creation picks are checked like any other.
  void _creation() {
    final creation = story.rules.creation;
    if (creation == null) return;
    if (creation.name && (rules?.stats.any((s) => s.id == 'name') ?? false)) {
      error(
        'rules.creation.name',
        'a stat called "name" would be shadowed by {name}',
      );
    }
    for (var g = 0; g < creation.picks.length; g++) {
      for (var o = 0; o < creation.picks[g].options.length; o++) {
        _effects(
          'rules.creation.picks[$g].options[$o].effects',
          creation.picks[g].options[o].effects,
        );
      }
    }
  }

  void _image(String where, String? path) {
    if (path != null && assetExists != null && !assetExists!(path)) {
      error(where, 'image file not found: $path');
    }
  }

  void _file(String where, String path, String what) {
    if (assetExists != null && !assetExists!(path)) {
      error(where, '$what file not found: $path');
    }
  }

  void _target(String where, String id) {
    if (!story.nodes.containsKey(id)) error(where, 'unknown node "$id"');
  }

  void _item(String where, String id) {
    if (!story.items.containsKey(id)) error(where, 'unknown item "$id"');
  }

  void _stat(String where, String id) {
    final known = rules?.stats.any((s) => s.id == id);
    if (known == false) error(where, 'unknown stat "$id"');
  }

  void _dice(String where, String source) {
    try {
      Dice.parse(source);
    } on FormatException catch (e) {
      error(where, e.message);
    }
  }

  void _quantity(String where, Quantity quantity) {
    if (quantity.stat case final stat?) _stat(where, stat);
  }

  void _operand(String where, Operand? operand) {
    if (operand case StatRef(:final stat)) _stat(where, stat);
  }

  void _node(String id, Node node) {
    final at = 'nodes.$id';
    if (node.draft) warn(at, 'draft', 'draft page, not written yet');
    _image('$at.image', node.image);
    if (node.music != null && node.music != stopMusic) {
      _file('$at.music', node.music!, 'music');
    }
    if (node.sound != null) _file('$at.sound', node.sound!, 'sound');
    for (var i = 0; i < node.parts.length; i++) {
      final part = node.parts[i];
      final here = node.textIsList ? '$at.text[$i]' : '$at.text';
      if (part.condition case final condition?) {
        _condition('$here.if', condition);
      }
      _placeholders(here, part.text);
    }
    _effects('$at.effects', node.effects);
    for (var i = 0; i < node.choices.length; i++) {
      _choice('$at.choices[$i]', node.choices[i]);
    }
    if (node.combat case final combat?) _combat('$at.combat', combat);
  }

  /// Schema 4 text: every `{stat}` must name a stat of the story.
  void _placeholders(String where, String text) {
    if (story.schema < 4) return;
    for (final stat in placeholderStats(text)) {
      // {name} is the hero's name when the story asks for one.
      if (stat == 'name' && (story.rules.creation?.name ?? false)) continue;
      _stat(where, stat);
    }
  }

  void _choice(String at, Choice choice) {
    _placeholders('$at.text', choice.text);
    if (choice.to case final to?) _target('$at.to', to);
    if (choice.condition case final condition?) {
      _condition('$at.if', condition);
    }
    _effects('$at.effects', choice.effects);
    if (choice.table case final table?) {
      for (var i = 0; i < table.outcomes.length; i++) {
        final outcome = table.outcomes[i];
        _target('$at.table.outcomes[$i].to', outcome.to);
        _effects('$at.table.outcomes[$i].effects', outcome.effects);
      }
    }
    if (choice.check case final check?) {
      _dice('$at.check.roll', check.roll);
      _operand('$at.check.add', check.add);
      _operand('$at.check.vs', check.vs);
      _target('$at.check.pass', check.pass);
      _target('$at.check.fail', check.fail);
      _effects('$at.check.effects', check.effects);
    }
  }

  void _combat(String at, Combat combat) {
    _target('$at.win', combat.win);
    if (combat.flee case final flee?) _target('$at.flee', flee);
    if (combat.wounded case final wounded?) _target('$at.wounded', wounded);
    if (combat.rounds case final rounds?) _target('$at.rounds.to', rounds.to);
    final rulesCombat = rules?.combat;
    if (rules != null && rulesCombat == null) {
      error(at, 'the story has a fight but its rules define no combat');
    }
    if (combat.simultaneous &&
        (combat.duel || rulesCombat?.mode == CombatMode.table)) {
      error(
        '$at.simultaneous',
        'a results table cannot be used against a group',
      );
    }
    if (combat.duel && (rulesCombat?.table.isEmpty ?? false)) {
      error('$at.duel', 'needs a results table in rules.combat');
    }
    for (var i = 0; i < combat.enemies.length; i++) {
      final enemy = combat.enemies[i];
      final here = '$at.enemies[$i]';
      if (enemy.health < 1) error('$here.health', 'must be at least 1');
      if (enemy.damage case final damage?) _dice('$here.damage', damage);
      if (rulesCombat?.mode == CombatMode.vsDefense && enemy.defense == null) {
        error(
          '$here.defense',
          'missing: "${enemy.name}" needs a defense (vs-defense combat)',
        );
      }
    }
  }

  void _condition(String at, Condition condition) {
    switch (condition) {
      case HasItem(:final item):
        _item(at, item);
        itemsRequired.putIfAbsent(item, () => at);
      case FlagSet(:final flag):
        flagsRead.putIfAbsent(flag, () => at);
      case Visited(:final node) || VisitCount(:final node):
        _target(at, node);
      case StatCompare(:final stat, :final value):
        _stat(at, stat);
        _quantity(at, value);
      case All(:final conditions) || Any(:final conditions):
        for (final c in conditions) {
          _condition(at, c);
        }
      case Not(:final condition):
        _condition(at, condition);
    }
  }

  void _effects(String at, List<Effect> effects) {
    for (var i = 0; i < effects.length; i++) {
      final here = '$at[$i]';
      switch (effects[i]) {
        case GiveItem(:final item):
          _item(here, item);
          itemsGiven.add(item);
        case TakeItem(:final item):
          _item(here, item);
          itemsTaken.putIfAbsent(item, () => here);
        case StatChange(:final stat, :final amount):
          _stat(here, stat);
          _quantity(here, amount);
        case SetFlag(:final flag):
          flagsSet.add(flag);
        case Achieve(:final achievement):
          if (!story.achievements.containsKey(achievement)) {
            error(here, 'unknown achievement "$achievement"');
          }
          achievementsEarned.add(achievement);
        case UnlockEntry(:final entry):
          if (!story.journal.containsKey(entry)) {
            error(here, 'unknown journal entry "$entry"');
          }
          entriesUnlocked.add(entry);
        case ClearFlag() || TakeAll():
          break;
      }
    }
  }

  void _summaries() {
    for (final id in story.achievements.keys) {
      if (!achievementsEarned.contains(id)) {
        warn('achievements.$id', 'never-earned', 'is never earned');
      }
    }
    for (final MapEntry(:key, :value) in itemsRequired.entries) {
      if (!itemsGiven.contains(key)) {
        warn(
          value,
          'required-never-given',
          'item "$key" is required but never given',
        );
      }
    }
    for (final item in usableItems.difference(itemsGiven)) {
      warn('items.$item', 'usable-never-given', 'is usable but never given');
    }
    for (final MapEntry(:key, :value) in itemsTaken.entries) {
      if (!itemsGiven.contains(key)) {
        warn(
          value,
          'taken-never-given',
          'item "$key" is taken but never given',
        );
      }
    }
    for (final MapEntry(:key, :value) in flagsRead.entries) {
      if (!flagsSet.contains(key)) {
        warn(value, 'flag-never-set', 'flag "$key" is checked but never set');
      }
    }
    for (final entry in story.journal.keys) {
      if (!entriesUnlocked.contains(entry)) {
        warn('journal.$entry', 'journal-never-unlocked', 'is never unlocked');
      }
    }
    for (final flag in flagsSet.difference(flagsRead.keys.toSet())) {
      warn('flags.$flag', 'flag-never-checked', 'is set but never checked');
    }
  }

  void _reachability() {
    if (!story.nodes.containsKey(story.start)) return;
    final seen = <String>{story.start};
    final queue = [story.start];
    while (queue.isNotEmpty) {
      final node = story.nodes[queue.removeLast()]!;
      for (final next in [
        for (final c in node.choices) ...[
          ?c.to,
          if (c.check != null) ...[c.check!.pass, c.check!.fail],
          if (c.table != null) ...[for (final o in c.table!.outcomes) o.to],
        ],
        ?node.combat?.win,
        ?node.combat?.flee,
        ?node.combat?.wounded,
        ?node.combat?.rounds?.to,
      ]) {
        if (story.nodes.containsKey(next) && seen.add(next)) queue.add(next);
      }
    }
    for (final id in story.nodes.keys.where((id) => !seen.contains(id))) {
      warn('nodes.$id', 'unreachable', 'is unreachable from the start');
    }
    final reachableEndings = seen
        .map((id) => story.nodes[id]!.ending)
        .whereType<Ending>();
    if (!reachableEndings.contains(Ending.victory)) {
      warn('nodes', 'no-victory', 'no victory ending is reachable');
    }
  }
}
