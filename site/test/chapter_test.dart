import 'package:gamebook_site/src/content/chapter.dart';
import 'package:gamebook_site/src/content/template.dart';
import 'package:test/test.dart';

void main() {
  test('renders markdown, takes the title, embeds examples', () {
    final chapter = renderChapter(
      '01-start',
      '# Getting started\n\nHello *world*.\n\n```gamebook\nexamples/a/b\n```\n',
      (path) => '{"title": "x"}',
    );
    expect(chapter.title, 'Getting started');
    expect(chapter.html, contains('<em>world</em>'));
    expect(chapter.html, contains('class="gb-embed"'));
    expect(chapter.html, isNot(contains('```')));
  });

  test('links to other chapters point at their pages', () {
    final chapter = renderChapter(
      'x',
      '# X\n\nSee [next](02-pages.md) and [part](03-items.md#keys) '
          'and [spec](https://example.com/a.md) and [kit](../../llm-kit.md).',
      (_) => null,
    );
    expect(chapter.html, contains('href="02-pages.html"'));
    expect(chapter.html, contains('href="03-items.html#keys"'));
    expect(chapter.html, contains('href="https://example.com/a.md"'));
    expect(chapter.html, contains('href="../../llm-kit.md"'));
  });

  test('a chapter needs a title', () {
    expect(
      () => renderChapter('x', 'no title', (_) => null),
      throwsA(isA<BuildException>()),
    );
  });

  test('literal double braces in a chapter are kept', () {
    final chapter = renderChapter(
      'x',
      '# X\n\nWrite `{{` for a brace.',
      (_) => null,
    );
    expect(chapter.html, contains('{{'));
  });
}
