import 'package:gamebook_site/src/content/template.dart';
import 'package:test/test.dart';

void main() {
  test('fills placeholders', () {
    expect(
      fillTemplate('<p>{{a.b}} {{c}}</p>', {'a.b': 'x', 'c': 'y'}),
      '<p>x y</p>',
    );
  });

  test('a missing value fails the build, naming it', () {
    expect(
      () => fillTemplate('{{missing}}', {}),
      throwsA(
        isA<BuildException>().having(
          (e) => e.message,
          'message',
          contains('{{missing}}'),
        ),
      ),
    );
  });

  test('inserted values are not filled again', () {
    expect(fillTemplate('{{a}}', {'a': '{{b}}'}), '{{b}}');
  });
}
