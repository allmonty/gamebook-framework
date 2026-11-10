import 'package:gamebook_engine/check.dart';
import 'package:gamebook_engine/json_reader.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

Check check(Map<String, Object?> json) =>
    Check.fromJson(JsonObject({'pass': 'a', 'fail': 'b', ...json}, ''));

const state = GameState(
  node: 'n',
  stats: {'skill': StatValue(9, 12), 'luck': StatValue(8, 12)},
);

void main() {
  test('gte adds a stat to the dice and passes at the target', () {
    final c = check({'roll': '2d6', 'add': 'skill', 'op': 'gte', 'vs': 15});

    final pass = resolveCheck(c, state, ScriptedRandom([3, 3]));
    expect(pass.total, 15);
    expect(pass.passed, isTrue);
    expect(pass.roll.dice, [3, 3]);
    expect(pass.added, 9);
    expect(pass.target, 15);

    final fail = resolveCheck(c, state, ScriptedRandom([3, 2]));
    expect(fail.total, 14);
    expect(fail.passed, isFalse);
  });

  test('lte against a stat is the Test your Luck shape', () {
    final c = check({'roll': '2d6', 'op': 'lte', 'vs': 'luck'});

    expect(resolveCheck(c, state, ScriptedRandom([4, 4])).passed, isTrue);
    expect(resolveCheck(c, state, ScriptedRandom([4, 5])).passed, isFalse);
    expect(resolveCheck(c, state, ScriptedRandom([1, 1])).target, 8);
  });

  test('add may be a plain number', () {
    final c = check({'roll': '1d20', 'add': 2, 'op': 'gte', 'vs': 12});

    final result = resolveCheck(c, state, ScriptedRandom([10]));
    expect(result.total, 12);
    expect(result.passed, isTrue);
  });

  test('a bad roll string throws', () {
    final c = check({'roll': 'x', 'op': 'gte', 'vs': 1});
    expect(
      () => resolveCheck(c, state, ScriptedRandom([])),
      throwsFormatException,
    );
  });
}
