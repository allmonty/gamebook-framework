import 'package:gamebook_engine/json_reader.dart';
import 'package:gamebook_engine/quantity.dart';
import 'package:gamebook_engine/state.dart';
import 'package:test/test.dart';

const state = GameState(
  node: 'a',
  stats: {'gold': StatValue(12, 50), 'price': StatValue(5)},
);

void main() {
  group('parse', () {
    test('an integer', () {
      final q = Quantity.fromJson(7, 'p');
      expect(q.isConstant, isTrue);
      expect(q.value, 7);
      expect(q.resolve(state), 7);
    });

    test('a stat, with or without a multiplier', () {
      expect(Quantity.fromJson({'stat': 'price'}, 'p').resolve(state), 5);
      expect(
        Quantity.fromJson({'stat': 'price', 'times': 3}, 'p').resolve(state),
        15,
      );
      expect(
        Quantity.fromJson({'stat': 'price', 'times': -1}, 'p').resolve(state),
        -5,
      );
    });

    test('a stat the state does not have is 0', () {
      expect(const Quantity.ofStat('nope').resolve(state), 0);
    });

    test('compares by value and prints compactly', () {
      expect(const Quantity.value(3), const Quantity.value(3));
      expect(const Quantity.ofStat('a', 2), const Quantity.ofStat('a', 2));
      expect(const Quantity.ofStat('a'), isNot(const Quantity.value(1)));
      expect('${const Quantity.value(3)}', '3');
      expect('${const Quantity.ofStat('a')}', 'a');
      expect('${const Quantity.ofStat('a', -2)}', 'a*-2');
    });

    test('errors name the path', () {
      String error(Object? json) {
        try {
          Quantity.fromJson(json, 'x.gte');
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(error('gold'), 'x.gte: expected an integer or {"stat": ...}');
      expect(error(1.5), 'x.gte: expected an integer or {"stat": ...}');
      expect(error(<String, Object?>{}), 'x.gte.stat: missing');
      expect(error({'stat': 'a b'}), startsWith('x.gte.stat: invalid id'));
      expect(
        error({'stat': 'a', 'times': 'x'}),
        'x.gte.times: expected an integer',
      );
      expect(error({'stat': 'a', 'more': 1}), 'x.gte.more: unknown key');
    });
  });
}
