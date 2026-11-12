import 'json_reader.dart';
import 'state.dart';

/// A number a story can give directly or take from a stat: `5`, or
/// `{ "stat": "price" }`, or `{ "stat": "price", "times": -1 }`. See
/// spec/framework.md B4.
class Quantity {
  const Quantity.value(int this.value) : stat = null, times = 1;

  const Quantity.ofStat(String this.stat, [this.times = 1]) : value = null;

  factory Quantity.fromJson(Object? json, String path) {
    if (json is int) return Quantity.value(checkInt(json, path));
    if (json is! Map<String, Object?>) {
      throw StoryFormatException(path, 'expected an integer or {"stat": ...}');
    }
    final obj = JsonObject(json, path);
    final quantity = Quantity.ofStat(
      checkId(obj.string('stat'), obj.childPath('stat')),
      obj.has('times') ? obj.integer('times') : 1,
    );
    obj.finish();
    return quantity;
  }

  /// The fixed number, or null if this reads a stat.
  final int? value;
  final String? stat;
  final int times;

  bool get isConstant => value != null;

  /// The number now: the fixed value, or the stat's current value times
  /// [times] (0 for a stat the state does not have).
  int resolve(GameState state) => value ?? state.stat(stat!) * times;

  @override
  bool operator ==(Object other) =>
      other is Quantity &&
      other.value == value &&
      other.stat == stat &&
      other.times == times;

  @override
  int get hashCode => Object.hash(value, stat, times);

  @override
  String toString() => isConstant
      ? '$value'
      : times == 1
      ? stat!
      : '$stat*$times';
}
