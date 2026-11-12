import 'package:gamebook_site/src/content/embed.dart';
import 'package:gamebook_site/src/content/template.dart';
import 'package:test/test.dart';

void main() {
  const story = '{\n  "title": "A </script> trap"\n}';

  test('a gamebook block becomes an embed with the example JSON', () {
    final out = embedExamples(
      'Before\n\n```gamebook\nexamples/x/y\n```\n\nAfter',
      (path) => path == 'examples/x/y' ? story : null,
    );
    expect(out, contains('<div class="gb-embed" data-example="examples/x/y">'));
    expect(out, contains(r'{"title":"A <\/script> trap"}'));
    expect(out, startsWith('Before'));
    expect(out, endsWith('After'));
  });

  test('other code blocks are left alone', () {
    const md = '```json\n{}\n```';
    expect(embedExamples(md, (_) => fail('no lookup')), md);
  });

  test('a missing example fails the build, naming the file', () {
    expect(
      () => embedExamples('```gamebook\nexamples/nope\n```', (_) => null),
      throwsA(
        isA<BuildException>().having(
          (e) => e.message,
          'message',
          contains('examples/nope'),
        ),
      ),
    );
  });

  test('an example that is not JSON fails the build', () {
    expect(() => exampleEmbed('p', '{oops'), throwsA(isA<BuildException>()));
  });
}
