import 'dart:math';

/// A stat's current value and its ceiling, if it has one.
class StatValue {
  const StatValue(this.value, [this.max]);

  factory StatValue.fromJson(Object? json) {
    if (json is Map<String, Object?> &&
        json['value'] is int &&
        (json['max'] == null || json['max'] is int)) {
      return StatValue(json['value']! as int, json['max'] as int?);
    }
    throw const FormatException('state: bad stat');
  }

  final int value;
  final int? max;

  /// The stat set to [next], kept within `0..max`.
  StatValue clampedTo(int next) =>
      StatValue(next < 0 ? 0 : (max != null && next > max! ? max! : next), max);

  /// [value] plus [delta], kept within `0..max`.
  StatValue adjusted(int delta) => clampedTo(value + delta);

  Map<String, Object?> toJson() => {'value': value, 'max': max};
}

/// Progress through the current fight. See spec/framework.md B11.
class CombatState {
  const CombatState(this.enemy, this.enemyHealth, [this.luck]);

  factory CombatState.fromJson(Object? json) {
    if (json is Map<String, Object?> &&
        json['enemy'] is int &&
        json['health'] is List<Object?> &&
        (json['health']! as List<Object?>).every((h) => h is int)) {
      return CombatState(
        json['enemy']! as int,
        (json['health']! as List<Object?>).cast<int>(),
        json['luck'] == null ? null : LuckChance.fromJson(json['luck']),
      );
    }
    throw const FormatException('state: bad combat');
  }

  /// Index of the enemy being fought.
  final int enemy;

  /// Current health of every enemy, in story order.
  final List<int> enemyHealth;

  /// The wounds of the last round, while the player may still test luck on
  /// them (schema 5); null otherwise.
  final LuckChance? luck;

  Map<String, Object?> toJson() => {
    'enemy': enemy,
    'health': enemyHealth,
    if (luck != null) 'luck': luck!.toJson(),
  };
}

/// What a luck test in a fight would change: the wound dealt to enemy
/// [enemy] and the wound taken, as they stand after the last round.
class LuckChance {
  const LuckChance({
    required this.enemy,
    required this.dealt,
    required this.taken,
  });

  factory LuckChance.fromJson(Object? json) {
    if (json is Map<String, Object?> &&
        json['enemy'] is int &&
        json['dealt'] is int &&
        json['taken'] is int) {
      return LuckChance(
        enemy: json['enemy']! as int,
        dealt: json['dealt']! as int,
        taken: json['taken']! as int,
      );
    }
    throw const FormatException('state: bad luck chance');
  }

  final int enemy;
  final int dealt;
  final int taken;

  Map<String, Object?> toJson() => {
    'enemy': enemy,
    'dealt': dealt,
    'taken': taken,
  };
}

/// Everything that changes while playing; the unit that is saved.
class GameState {
  const GameState({
    required this.node,
    this.stats = const {},
    this.inventory = const {},
    this.flags = const {},
    this.visited = const {},
    this.combat,
    this.offers = const [],
    this.taken = const {},
    this.visits = const {},
    this.statBonus = const {},
    this.name,
    this.journal = const [],
    this.music,
  });

  /// Throws [FormatException] if [json] is not a state this version wrote.
  factory GameState.fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['node'] is! String) {
      throw const FormatException('state: bad node');
    }
    final stats = json['stats'];
    if (stats is! Map<String, Object?>) {
      throw const FormatException('state: bad stats');
    }
    return GameState(
      node: json['node']! as String,
      stats: {
        for (final entry in stats.entries)
          entry.key: StatValue.fromJson(entry.value),
      },
      inventory: _strings(json['inventory']),
      flags: _strings(json['flags']),
      visited: _strings(json['visited']),
      combat: json['combat'] == null
          ? null
          : CombatState.fromJson(json['combat']),
      // Saves from before offers existed have none.
      offers: json['offers'] == null
          ? const []
          : _strings(json['offers']).toList(),
      taken: json['taken'] == null ? const {} : _strings(json['taken']),
      visits: _visits(json['visits'], _strings(json['visited'])),
      name: json['name'] is String ? json['name']! as String : null,
      music: json['music'] is String ? json['music']! as String : null,
      journal: json['journal'] == null
          ? const []
          : _strings(json['journal']).toList(),
    );
  }

  /// Counts of entries per node. Saves from before counting have only the set
  /// of visited nodes, which counts as one visit each.
  static Map<String, int> _visits(Object? json, Set<String> visited) {
    if (json == null) return {for (final node in visited) node: 1};
    if (json is Map<String, Object?> && json.values.every((v) => v is int)) {
      return json.cast<String, int>();
    }
    throw const FormatException('state: bad visits');
  }

  static Set<String> _strings(Object? json) {
    if (json is List<Object?> && json.every((e) => e is String)) {
      return json.cast<String>().toSet();
    }
    throw const FormatException('state: expected a list of strings');
  }

  final String node;
  final Map<String, StatValue> stats;

  /// Items held, in pickup order.
  final Set<String> inventory;
  final Set<String> flags;
  final Set<String> visited;
  final CombatState? combat;

  /// Items found that the player has not yet taken or left, in the order
  /// they were found (`pickup: "choose"`).
  final List<String> offers;

  /// `<node>#<index>` of every once-only choice already taken.
  final Set<String> taken;

  /// How many times each node was entered.
  final Map<String, int> visits;

  int visitsTo(String node) => visits[node] ?? 0;

  /// Bonuses to stats from items in the pack, by stat id. Derived by the
  /// engine from the story's items; not part of the saved state.
  final Map<String, int> statBonus;

  /// The hero's name, when the story asks for one (schema 5).
  final String? name;

  /// Ids of the journal entries unlocked, oldest first (schema 5).
  final List<String> journal;

  /// The music file now playing, if any (schema 5); kept in the save so a
  /// resumed game picks it up again.
  final String? music;

  /// The stat's value now: what it is plus the bonuses of carried items,
  /// never below 0 (B5).
  int stat(String id) => max(0, (stats[id]?.value ?? 0) + (statBonus[id] ?? 0));

  /// The bonus carried items give to [id] (0 if none).
  int bonusOf(String id) => statBonus[id] ?? 0;

  GameState copyWith({
    String? node,
    Map<String, StatValue>? stats,
    Set<String>? inventory,
    Set<String>? flags,
    Set<String>? visited,
    List<String>? offers,
    Set<String>? taken,
    Map<String, int>? visits,
    Map<String, int>? statBonus,
    String? name,
    List<String>? journal,
    String? music,
    bool stopMusic = false,
    CombatState? combat,
    bool endCombat = false,
  }) => GameState(
    node: node ?? this.node,
    stats: stats ?? this.stats,
    inventory: inventory ?? this.inventory,
    flags: flags ?? this.flags,
    visited: visited ?? this.visited,
    combat: endCombat ? null : combat ?? this.combat,
    offers: offers ?? this.offers,
    taken: taken ?? this.taken,
    visits: visits ?? this.visits,
    statBonus: statBonus ?? this.statBonus,
    name: name ?? this.name,
    journal: journal ?? this.journal,
    music: stopMusic ? null : music ?? this.music,
  );

  /// Starts, updates or (with null) ends the current fight.
  GameState withCombat(CombatState? combat) =>
      copyWith(combat: combat, endCombat: combat == null);

  /// The same state with item bonuses to stats (never saved, always derived
  /// from the pack).
  GameState withBonus(Map<String, int> bonus) => copyWith(statBonus: bonus);

  Map<String, Object?> toJson() => {
    'node': node,
    'stats': {for (final e in stats.entries) e.key: e.value.toJson()},
    'inventory': inventory.toList(),
    'flags': flags.toList(),
    'visited': visited.toList(),
    'combat': combat?.toJson(),
    'offers': offers,
    'taken': taken.toList(),
    'visits': visits,
    'name': name,
    'journal': journal,
    'music': music,
  };
}
