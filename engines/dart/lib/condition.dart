import 'json_reader.dart';
import 'quantity.dart';
import 'state.dart';

enum CompareOp { gte, lte, eq }

/// Something a choice can require. See spec/framework.md B7.
sealed class Condition {
  const Condition();

  factory Condition.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    const kinds = [
      'has',
      'flag',
      'visited',
      'visits',
      'all',
      'any',
      'not',
      'stat',
    ];
    final present = kinds.where(obj.has).toList();
    if (present.length != 1) {
      throw StoryFormatException(
        path,
        'a condition needs exactly one of ${kinds.join(', ')}',
      );
    }
    final Condition condition;
    switch (present.single) {
      case 'has':
        condition = HasItem(checkId(obj.string('has'), obj.childPath('has')));
      case 'flag':
        condition = FlagSet(checkId(obj.string('flag'), obj.childPath('flag')));
      case 'visited':
        condition = Visited(
          checkId(obj.string('visited'), obj.childPath('visited')),
        );
      case 'visits':
        condition = _visits(obj);
      case 'all':
        condition = All(obj.list('all', Condition.fromJson));
      case 'any':
        condition = Any(obj.list('any', Condition.fromJson));
      case 'not':
        condition = Not(
          Condition.fromJson(obj.raw('not'), obj.childPath('not')),
        );
      default:
        condition = _stat(obj);
    }
    obj.finish();
    return condition;
  }

  static VisitCount _visits(JsonObject obj) {
    final ops = CompareOp.values.where((op) => obj.has(op.name)).toList();
    if (ops.length != 1) {
      throw StoryFormatException(
        obj.path,
        'a visits condition needs exactly one of gte, lte, eq',
      );
    }
    return VisitCount(
      checkId(obj.string('visits'), obj.childPath('visits')),
      ops.single,
      obj.integer(ops.single.name),
    );
  }

  static StatCompare _stat(JsonObject obj) {
    final ops = CompareOp.values.where((op) => obj.has(op.name)).toList();
    if (ops.length != 1) {
      throw StoryFormatException(
        obj.path,
        'a stat condition needs exactly one of gte, lte, eq',
      );
    }
    return StatCompare(
      checkId(obj.string('stat'), obj.childPath('stat')),
      ops.single,
      Quantity.fromJson(
        obj.raw(ops.single.name),
        obj.childPath(ops.single.name),
      ),
    );
  }
}

class HasItem extends Condition {
  const HasItem(this.item);
  final String item;
}

class FlagSet extends Condition {
  const FlagSet(this.flag);
  final String flag;
}

class Visited extends Condition {
  const Visited(this.node);
  final String node;
}

/// How many times a node was entered (schema 4).
class VisitCount extends Condition {
  const VisitCount(this.node, this.op, this.value);
  final String node;
  final CompareOp op;
  final int value;
}

class StatCompare extends Condition {
  const StatCompare(this.stat, this.op, this.value);
  final String stat;
  final CompareOp op;

  /// What the stat is compared with: a number, or another stat (schema 5).
  final Quantity value;
}

class All extends Condition {
  const All(this.conditions);
  final List<Condition> conditions;
}

class Any extends Condition {
  const Any(this.conditions);
  final List<Condition> conditions;
}

class Not extends Condition {
  const Not(this.condition);
  final Condition condition;
}

/// Whether [condition] holds in [state].
bool evaluate(Condition condition, GameState state) => switch (condition) {
  HasItem(:final item) => state.inventory.contains(item),
  FlagSet(:final flag) => state.flags.contains(flag),
  Visited(:final node) => state.visited.contains(node),
  VisitCount(:final node, :final op, :final value) => switch (op) {
    CompareOp.gte => state.visitsTo(node) >= value,
    CompareOp.lte => state.visitsTo(node) <= value,
    CompareOp.eq => state.visitsTo(node) == value,
  },
  StatCompare(:final stat, :final op, :final value) => switch (op) {
    CompareOp.gte => state.stat(stat) >= value.resolve(state),
    CompareOp.lte => state.stat(stat) <= value.resolve(state),
    CompareOp.eq => state.stat(stat) == value.resolve(state),
  },
  All(:final conditions) => conditions.every((c) => evaluate(c, state)),
  Any(:final conditions) => conditions.any((c) => evaluate(c, state)),
  Not(:final condition) => !evaluate(condition, state),
};

/// A single requirement that is not met. [negated] means the player must NOT
/// have it (the requirement sits under a `not`).
class Unmet {
  const Unmet(this.condition, {this.negated = false, this.target});

  /// Never an `All`, `Any` or `Not`.
  final Condition condition;
  final bool negated;

  /// For a stat condition: the number it is compared with right now (a stat
  /// quantity is resolved), so the player can be told "needs Gold 12".
  final int? target;
}

/// The leaf requirements keeping [condition] from holding in [state], for the
/// "needs ..." text on a locked choice. Empty when it holds. For `any` all
/// the alternatives are listed; authors who need nicer wording set
/// `lockedText` on the choice.
List<Unmet> explain(Condition condition, GameState state) =>
    _unmet(condition, state, negated: false);

List<Unmet> _unmet(
  Condition condition,
  GameState state, {
  required bool negated,
}) {
  if (evaluate(condition, state) != negated) return const [];
  return switch (condition) {
    Not(:final condition) => _unmet(condition, state, negated: !negated),
    All(:final conditions) || Any(:final conditions) => [
      for (final c in conditions) ..._unmet(c, state, negated: negated),
    ],
    _ => [
      Unmet(
        condition,
        negated: negated,
        target: condition is StatCompare
            ? condition.value.resolve(state)
            : null,
      ),
    ],
  };
}
