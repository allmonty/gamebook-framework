import 'dart:math';

/// A stat's current value, its ceiling if it has one, and its floor.
class StatValue {
  const StatValue(this.value, [this.max, this.min = 0]);

  factory StatValue.fromJson(Object? json) {
    if (json is Map<String, Object?> &&
        json['value'] is int &&
        (json['max'] == null || json['max'] is int) &&
        (json['min'] == null || json['min'] is int)) {
      return StatValue(
        json['value']! as int,
        json['max'] as int?,
        // Saves from before schema 8 have floors of 0.
        json['min'] as int? ?? 0,
      );
    }
    throw const FormatException('state: bad stat');
  }

  final int value;
  final int? max;

  /// 0, or what the story set (schema 8; may be negative).
  final int min;

  /// The stat set to [next], kept within `min..max`.
  StatValue clampedTo(int next) => StatValue(
    next < min ? min : (max != null && next > max! ? max! : next),
    max,
    min,
  );

  /// [value] plus [delta], kept within `min..max`.
  StatValue adjusted(int delta) => clampedTo(value + delta);

  Map<String, Object?> toJson() => {
    'value': value,
    'max': max,
    if (min != 0) 'min': min,
  };
}

/// Progress through the current fight. See spec/framework.md B11.
class CombatState {
  const CombatState(this.enemy, this.enemyHealth, [this.luck, this.round = 0]);

  factory CombatState.fromJson(Object? json) {
    if (json is Map<String, Object?> &&
        json['enemy'] is int &&
        json['health'] is List<Object?> &&
        (json['health']! as List<Object?>).every((h) => h is int) &&
        (json['round'] == null || json['round'] is int)) {
      return CombatState(
        json['enemy']! as int,
        (json['health']! as List<Object?>).cast<int>(),
        json['luck'] == null ? null : LuckChance.fromJson(json['luck']),
        // A save from before schema 8 has no count.
        json['round'] as int? ?? 0,
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

  /// Rounds played so far, items that cost a round included (schema 8).
  final int round;

  Map<String, Object?> toJson() => {
    'enemy': enemy,
    'health': enemyHealth,
    if (luck != null) 'luck': luck!.toJson(),
    'round': round,
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
    this.counts = const {},
    this.offerCounts = const {},
    this.returnTo = const [],
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
      // Saves from before counted items (schema 8) hold one of each.
      counts: _ints(json['counts']),
      offerCounts: _ints(json['offerCounts']),
      // Saves from before schema 8 remember no pages.
      returnTo: json['returnTo'] == null ? const [] : _list(json['returnTo']),
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

  static Map<String, int> _ints(Object? json) {
    if (json == null) return const {};
    if (json is Map<String, Object?> && json.values.every((v) => v is int)) {
      return json.cast<String, int>();
    }
    throw const FormatException('state: expected a map of counts');
  }

  static List<String> _list(Object? json) {
    if (json is List<Object?> && json.every((e) => e is String)) {
      return json.cast<String>().toList();
    }
    throw const FormatException('state: expected a list of strings');
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

  /// How many of a countable item (schema 8) are held, for every one held
  /// more than once; any other item held counts 1. See [count].
  final Map<String, int> counts;

  /// The same for the offers: how many are offered at once.
  final Map<String, int> offerCounts;

  /// The pages a `return` leads back to, oldest first (schema 8): the last
  /// one is where the next `return` goes.
  final List<String> returnTo;

  /// How many of [item] the pack holds (0 if none).
  int count(String item) => inventory.contains(item) ? counts[item] ?? 1 : 0;

  /// How many of [item] are on offer (0 if it is not).
  int offered(String item) =>
      offers.contains(item) ? offerCounts[item] ?? 1 : 0;

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
  /// never below its floor (B5).
  int stat(String id) =>
      max(stats[id]?.min ?? 0, (stats[id]?.value ?? 0) + (statBonus[id] ?? 0));

  /// The bonus carried items give to [id] (0 if none).
  int bonusOf(String id) => statBonus[id] ?? 0;

  GameState copyWith({
    String? node,
    Map<String, StatValue>? stats,
    Set<String>? inventory,
    Set<String>? flags,
    Set<String>? visited,
    List<String>? offers,
    Map<String, int>? counts,
    Map<String, int>? offerCounts,
    List<String>? returnTo,
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
    counts: counts ?? this.counts,
    offerCounts: offerCounts ?? this.offerCounts,
    returnTo: returnTo ?? this.returnTo,
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
    'counts': counts,
    'offerCounts': offerCounts,
    'returnTo': returnTo,
    'taken': taken.toList(),
    'visits': visits,
    'name': name,
    'journal': journal,
    'music': music,
  };
}
