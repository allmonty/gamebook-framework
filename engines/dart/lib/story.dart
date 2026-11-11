import 'dart:convert';

import 'condition.dart';
import 'dice.dart';
import 'effect.dart';
import 'json_reader.dart';
import 'rules_spec.dart';
import 'text.dart';

export 'condition.dart';
export 'effect.dart';
export 'json_reader.dart' show StoryFormatException;
export 'rules_spec.dart';

/// The schema versions this engine can read.
const supportedSchemas = {1, 2, 3, 4, 5, 6, 7};

enum Ending { victory, death }

enum CheckOp { gte, lte }

/// A number in a check: a literal or the current value of a stat.
sealed class Operand {
  const Operand();

  factory Operand.fromJson(Object? json, String path) => switch (json) {
    final int n => Const(n),
    final String id => StatRef(checkId(id, path)),
    _ => throw StoryFormatException(path, 'expected an integer or a stat id'),
  };
}

class Const extends Operand {
  const Const(this.value);
  final int value;
}

class StatRef extends Operand {
  const StatRef(this.stat);
  final String stat;
}

enum UseWhen { story, combat }

enum CombatCost { round, free }

/// What happens when the player uses an item (schema 2). The item is removed
/// from the inventory by the engine. See spec/framework.md B5.
class ItemUse {
  const ItemUse({
    required this.effects,
    required this.when,
    this.combatCost = CombatCost.round,
  });

  factory ItemUse.fromJson(JsonObject obj) {
    final when = obj.list('when', (json, path) {
      final match = UseWhen.values.where((w) => w.name == json).firstOrNull;
      return match ??
          (throw StoryFormatException(path, 'expected "story" or "combat"'));
    });
    if (when.isEmpty) {
      throw obj.error('when', 'needs at least one of "story", "combat"');
    }
    final costName = obj.optString('combatCost');
    final cost = costName == null
        ? null
        : CombatCost.values.where((c) => c.name == costName).firstOrNull;
    if (costName != null) {
      if (cost == null) {
        throw obj.error('combatCost', 'expected "round" or "free"');
      }
      if (!when.contains(UseWhen.combat)) {
        throw obj.error(
          'combatCost',
          'only applies to items usable in "combat"',
        );
      }
    }
    final use = ItemUse(
      effects: obj.list('effects', Effect.fromJson),
      when: when.toSet(),
      combatCost: cost ?? CombatCost.round,
    );
    obj.finish();
    return use;
  }

  final List<Effect> effects;
  final Set<UseWhen> when;
  final CombatCost combatCost;
}

/// The value of a node's `music` that stops the music.
const stopMusic = 'stop';

/// A note the player unlocks through play and can reread (schema 5).
/// Something a player can earn, kept across games (schema 7, B15).
class Achievement {
  const Achievement({
    required this.title,
    this.description,
    this.hidden = false,
  });

  factory Achievement.fromJson(String _, Object? json, String path) {
    final obj = JsonObject(json, path);
    final achievement = Achievement(
      title: obj.string('title'),
      description: obj.optString('description'),
      hidden: obj.optBool('hidden'),
    );
    obj.finish();
    return achievement;
  }

  final String title;
  final String? description;

  /// Players see only that it exists until they earn it.
  final bool hidden;
}

class JournalEntry {
  const JournalEntry({required this.title, required this.text});

  factory JournalEntry.fromJson(String _, Object? json, String path) {
    final obj = JsonObject(json, path);
    final entry = JournalEntry(
      title: obj.string('title'),
      text: obj.string('text'),
    );
    obj.finish();
    return entry;
  }

  final String title;
  final String text;
}

/// A named group of pages, for authors and editors (schema 6, B13).
class Chapter {
  const Chapter({required this.title});

  factory Chapter.fromJson(String _, Object? json, String path) {
    final obj = JsonObject(json, path);
    final chapter = Chapter(title: obj.string('title'));
    obj.finish();
    return chapter;
  }

  final String title;
}

class Item {
  const Item({
    required this.name,
    this.description,
    this.image,
    this.use,
    this.capacity,
    this.bonus = const {},
  });

  factory Item.fromJson(String _, Object? json, String path) {
    final obj = JsonObject(json, path);
    final use = obj.optObject('use');
    final capacity = obj.optInt('capacity');
    if (capacity != null && capacity < 1) {
      throw obj.error('capacity', 'must be at least 1');
    }
    final item = Item(
      name: obj.string('name'),
      description: obj.optString('description'),
      image: obj.optString('image'),
      use: use == null ? null : ItemUse.fromJson(use),
      capacity: capacity,
      bonus: obj.idMap('bonus', (id, json, path) {
        if (json is! int) {
          throw StoryFormatException(path, 'expected an integer');
        }
        return json;
      }, optional: true),
    );
    obj.finish();
    return item;
  }

  final String name;
  final String? description;
  final String? image;

  /// Null for an item that is only held.
  final ItemUse? use;

  /// Extra pack slots while carried (a container, schema 3); it uses no slot.
  final int? capacity;

  /// Changes to stats while the item is in the pack (schema 5), by stat id.
  final Map<String, int> bonus;
}

class Check {
  const Check({
    required this.roll,
    this.add,
    required this.op,
    required this.vs,
    required this.pass,
    required this.fail,
    this.effects = const [],
  });

  factory Check.fromJson(JsonObject obj) {
    final opName = obj.string('op');
    final op = CheckOp.values.where((o) => o.name == opName).firstOrNull;
    if (op == null) throw obj.error('op', 'expected "gte" or "lte"');
    final add = obj.has('add')
        ? Operand.fromJson(obj.raw('add'), obj.childPath('add'))
        : null;
    final check = Check(
      roll: obj.string('roll'),
      add: add,
      op: op,
      vs: Operand.fromJson(obj.raw('vs'), obj.childPath('vs')),
      pass: checkId(obj.string('pass'), obj.childPath('pass')),
      fail: checkId(obj.string('fail'), obj.childPath('fail')),
      effects: obj.list('effects', Effect.fromJson, optional: true),
    );
    obj.finish();
    return check;
  }

  /// Dice notation, validated when rules are resolved (spec/framework.md B8).
  final String roll;
  final Operand? add;
  final CheckOp op;
  final Operand vs;
  final String pass;
  final String fail;
  final List<Effect> effects;
}

/// One result of a [RandomTable]: used when the roll is at most [upTo].
class TableOutcome {
  const TableOutcome({
    required this.upTo,
    required this.to,
    this.effects = const [],
  });

  factory TableOutcome.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final outcome = TableOutcome(
      upTo: obj.integer('upTo'),
      to: checkId(obj.string('to'), obj.childPath('to')),
      effects: obj.list('effects', Effect.fromJson, optional: true),
    );
    obj.finish();
    return outcome;
  }

  final int upTo;
  final String to;
  final List<Effect> effects;
}

/// Roll dice and pick the first outcome whose `upTo` is at least the total
/// (schema 4). See spec/framework.md B10.
class RandomTable {
  const RandomTable({required this.roll, required this.outcomes});

  factory RandomTable.fromJson(JsonObject obj) {
    final roll = obj.string('roll');
    final Dice dice;
    try {
      dice = Dice.parse(roll);
    } on FormatException catch (e) {
      throw obj.error('roll', e.message);
    }
    final outcomes = obj.list('outcomes', TableOutcome.fromJson);
    if (outcomes.isEmpty) throw obj.error('outcomes', 'needs at least one');
    for (var i = 1; i < outcomes.length; i++) {
      if (outcomes[i].upTo <= outcomes[i - 1].upTo) {
        throw StoryFormatException(
          '${obj.childPath('outcomes')}[$i].upTo',
          'must be greater than the one before (${outcomes[i - 1].upTo})',
        );
      }
    }
    if (outcomes.last.upTo < dice.max) {
      throw StoryFormatException(
        '${obj.childPath('outcomes')}[${outcomes.length - 1}].upTo',
        'must be at least ${dice.max}, the largest possible roll of $roll',
      );
    }
    obj.finish();
    return RandomTable(roll: roll, outcomes: outcomes);
  }

  final String roll;
  final List<TableOutcome> outcomes;

  /// The outcome for a rolled [total]; the last one if it is above them all.
  TableOutcome outcomeFor(int total) =>
      outcomes.firstWhere((o) => total <= o.upTo, orElse: () => outcomes.last);
}

class Choice {
  const Choice({
    required this.text,
    this.to,
    this.check,
    this.table,
    this.condition,
    this.effects = const [],
    this.hideIfLocked = false,
    this.lockedText,
    this.once = false,
  });

  factory Choice.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final check = obj.optObject('check');
    final table = obj.optObject('table');
    final to = obj.optString('to');
    if ([check, table, to].where((x) => x != null).length != 1) {
      throw StoryFormatException(
        path,
        'needs exactly one of "to", "check" or "table"',
      );
    }
    final choice = Choice(
      text: obj.string('text'),
      to: to == null ? null : checkId(to, obj.childPath('to')),
      check: check == null ? null : Check.fromJson(check),
      table: table == null ? null : RandomTable.fromJson(table),
      condition: obj.has('if')
          ? Condition.fromJson(obj.raw('if'), obj.childPath('if'))
          : null,
      effects: obj.list('effects', Effect.fromJson, optional: true),
      hideIfLocked: obj.optBool('hideIfLocked'),
      lockedText: obj.optString('lockedText'),
      once: obj.optBool('once'),
    );
    obj.finish();
    return choice;
  }

  final String text;
  final String? to;
  final Check? check;

  /// A random outcome table (schema 4).
  final RandomTable? table;
  final Condition? condition;
  final List<Effect> effects;
  final bool hideIfLocked;
  final String? lockedText;

  /// Gone for the rest of the game once taken (schema 4).
  final bool once;
}

class Enemy {
  const Enemy({
    required this.name,
    required this.attack,
    required this.health,
    this.defense,
    this.damage,
    this.armor = 0,
  });

  factory Enemy.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final enemy = Enemy(
      name: obj.string('name'),
      attack: obj.integer('attack'),
      health: obj.integer('health'),
      defense: obj.optInt('defense'),
      damage: obj.optString('damage'),
      armor: obj.optInt('armor') ?? 0,
    );
    obj.finish();
    if (enemy.armor < 0) throw obj.error('armor', 'must not be negative');
    return enemy;
  }

  final String name;
  final int attack;
  final int health;
  final int? defense;
  final String? damage;

  /// Taken off every wound the player deals to this enemy (schema 5).
  final int armor;
}

class Combat {
  const Combat({
    required this.enemies,
    required this.win,
    this.flee,
    this.simultaneous = false,
    this.duel = false,
  });

  factory Combat.fromJson(JsonObject obj) {
    final enemies = obj.list('enemies', Enemy.fromJson);
    if (enemies.isEmpty) throw obj.error('enemies', 'needs at least one enemy');
    final flee = obj.optString('flee');
    final combat = Combat(
      enemies: enemies,
      win: checkId(obj.string('win'), obj.childPath('win')),
      flee: flee == null ? null : checkId(flee, obj.childPath('flee')),
      simultaneous: obj.optBool('simultaneous'),
      duel: obj.optBool('duel'),
    );
    obj.finish();
    return combat;
  }

  final List<Enemy> enemies;
  final String win;
  final String? flee;

  /// All enemies fight at once and the player picks a target each round
  /// (schema 5).
  final bool simultaneous;

  /// Resolved by the results table of the rules instead of the combat mode
  /// (schema 5).
  final bool duel;
}

/// A paragraph of page text, shown only while [condition] holds (schema 4).
class TextPart {
  const TextPart(this.text, [this.condition]);

  factory TextPart.fromJson(Object? json, String path) {
    if (json is String) return TextPart(json);
    final obj = JsonObject(json, path);
    final part = TextPart(
      obj.string('text'),
      obj.has('if')
          ? Condition.fromJson(obj.raw('if'), obj.childPath('if'))
          : null,
    );
    obj.finish();
    return part;
  }

  final String text;
  final Condition? condition;
}

class Node {
  const Node({
    required this.id,
    required this.parts,
    this.textIsList = false,
    this.image,
    this.music,
    this.sound,
    this.effects = const [],
    this.once = false,
    this.choices = const [],
    this.combat,
    this.ending,
    this.title,
    this.note,
    this.chapter,
    this.draft = false,
  });

  factory Node.fromJson(String id, Object? json, String path) {
    final obj = JsonObject(json, path);
    final combat = obj.optObject('combat');
    final endingName = obj.optString('ending');
    final ending = endingName == null
        ? null
        : Ending.values.where((e) => e.name == endingName).firstOrNull;
    if (endingName != null && ending == null) {
      throw obj.error('ending', 'expected "victory" or "death"');
    }
    final choices = obj.list('choices', Choice.fromJson, optional: true);
    final draft = obj.optBool('draft');
    if (!draft &&
        [
              choices.isNotEmpty,
              combat != null,
              ending != null,
            ].where((present) => present).length !=
            1) {
      throw StoryFormatException(
        path,
        'needs exactly one of non-empty "choices", "combat" or "ending"',
      );
    }
    final rawText = obj.raw('text');
    final parts = switch (rawText) {
      final String text => [TextPart(text)],
      final List<Object?> list => [
        for (var i = 0; i < list.length; i++)
          TextPart.fromJson(list[i], '${obj.childPath('text')}[$i]'),
      ],
      null when draft => const <TextPart>[],
      null => throw obj.error('text', 'missing'),
      _ => throw obj.error('text', 'expected a string or a list of parts'),
    };
    if (parts.isEmpty && rawText != null) {
      throw obj.error('text', 'needs at least one part');
    }
    final title = obj.optString('title');
    if (title != null && title.trim().isEmpty) {
      throw obj.error('title', 'must not be empty');
    }
    final chapter = obj.optString('chapter');
    final node = Node(
      id: id,
      title: title,
      note: obj.optString('note'),
      draft: draft,
      chapter: chapter == null
          ? null
          : checkId(chapter, obj.childPath('chapter')),
      parts: parts,
      textIsList: rawText is List,
      image: obj.optString('image'),
      music: obj.optString('music'),
      sound: obj.optString('sound'),
      effects: obj.list('effects', Effect.fromJson, optional: true),
      once: obj.optBool('once'),
      choices: choices,
      combat: combat == null ? null : Combat.fromJson(combat),
      ending: ending,
    );
    obj.finish();
    return node;
  }

  final String id;

  /// The page text; every part is shown, or only those whose `if` holds.
  final List<TextPart> parts;

  /// Whether the story wrote `text` as a list (schema 4).
  final bool textIsList;
  final String? image;

  /// A music file that loops from this page on, or [stopMusic] (schema 5).
  final String? music;

  /// A sound played once when the page is entered (schema 5).
  final String? sound;
  final List<Effect> effects;
  final bool once;

  /// All the text of the page in one string, for tools that do not play it.
  String get text => parts.map((p) => p.text).join('\n\n');
  final List<Choice> choices;
  final Combat? combat;
  final Ending? ending;

  /// A short name for the page; players see it only with
  /// [Story.showTitles] (schema 6).
  final String? title;

  /// For authors only, never shown to players (schema 6).
  final String? note;

  /// The id of the chapter this page belongs to (schema 6).
  final String? chapter;

  /// Not written yet (schema 6): may lack text and a way out, and offers no
  /// choices, fight or ending when entered.
  final bool draft;
}

/// A whole story file. See spec/framework.md B3.
class Story {
  const Story({
    required this.schema,
    required this.id,
    required this.lang,
    required this.title,
    this.author,
    this.description,
    this.cover,
    required this.rules,
    required this.items,
    this.journal = const {},
    required this.start,
    required this.nodes,
    this.chapters = const {},
    this.showTitles = false,
    this.achievements = const {},
  });

  factory Story.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw StoryFormatException('', 'invalid JSON: ${e.message}');
    }
    return Story.fromJson(json);
  }

  factory Story.fromJson(Object? json) {
    final obj = JsonObject(json, '');
    final schema = obj.integer('schema');
    if (!supportedSchemas.contains(schema)) {
      throw obj.error('schema', 'unsupported schema version $schema');
    }
    obj.optString(r'$schema'); // editor hint for story.schema.json; not used
    final id = obj.string('id');
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw obj.error('id', 'expected a slug (lowercase letters, digits, "-")');
    }
    final usesShowTitles = obj.has('showTitles');
    final story = Story(
      schema: schema,
      chapters: obj.idMap('chapters', Chapter.fromJson, optional: true),
      achievements: obj.idMap(
        'achievements',
        Achievement.fromJson,
        optional: true,
      ),
      showTitles: obj.optBool('showTitles'),
      id: id,
      lang: obj.string('lang'),
      title: obj.string('title'),
      author: obj.optString('author'),
      description: obj.optString('description'),
      cover: obj.optString('cover'),
      rules: RulesSpec.fromJson(obj.object('rules')),
      items: obj.idMap('items', Item.fromJson, optional: true),
      journal: obj.idMap('journal', JournalEntry.fromJson, optional: true),
      start: checkId(obj.string('start'), obj.childPath('start')),
      nodes: obj.idMap('nodes', Node.fromJson),
    );
    obj.finish();
    if (schema < 2) {
      for (final MapEntry(:key, :value) in story.items.entries) {
        if (value.use != null) {
          throw StoryFormatException('items.$key.use', 'needs "schema": 2');
        }
      }
    }
    if (schema < 3) {
      final path = story._firstSchema3Feature();
      if (path != null) throw StoryFormatException(path, 'needs "schema": 3');
    }
    if (schema < 4) {
      final path = story._firstSchema4Feature();
      if (path != null) throw StoryFormatException(path, 'needs "schema": 4');
    } else {
      story._checkTemplates();
    }
    if (schema < 5) {
      final path = story._firstSchema5Feature();
      if (path != null) throw StoryFormatException(path, 'needs "schema": 5');
    }
    if (schema < 6) {
      final path = usesShowTitles ? 'showTitles' : story._firstSchema6Feature();
      if (path != null) throw StoryFormatException(path, 'needs "schema": 6');
    }
    if (schema < 7) {
      final path = story._firstSchema7Feature();
      if (path != null) throw StoryFormatException(path, 'needs "schema": 7');
    }
    for (final MapEntry(:key, :value) in story.nodes.entries) {
      if (value.chapter case final chapter?
          when !story.chapters.containsKey(chapter)) {
        throw StoryFormatException(
          'nodes.$key.chapter',
          'unknown chapter "$chapter"',
        );
      }
    }
    return story;
  }

  /// Where the story first uses something only schema 7 has, or null.
  String? _firstSchema7Feature() {
    if (achievements.isNotEmpty) return 'achievements';
    for (final (path, effects) in effectLists()) {
      final found = _findEffect(path, effects, (e) => e is Achieve);
      if (found != null) return found;
    }
    return null;
  }

  /// Every list of effects in the story with its JSON path: pages, choices,
  /// checks, table outcomes, items' use and creation picks.
  Iterable<(String, List<Effect>)> effectLists() sync* {
    for (final MapEntry(:key, :value) in items.entries) {
      if (value.use case final use?) {
        yield ('items.$key.use.effects', use.effects);
      }
    }
    final picks = rules.creation?.picks ?? const <PickGroup>[];
    for (var g = 0; g < picks.length; g++) {
      for (var o = 0; o < picks[g].options.length; o++) {
        yield (
          'rules.creation.picks[$g].options[$o].effects',
          picks[g].options[o].effects,
        );
      }
    }
    for (final MapEntry(:key, :value) in nodes.entries) {
      yield ('nodes.$key.effects', value.effects);
      for (var i = 0; i < value.choices.length; i++) {
        final at = 'nodes.$key.choices[$i]';
        final choice = value.choices[i];
        yield ('$at.effects', choice.effects);
        if (choice.check case final check?) {
          yield ('$at.check.effects', check.effects);
        }
        final outcomes = choice.table?.outcomes ?? const <TableOutcome>[];
        for (var j = 0; j < outcomes.length; j++) {
          yield ('$at.table.outcomes[$j].effects', outcomes[j].effects);
        }
      }
    }
  }

  /// Where the story first uses something only schema 6 has, or null.
  String? _firstSchema6Feature() {
    if (chapters.isNotEmpty) return 'chapters';
    for (final MapEntry(:key, :value) in nodes.entries) {
      if (value.title != null) return 'nodes.$key.title';
      if (value.note != null) return 'nodes.$key.note';
      if (value.chapter != null) return 'nodes.$key.chapter';
      if (value.draft) return 'nodes.$key.draft';
    }
    return null;
  }

  /// Where the story first uses something only schema 5 has, or null.
  String? _firstSchema5Feature() {
    if (rules.creation != null) return 'rules.creation';
    if (journal.isNotEmpty) return 'journal';
    for (final MapEntry(:key, :value) in nodes.entries) {
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
    for (final MapEntry(:key, :value) in items.entries) {
      if (value.bonus.isNotEmpty) return 'items.$key.bonus';
    }
    bool newEffect(Effect e) =>
        e is UnlockEntry ||
        e is StatChange && (e.replace || !e.amount.isConstant);
    for (final MapEntry(:key, :value) in items.entries) {
      final path = _findEffect(
        'items.$key.use.effects',
        value.use?.effects,
        newEffect,
      );
      if (path != null) return path;
    }
    for (final MapEntry(:key, :value) in nodes.entries) {
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
      final onNode = _findEffect('$at.effects', value.effects, newEffect);
      if (onNode != null) return onNode;
      for (var i = 0; i < value.choices.length; i++) {
        final choice = value.choices[i];
        if (_comparesStat(choice.condition)) return '$at.choices[$i].if';
        final found =
            _findEffect('$at.choices[$i].effects', choice.effects, newEffect) ??
            _findEffect(
              '$at.choices[$i].check.effects',
              choice.check?.effects,
              newEffect,
            );
        if (found != null) return found;
        final outcomes = choice.table?.outcomes ?? const [];
        for (var j = 0; j < outcomes.length; j++) {
          final inOutcome = _findEffect(
            '$at.choices[$i].table.outcomes[$j].effects',
            outcomes[j].effects,
            newEffect,
          );
          if (inOutcome != null) return inOutcome;
        }
      }
    }
    return null;
  }

  static String? _findEffect(
    String path,
    List<Effect>? effects,
    bool Function(Effect) test,
  ) {
    if (effects == null) return null;
    for (var i = 0; i < effects.length; i++) {
      if (test(effects[i])) return '$path[$i]';
    }
    return null;
  }

  /// Whether [condition] compares a stat with another stat (schema 5).
  static bool _comparesStat(Condition? condition) => switch (condition) {
    null => false,
    StatCompare(:final value) => !value.isConstant,
    All(:final conditions) ||
    Any(:final conditions) => conditions.any(_comparesStat),
    Not(:final condition) => _comparesStat(condition),
    _ => false,
  };

  /// Schema 4 text: every placeholder must be well formed.
  void _checkTemplates() {
    for (final MapEntry(:key, :value) in nodes.entries) {
      for (var i = 0; i < value.parts.length; i++) {
        checkTemplate(
          value.parts[i].text,
          value.textIsList ? 'nodes.$key.text[$i]' : 'nodes.$key.text',
        );
      }
      for (var i = 0; i < value.choices.length; i++) {
        checkTemplate(value.choices[i].text, 'nodes.$key.choices[$i].text');
      }
    }
  }

  /// Where the story first uses something only schema 4 has, or null.
  String? _firstSchema4Feature() {
    for (final MapEntry(:key, :value) in nodes.entries) {
      if (value.textIsList) return 'nodes.$key.text';
      for (var i = 0; i < value.choices.length; i++) {
        final choice = value.choices[i];
        if (choice.once) return 'nodes.$key.choices[$i].once';
        if (choice.table != null) return 'nodes.$key.choices[$i].table';
        if (_usesVisits(choice.condition)) {
          return 'nodes.$key.choices[$i].if';
        }
      }
    }
    return null;
  }

  static bool _usesVisits(Condition? condition) => switch (condition) {
    null => false,
    VisitCount() => true,
    All(:final conditions) ||
    Any(:final conditions) => conditions.any(_usesVisits),
    Not(:final condition) => _usesVisits(condition),
    _ => false,
  };

  /// Where the story first uses something only schema 3 has, or null.
  String? _firstSchema3Feature() {
    if (rules.inventory != null) return 'rules.inventory';
    for (final MapEntry(:key, :value) in items.entries) {
      if (value.capacity != null) return 'items.$key.capacity';
      final path = _takeAllIn('items.$key.use.effects', value.use?.effects);
      if (path != null) return path;
    }
    for (final MapEntry(:key, :value) in nodes.entries) {
      final at = 'nodes.$key';
      final path = _takeAllIn('$at.effects', value.effects);
      if (path != null) return path;
      for (var i = 0; i < value.choices.length; i++) {
        final choice = value.choices[i];
        final inChoice =
            _takeAllIn('$at.choices[$i].effects', choice.effects) ??
            _takeAllIn('$at.choices[$i].check.effects', choice.check?.effects);
        if (inChoice != null) return inChoice;
      }
    }
    return null;
  }

  static String? _takeAllIn(String path, List<Effect>? effects) {
    if (effects == null) return null;
    for (var i = 0; i < effects.length; i++) {
      if (effects[i] is TakeAll) return '$path[$i]';
    }
    return null;
  }

  /// The `schema` version the file declares; `{stat}` placeholders in text
  /// only mean something from version 4 on.
  final int schema;
  final String id;
  final String lang;
  final String title;
  final String? author;
  final String? description;
  final String? cover;
  final RulesSpec rules;
  final Map<String, Item> items;

  /// Notes the player can unlock, by id (schema 5).
  final Map<String, JournalEntry> journal;
  final String start;
  final Map<String, Node> nodes;

  /// Groups of pages, in reading order, by id (schema 6).
  final Map<String, Chapter> chapters;

  /// Whether players see each page's title as its heading (schema 6).
  final bool showTitles;

  /// Things a player can earn, by id (schema 7).
  final Map<String, Achievement> achievements;
}
