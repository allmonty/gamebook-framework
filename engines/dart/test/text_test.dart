import 'package:gamebook_engine/json_reader.dart';
import 'package:gamebook_engine/text.dart';
import 'package:test/test.dart';

String? lookup(String name) => switch (name) {
  'gold' => '7',
  'stamina' => '12',
  'stamina.max' => '24',
  _ => null,
};

void main() {
  group('renderTemplate', () {
    test('text without braces is unchanged', () {
      expect(renderTemplate('Hello, world.', lookup), 'Hello, world.');
    });

    test('fills in stats and their maximum', () {
      expect(
        renderTemplate(
          'You have {gold} crowns and {stamina}/{stamina.max}.',
          lookup,
        ),
        'You have 7 crowns and 12/24.',
      );
    });

    test('doubled braces are literal', () {
      expect(
        renderTemplate('Use {{gold}} and }} like this: {gold}', lookup),
        'Use {gold} and } like this: 7',
      );
    });

    test('an unknown stat is left as written', () {
      expect(renderTemplate('A {mana} potion', lookup), 'A {mana} potion');
    });

    test('placeholders may sit side by side or at the edges', () {
      expect(renderTemplate('{gold}{gold}', lookup), '77');
      expect(renderTemplate('{gold}', lookup), '7');
    });
  });

  group('placeholderStats', () {
    test('lists the stats, without .max', () {
      expect(placeholderStats('{gold} of {stamina.max}, {{not}} {gold}'), [
        'gold',
        'stamina',
        'gold',
      ]);
    });
  });

  group('checkTemplate', () {
    test('accepts good text', () {
      expect(
        () => checkTemplate('{gold} {{ }} {a-b.max}', 'p'),
        returnsNormally,
      );
    });

    String error(String source) {
      try {
        checkTemplate(source, 'nodes.a.text');
      } on StoryFormatException catch (e) {
        return e.toString();
      }
      fail('expected a StoryFormatException');
    }

    test('rejects an unclosed brace', () {
      expect(error('You have {gold'), startsWith('nodes.a.text: unclosed "{"'));
    });

    test('rejects a stray closing brace', () {
      expect(error('oops }'), startsWith('nodes.a.text: stray "}"'));
    });

    test('rejects a placeholder that is not a stat name', () {
      expect(
        error('{ gold }'),
        startsWith('nodes.a.text: bad placeholder "{ gold }"'),
      );
      expect(error('{}'), startsWith('nodes.a.text: bad placeholder "{}"'));
      expect(
        error('{a.min}'),
        startsWith('nodes.a.text: bad placeholder "{a.min}"'),
      );
    });
  });
}
