import 'dart:math';

import 'dice.dart';
import 'json_reader.dart';
import 'rules_spec.dart';
import 'state.dart';

class StatRules {
  const StatRules({
    required this.id,
    required this.label,
    required this.roll,
    required this.max,
    this.limit,
    this.min = 0,
  });

  final String id;
  final String label;
  final Dice roll;

  /// Whether the rolled value is also the ceiling.
  final bool max;

  /// A fixed ceiling instead (schema 5); never together with [max].
  final int? limit;

  /// The floor (schema 8), 0 unless the story says otherwise.
  final int min;
}

enum CombatMode {
  opposed('opposed'),
  vsDefense('vs-defense'),
  table('table');

  const CombatMode(this.json);
  final String json;
}

/// How big the pack is and what happens when something is found.
class InventoryRules {
  const InventoryRules({this.capacity, this.pickup = PickupMode.auto});

  /// Items that can be carried, not counting containers; null is unlimited.
  final int? capacity;
  final PickupMode pickup;
}

class CombatRules {
  const CombatRules({
    required this.mode,
    required this.attackRoll,
    required this.attackStat,
    required this.damage,
    this.defenseStat,
    this.defenseBase,
    this.luck,
    this.table = const [],
    this.tableRoll,
  });

  final CombatMode mode;
  final Dice attackRoll;
  final String attackStat;
  final Dice damage;

  /// Only for [CombatMode.vsDefense].
  final String? defenseStat;
  final int? defenseBase;

  /// Testing your Luck in a fight; null when the story has none (schema 5).
  final LuckRules? luck;

  /// The results by combat ratio: always in [CombatMode.table], where
  /// [attackRoll] is [tableRoll] and [damage] is not used; in the other modes
  /// only if the story gives a table for its duels (`duel: true` fights).
  final List<ResultsRow> table;

  /// The roll that picks a result of [table]; null when there is no table.
  final Dice? tableRoll;
}

/// [LuckSpec] checked: the stat exists and the roll is valid dice.
class LuckRules {
  const LuckRules({
    required this.stat,
    required this.roll,
    required this.lucky,
    required this.unlucky,
  });

  final String stat;
  final Dice roll;
  final LuckChange lucky;
  final LuckChange unlucky;
}

/// A story's rules after the preset and the story's overrides are merged and
/// checked. See spec/framework.md B4.
class Rules {
  const Rules({
    required this.stats,
    required this.health,
    required this.rerolls,
    this.combat,
    this.inventory = const InventoryRules(),
    this.creation,
    this.undo = 0,
  });

  /// Throws [StoryFormatException] naming the problem under `rules`.
  factory Rules.resolve(RulesSpec spec) {
    final preset = spec.preset == null ? null : _preset(spec.preset!);
    final stats = _mergeStats(preset?.stats ?? const {}, spec.stats);
    final health = spec.health ?? preset?.health;
    if (health == null) {
      throw const StoryFormatException('rules.health', 'missing');
    }
    if (!stats.any((s) => s.id == health)) {
      throw StoryFormatException('rules.health', 'unknown stat "$health"');
    }
    if (stats.firstWhere((s) => s.id == health).min != 0) {
      // Health at 0 is death (B4), so it has no other floor.
      throw StoryFormatException(
        'rules.stats.$health.min',
        'the health stat cannot have a min',
      );
    }
    final rerolls = spec.rerolls ?? preset?.rerolls ?? 0;
    if (rerolls < 0) {
      throw const StoryFormatException('rules.rerolls', 'must not be negative');
    }
    final undo = spec.undo ?? 0;
    if (undo < 0) {
      throw const StoryFormatException('rules.undo', 'must not be negative');
    }
    return Rules(
      stats: stats,
      health: health,
      rerolls: rerolls,
      combat: _combat(preset?.combat, spec.combat, stats),
      inventory: InventoryRules(
        capacity: spec.inventory?.capacity,
        pickup: spec.inventory?.pickup ?? PickupMode.auto,
      ),
      creation: spec.creation,
      undo: undo,
    );
  }

  final List<StatRules> stats;

  /// Id of the stat that means "alive"; at 0 the game ends in death.
  final String health;
  final int rerolls;

  /// Null when the story defines no combat rules.
  final CombatRules? combat;
  final InventoryRules inventory;

  /// The name and the pick groups of character creation, if any.
  final CreationSpec? creation;

  /// How many pages the player can go back; 0 means none (schema 5).
  final int undo;

  /// A fresh roll of every stat (character creation). Stats with a ceiling
  /// get the rolled value as their max.
  Map<String, StatValue> rollStats(Random random) => {
    for (final stat in stats)
      stat.id: _rolled(stat, stat.roll.roll(random).total),
  };

  static StatValue _rolled(StatRules stat, int rolled) {
    final value = max(rolled, stat.min);
    if (stat.limit != null) {
      return StatValue(min(value, stat.limit!), stat.limit, stat.min);
    }
    return StatValue(value, stat.max ? value : null, stat.min);
  }
}

const _presets = {
  'fighting-fantasy': RulesSpec(
    rerolls: 2,
    health: 'stamina',
    stats: {
      'skill': StatSpec(label: 'Skill', roll: '1d6+6', max: true),
      'stamina': StatSpec(label: 'Stamina', roll: '2d6+12', max: true),
      'luck': StatSpec(label: 'Luck', roll: '1d6+6', max: true),
    },
    combat: CombatSpec(
      mode: 'opposed',
      attackRoll: '2d6',
      attackStat: 'skill',
      damage: '2',
    ),
  ),
  'd20-lite': RulesSpec(
    rerolls: 2,
    health: 'hp',
    stats: {
      'might': StatSpec(label: 'Might', roll: '1d4', max: false),
      'agility': StatSpec(label: 'Agility', roll: '1d4', max: false),
      'wits': StatSpec(label: 'Wits', roll: '1d4', max: false),
      'hp': StatSpec(label: 'HP', roll: '2d6+8', max: true),
    },
    combat: CombatSpec(
      mode: 'vs-defense',
      attackRoll: '1d20',
      attackStat: 'might',
      defenseStat: 'agility',
      defenseBase: 10,
      damage: '1d6',
    ),
  ),
};

/// Names of the built-in presets.
Iterable<String> get presetNames => _presets.keys;

RulesSpec _preset(String name) =>
    _presets[name] ??
    (throw StoryFormatException('rules.preset', 'unknown preset "$name"'));

Dice _dice(String? source, String path) {
  if (source == null) throw StoryFormatException(path, 'missing');
  try {
    return Dice.parse(source);
  } on FormatException catch (e) {
    throw StoryFormatException(path, e.message);
  }
}

List<StatRules> _mergeStats(
  Map<String, StatSpec> base,
  Map<String, StatSpec> overrides,
) {
  final merged = <String, StatSpec>{
    for (final id in {...base.keys, ...overrides.keys})
      id: StatSpec(
        label: overrides[id]?.label ?? base[id]?.label,
        roll: overrides[id]?.roll ?? base[id]?.roll,
        // A story limit replaces a preset's "max" unless it says otherwise.
        max:
            overrides[id]?.max ??
            (overrides[id]?.limit != null ? false : base[id]?.max),
        limit: overrides[id]?.limit ?? base[id]?.limit,
        min: overrides[id]?.min ?? base[id]?.min,
      ),
  };
  if (merged.isEmpty) {
    throw const StoryFormatException('rules.stats', 'missing');
  }
  return [
    for (final MapEntry(:key, :value) in merged.entries)
      StatRules(
        id: key,
        label: value.label ?? key,
        roll: _dice(value.roll, 'rules.stats.$key.roll'),
        max: value.max ?? false,
        limit: _checkedLimit(key, value),
        min: _checkedMin(key, value),
      ),
  ];
}

int? _checkedLimit(String stat, StatSpec spec) {
  if (spec.limit != null && (spec.max ?? false)) {
    throw StoryFormatException(
      'rules.stats.$stat.limit',
      'cannot be combined with "max": true',
    );
  }
  return spec.limit;
}

int _checkedMin(String stat, StatSpec spec) {
  final floor = spec.min ?? 0;
  if (spec.limit != null && floor >= spec.limit!) {
    throw StoryFormatException(
      'rules.stats.$stat.min',
      'must be below the limit (${spec.limit})',
    );
  }
  return floor;
}

CombatRules? _combat(
  CombatSpec? base,
  CombatSpec? override,
  List<StatRules> stats,
) {
  if (base == null && override == null) return null;
  String? pick(String? Function(CombatSpec) field) =>
      (override == null ? null : field(override)) ??
      (base == null ? null : field(base));
  String stat(String key, String? id) {
    if (id == null) throw StoryFormatException('rules.combat.$key', 'missing');
    if (!stats.any((s) => s.id == id)) {
      throw StoryFormatException('rules.combat.$key', 'unknown stat "$id"');
    }
    return id;
  }

  final modeName = pick((c) => c.mode);
  final mode = CombatMode.values.where((m) => m.json == modeName).firstOrNull;
  if (mode == null) {
    throw StoryFormatException(
      'rules.combat.mode',
      modeName == null
          ? 'missing'
          : 'expected "opposed", "vs-defense" or "table", got "$modeName"',
    );
  }
  if (mode == CombatMode.table) return _tableCombat(base, override, stat);
  final vsDefense = mode == CombatMode.vsDefense;
  final defenseBase = override?.defenseBase ?? base?.defenseBase;
  if (vsDefense && defenseBase == null) {
    throw const StoryFormatException('rules.combat.defenseBase', 'missing');
  }
  // A table beside a normal mode is for the fights marked `duel`.
  final hasTable = (override?.table ?? base?.table) != null;
  if (!hasTable && (override?.roll ?? base?.roll) != null) {
    throw const StoryFormatException('rules.combat.table', 'missing');
  }
  final results = hasTable ? _results(base, override) : null;
  return CombatRules(
    mode: mode,
    attackRoll: _dice(pick((c) => c.attackRoll), 'rules.combat.attackRoll'),
    attackStat: stat('attackStat', pick((c) => c.attackStat)),
    damage: _dice(pick((c) => c.damage), 'rules.combat.damage'),
    defenseStat: vsDefense
        ? stat('defenseStat', pick((c) => c.defenseStat))
        : null,
    defenseBase: vsDefense ? defenseBase : null,
    luck: _luck(override?.luck ?? base?.luck, stats),
    table: results?.$2 ?? const [],
    tableRoll: results?.$1,
  );
}

LuckRules? _luck(LuckSpec? spec, List<StatRules> stats) {
  if (spec == null) return null;
  if (!stats.any((s) => s.id == spec.stat)) {
    throw StoryFormatException(
      'rules.combat.luck.stat',
      'unknown stat "${spec.stat}"',
    );
  }
  return LuckRules(
    stat: spec.stat,
    roll: _dice(spec.roll ?? '2d6', 'rules.combat.luck.roll'),
    lucky: spec.lucky,
    unlucky: spec.unlucky,
  );
}

/// The roll and the rows of a results table, checked: the roll can give 0
/// and nothing lower, the rows are ordered with `upTo` on all but the last,
/// and each has a result for every value of the roll.
(Dice, List<ResultsRow>) _results(CombatSpec? base, CombatSpec? override) {
  final roll = _dice(
    override?.roll ?? base?.roll ?? '1d10-1',
    'rules.combat.roll',
  );
  if (roll.min != 0) {
    throw StoryFormatException(
      'rules.combat.roll',
      'must be able to give 0 and nothing lower (like 1d10-1)',
    );
  }
  final table = override?.table ?? base?.table;
  if (table == null || table.isEmpty) {
    throw const StoryFormatException('rules.combat.table', 'missing');
  }
  for (var i = 0; i < table.length; i++) {
    final row = table[i];
    final last = i == table.length - 1;
    final at = 'rules.combat.table[$i]';
    if (last && row.upTo != null) {
      throw StoryFormatException('$at.upTo', 'the last row has no "upTo"');
    }
    if (!last && row.upTo == null) {
      throw StoryFormatException('$at.upTo', 'missing');
    }
    if (!last && i > 0 && row.upTo! <= table[i - 1].upTo!) {
      throw StoryFormatException(
        '$at.upTo',
        'must be higher than the row above',
      );
    }
    if (row.results.length != roll.max + 1) {
      throw StoryFormatException(
        '$at.results',
        'needs ${roll.max + 1} results, one for each value of $roll '
            '(got ${row.results.length})',
      );
    }
  }
  return (roll, table);
}

/// `table` mode: the roll picks a pair of losses from the row of the combat
/// ratio. Enemy defense and damage are not used.
CombatRules _tableCombat(
  CombatSpec? base,
  CombatSpec? override,
  String Function(String key, String? id) stat,
) {
  final (roll, table) = _results(base, override);
  if ((override?.luck ?? base?.luck) != null) {
    throw const StoryFormatException(
      'rules.combat.luck',
      'cannot be combined with "table" mode',
    );
  }
  return CombatRules(
    mode: CombatMode.table,
    attackRoll: roll,
    attackStat: stat('attackStat', override?.attackStat ?? base?.attackStat),
    damage: Dice.parse('0'),
    table: table,
    tableRoll: roll,
  );
}
