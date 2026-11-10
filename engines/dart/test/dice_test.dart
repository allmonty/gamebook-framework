import 'dart:math';

import 'package:gamebook_engine/dice.dart';
import 'package:test/test.dart';

void main() {
  group('parse', () {
    test('NdM, with and without modifier', () {
      final plain = Dice.parse('1d20');
      expect((plain.count, plain.faces, plain.modifier), (1, 20, 0));
      final plus = Dice.parse('2d6+6');
      expect((plus.count, plus.faces, plus.modifier), (2, 6, 6));
      final minus = Dice.parse('2d6-1');
      expect((minus.count, minus.faces, minus.modifier), (2, 6, -1));
    });

    test('plain integer is a fixed number', () {
      final fixed = Dice.parse('3');
      expect(fixed.count, 0);
      expect(fixed.min, 3);
      expect(fixed.max, 3);
      expect(fixed.roll(Random(1)).dice, isEmpty);
      expect(fixed.roll(Random(1)).total, 3);
    });

    test('toString round trips the notation', () {
      for (final source in ['1d6', '2d6+6', '2d6-1', '3', '0']) {
        expect(Dice.parse(source).toString(), source);
      }
    });

    test('rejects bad notation', () {
      for (final bad in [
        '',
        'd6',
        '2d',
        '2d6+',
        '2 d6',
        '2D6',
        '-3',
        '1.5',
        'abc',
        '0d6',
        '1d0',
        '1d1',
      ]) {
        expect(() => Dice.parse(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('roll', () {
    test('keeps each die and adds the modifier to the total', () {
      final roll = Dice.parse('3d6+2').roll(Random(7));
      expect(roll.dice, hasLength(3));
      expect(roll.total, roll.dice.reduce((a, b) => a + b) + 2);
    });

    test('is deterministic for a seed', () {
      expect(
        Dice.parse('2d6').roll(Random(42)).dice,
        Dice.parse('2d6').roll(Random(42)).dice,
      );
    });

    test('stays within min and max and reaches both ends', () {
      final dice = Dice.parse('2d6-1');
      final random = Random(3);
      final totals = {for (var i = 0; i < 2000; i++) dice.roll(random).total};
      expect(totals.reduce(min), dice.min);
      expect(totals.reduce(max), dice.max);
      expect(dice.min, 1);
      expect(dice.max, 11);
    });
  });
}
