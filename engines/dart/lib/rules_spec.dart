import 'condition.dart';
import 'effect.dart';
import 'json_reader.dart';

/// What `give` does: add the item at once, or let the player decide.
enum PickupMode { auto, choose }

/// The `rules.inventory` block as written (schema 3).
class InventorySpec {
  const InventorySpec({this.capacity, this.pickup});

  factory InventorySpec.fromJson(JsonObject obj) {
    final capacity = obj.optInt('capacity');
    if (capacity != null && capacity < 1) {
      throw obj.error('capacity', 'must be at least 1');
    }
    final pickupName = obj.optString('pickup');
    final pickup = pickupName == null
        ? null
        : PickupMode.values.where((m) => m.name == pickupName).firstOrNull;
    if (pickupName != null && pickup == null) {
      throw obj.error('pickup', 'expected "auto" or "choose"');
    }
    obj.finish();
    return InventorySpec(capacity: capacity, pickup: pickup);
  }

  /// Null means unlimited.
  final int? capacity;
  final PickupMode? pickup;
}

/// The `rules` block exactly as written in a story: every field optional
/// because a preset may supply it. Resolved against presets in rules.dart.
class RulesSpec {
  const RulesSpec({
    this.preset,
    this.rerolls,
    this.health,
    this.stats = const {},
    this.combat,
    this.inventory,
    this.creation,
    this.undo,
    this.bonuses = const [],
  });

  factory RulesSpec.fromJson(JsonObject obj) {
    final combat = obj.optObject('combat');
    final inventory = obj.optObject('inventory');
    final creation = obj.optObject('creation');
    final spec = RulesSpec(
      preset: obj.optString('preset'),
      rerolls: obj.optInt('rerolls'),
      health: obj.optString('health'),
      stats: obj.idMap('stats', StatSpec.fromJson, optional: true),
      combat: combat == null ? null : CombatSpec.fromJson(combat),
      inventory: inventory == null ? null : InventorySpec.fromJson(inventory),
      creation: creation == null ? null : CreationSpec.fromJson(creation),
      undo: obj.optInt('undo'),
      bonuses: obj.list('bonuses', RuleBonus.fromJson, optional: true),
    );
    obj.finish();
    return spec;
  }

  final String? preset;
  final int? rerolls;
  final String? health;
  final Map<String, StatSpec> stats;
  final CombatSpec? combat;
  final InventorySpec? inventory;

  /// What the player decides when making the character (schema 5).
  final CreationSpec? creation;

  /// How many pages the player can go back (schema 5); null means none.
  final int? undo;

  /// Bonuses that apply while a condition holds (schema 8, B5).
  final List<RuleBonus> bonuses;
}

/// A bonus to stats while [condition] holds, like an item's (schema 8).
class RuleBonus {
  const RuleBonus(this.condition, this.bonus);

  factory RuleBonus.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final rule = RuleBonus(
      Condition.fromJson(obj.raw('if'), obj.childPath('if')),
      obj.idMap('bonus', (_, json, path) {
        if (json is! int) {
          throw StoryFormatException(path, 'expected an integer');
        }
        return json;
      }),
    );
    obj.finish();
    return rule;
  }

  final Condition condition;

  /// By stat id.
  final Map<String, int> bonus;
}

/// The `rules.creation` block: whether the hero has a name, and groups of
/// options the player picks from. See spec/framework.md B4.
class CreationSpec {
  const CreationSpec({this.name = false, this.picks = const []});

  factory CreationSpec.fromJson(JsonObject obj) {
    final spec = CreationSpec(
      name: obj.optBool('name'),
      picks: obj.list('picks', PickGroup.fromJson, optional: true),
    );
    obj.finish();
    final ids = <String>{};
    for (var i = 0; i < spec.picks.length; i++) {
      if (!ids.add(spec.picks[i].id)) {
        throw StoryFormatException(
          '${obj.childPath('picks')}[$i].id',
          'duplicate group id "${spec.picks[i].id}"',
        );
      }
    }
    return spec;
  }

  /// Whether the player names the hero (`{name}` in text).
  final bool name;
  final List<PickGroup> picks;
}

/// "Choose [count] of these": a group of options at character creation.
class PickGroup {
  const PickGroup({
    required this.id,
    required this.title,
    required this.count,
    required this.options,
  });

  factory PickGroup.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final group = PickGroup(
      id: checkId(obj.string('id'), obj.childPath('id')),
      title: obj.string('title'),
      count: obj.integer('count'),
      options: obj.list('options', PickOption.fromJson),
    );
    obj.finish();
    if (group.options.isEmpty) {
      throw StoryFormatException('$path.options', 'needs at least one option');
    }
    if (group.count < 1 || group.count > group.options.length) {
      throw StoryFormatException(
        '$path.count',
        'must be between 1 and the number of options (${group.options.length})',
      );
    }
    final ids = <String>{};
    for (var i = 0; i < group.options.length; i++) {
      if (!ids.add(group.options[i].id)) {
        throw StoryFormatException(
          '$path.options[$i].id',
          'duplicate option id "${group.options[i].id}"',
        );
      }
    }
    return group;
  }

  final String id;
  final String title;
  final int count;
  final List<PickOption> options;
}

class PickOption {
  const PickOption({
    required this.id,
    required this.label,
    this.description,
    this.effects = const [],
  });

  factory PickOption.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final option = PickOption(
      id: checkId(obj.string('id'), obj.childPath('id')),
      label: obj.string('label'),
      description: obj.optString('description'),
      effects: obj.list('effects', Effect.fromJson, optional: true),
    );
    obj.finish();
    return option;
  }

  final String id;
  final String label;
  final String? description;

  /// Applied at the start of the game if the player picks this option.
  final List<Effect> effects;
}

class StatSpec {
  const StatSpec({this.label, this.roll, this.max, this.limit, this.min});

  factory StatSpec.fromJson(String _, Object? json, String path) {
    final obj = JsonObject(json, path);
    final spec = StatSpec(
      label: obj.optString('label'),
      roll: obj.optString('roll'),
      max: obj.has('max') ? obj.optBool('max') : null,
      limit: obj.optInt('limit'),
      min: obj.optInt('min'),
    );
    if (spec.limit != null && spec.limit! < 1) {
      throw obj.error('limit', 'must be at least 1');
    }
    obj.finish();
    return spec;
  }

  final String? label;
  final String? roll;
  final bool? max;

  /// A ceiling independent of the roll (schema 5).
  final int? limit;

  /// The floor (schema 8), which may be negative; null is 0.
  final int? min;
}

class CombatSpec {
  const CombatSpec({
    this.mode,
    this.attackRoll,
    this.attackStat,
    this.defenseStat,
    this.defenseBase,
    this.damage,
    this.luck,
    this.roll,
    this.table,
  });

  factory CombatSpec.fromJson(JsonObject obj) {
    final luck = obj.optObject('luck');
    final spec = CombatSpec(
      mode: obj.optString('mode'),
      attackRoll: obj.optString('attackRoll'),
      attackStat: obj.optString('attackStat'),
      defenseStat: obj.optString('defenseStat'),
      defenseBase: obj.optInt('defenseBase'),
      damage: obj.optString('damage'),
      luck: luck == null ? null : LuckSpec.fromJson(luck),
      roll: obj.optString('roll'),
      table: obj.has('table') ? obj.list('table', ResultsRow.fromJson) : null,
    );
    obj.finish();
    return spec;
  }

  final String? mode;
  final String? attackRoll;
  final String? attackStat;
  final String? defenseStat;
  final int? defenseBase;
  final String? damage;

  /// Testing your Luck in a fight (schema 5).
  final LuckSpec? luck;

  /// Dice notation for `table` mode; null means `1d10-1`.
  final String? roll;

  /// The results of `table` mode, one row per band of combat ratio.
  final List<ResultsRow>? table;
}

/// One row of a combat results table: for ratios up to [upTo] (the last row,
/// with no [upTo], takes everything above), the health points `[enemy,
/// player]` lose for each value of the roll. See spec/framework.md B11.
class ResultsRow {
  const ResultsRow({this.upTo, required this.results});

  factory ResultsRow.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    final row = ResultsRow(
      upTo: obj.optInt('upTo'),
      results: obj.list('results', _pair),
    );
    obj.finish();
    return row;
  }

  static (int, int) _pair(Object? json, String path) {
    if (json is List<Object?> &&
        json.length == 2 &&
        json[0] is int &&
        json[1] is int) {
      return (json[0]! as int, json[1]! as int);
    }
    throw StoryFormatException(path, 'expected [enemy loss, player loss]');
  }

  final int? upTo;

  /// Indexed by the roll's total.
  final List<(int, int)> results;
}

/// `rules.combat.luck`: which stat is spent and what luck does to a wound.
/// The defaults are Fighting Fantasy's. See spec/framework.md B4.
class LuckSpec {
  const LuckSpec({
    required this.stat,
    this.roll,
    this.lucky = const LuckChange(dealt: 2, taken: -1),
    this.unlucky = const LuckChange(dealt: -1, taken: 1),
  });

  factory LuckSpec.fromJson(JsonObject obj) {
    final lucky = obj.optObject('lucky');
    final unlucky = obj.optObject('unlucky');
    final spec = LuckSpec(
      stat: checkId(obj.string('stat'), obj.childPath('stat')),
      roll: obj.optString('roll'),
      lucky: lucky == null
          ? const LuckChange(dealt: 2, taken: -1)
          : LuckChange.fromJson(lucky, 2, -1),
      unlucky: unlucky == null
          ? const LuckChange(dealt: -1, taken: 1)
          : LuckChange.fromJson(unlucky, -1, 1),
    );
    obj.finish();
    return spec;
  }

  final String stat;

  /// Dice notation; null means `2d6`.
  final String? roll;
  final LuckChange lucky;
  final LuckChange unlucky;
}

/// How a luck test changes the wound the player dealt and the one it took.
class LuckChange {
  const LuckChange({required this.dealt, required this.taken});

  factory LuckChange.fromJson(JsonObject obj, int dealt, int taken) {
    final change = LuckChange(
      dealt: obj.optInt('dealt') ?? dealt,
      taken: obj.optInt('taken') ?? taken,
    );
    obj.finish();
    return change;
  }

  final int dealt;
  final int taken;
}
