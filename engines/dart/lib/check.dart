import 'dart:math';

import 'dice.dart';
import 'state.dart';
import 'story.dart';

/// The outcome of a dice check. See spec/framework.md B10.
class CheckResult {
  const CheckResult({
    required this.roll,
    required this.added,
    required this.target,
    required this.op,
    required this.passed,
  });

  final DiceRoll roll;

  /// What was added to the dice (the `add` stat or number; 0 if none).
  final int added;
  final int target;
  final CheckOp op;
  final bool passed;

  int get total => roll.total + added;
}

int operandValue(Operand operand, GameState state) => switch (operand) {
  Const(:final value) => value,
  StatRef(:final stat) => state.stat(stat),
};

/// Rolls [check] against the stats in [state]. Throws [FormatException] if the
/// roll is not valid dice notation (the validator catches that earlier).
CheckResult resolveCheck(Check check, GameState state, Random random) {
  final roll = Dice.parse(check.roll).roll(random);
  final added = check.add == null ? 0 : operandValue(check.add!, state);
  final target = operandValue(check.vs, state);
  final total = roll.total + added;
  return CheckResult(
    roll: roll,
    added: added,
    target: target,
    op: check.op,
    passed: switch (check.op) {
      CheckOp.gte => total >= target,
      CheckOp.lte => total <= target,
    },
  );
}
