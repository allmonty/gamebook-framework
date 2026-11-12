import 'dart:math';

/// Dice notation: `NdM`, `NdM+K`, `NdM-K` or a plain integer.
/// See spec/framework.md B8.
class Dice {
  const Dice._(this.count, this.faces, this.modifier);

  /// Throws [FormatException] if [source] is not valid notation.
  factory Dice.parse(String source) {
    final match = _pattern.firstMatch(source);
    if (match == null) {
      throw FormatException('invalid dice notation "$source"');
    }
    if (match.group(1) == null) return Dice._(0, 0, int.parse(source));
    final count = int.parse(match.group(1)!);
    final faces = int.parse(match.group(2)!);
    if (count < 1 || faces < 2) {
      throw FormatException(
        'invalid dice notation "$source" (needs at least 1 die with 2 faces)',
      );
    }
    if (count > 100 || faces > 1000) {
      throw FormatException(
        'invalid dice notation "$source" (at most 100 dice of 1000 faces)',
      );
    }
    return Dice._(count, faces, int.parse(match.group(3) ?? '0'));
  }

  static final _pattern = RegExp(
    r'^(?:(\d{1,3})d(\d{1,4})([+-]\d{1,6})?|\d{1,6})$',
  );

  /// Number of dice; 0 for a fixed number.
  final int count;
  final int faces;
  final int modifier;

  int get min => count + modifier;
  int get max => count * faces + modifier;

  DiceRoll roll(Random random) => DiceRoll([
    for (var i = 0; i < count; i++) random.nextInt(faces) + 1,
  ], modifier);

  @override
  String toString() => count == 0
      ? '$modifier'
      : '${count}d$faces${modifier == 0
            ? ''
            : modifier > 0
            ? '+$modifier'
            : '$modifier'}';
}

/// The outcome of one roll; the UI shows [dice] and [total].
class DiceRoll {
  const DiceRoll(this.dice, this.modifier);

  final List<int> dice;
  final int modifier;

  int get total => dice.fold(modifier, (sum, d) => sum + d);
}
