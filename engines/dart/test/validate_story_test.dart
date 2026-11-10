import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/validate_story.dart';

final valid = jsonDecode(
  File('test/fixtures/rusty-door.en.json').readAsStringSync(),
) as Map<String, Object?>;

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('validate_story'));
  tearDown(() => root.deleteSync(recursive: true));

  File write(String path, Object json) => File('${root.path}/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(json is String ? json : jsonEncode(json));

  (int, String) run(List<String> args) {
    final out = StringBuffer();
    final code = runValidator(args, out);
    return (code, out.toString());
  }

  test('a valid game with a matching translation passes', () {
    write('rusty/story.en.json', valid);
    write('rusty/story.pt.json', {...valid, 'lang': 'pt'});

    final (code, out) = run([root.path]);

    expect(code, 0);
    expect(out, contains('2 file(s): 0 error(s), 0 warning(s).'));
  });

  test('story.schema.json is not treated as a story', () {
    write('rusty/story.en.json', valid);
    write('story.schema.json', {r'$schema': 'x', 'type': 'object'});

    final (code, out) = run([root.path]);

    expect(code, 0);
    expect(out, contains('1 file(s)'));
  });

  test('errors give exit code 1 and name the file', () {
    final broken = jsonDecode(jsonEncode(valid)) as Map<String, Object?>;
    broken['start'] = 'nowhere';
    final file = write('rusty/story.en.json', broken);

    final (code, out) = run([root.path]);

    expect(code, 1);
    expect(out, contains('${file.path}: error: start: unknown node "nowhere"'));
  });

  test('a file that does not parse is an error', () {
    write('rusty/story.en.json', '{nope');

    final (code, out) = run([root.path]);

    expect(code, 1);
    expect(out, contains('invalid JSON'));
  });

  test('the file name language must match the story', () {
    write('rusty/story.pt.json', valid);

    final (code, out) = run([root.path]);

    expect(code, 1);
    expect(out, contains('lang: is "en" but the file name says "pt"'));
  });

  test('image paths are checked relative to the story file', () {
    final withImage = {...valid, 'cover': 'images/cover.webp'};
    write('rusty/story.en.json', withImage);

    expect(run([root.path]).$1, 1);

    write('rusty/images/cover.webp', 'x');
    expect(run([root.path]).$1, 0);
  });

  test('warnings pass unless --strict', () {
    final json = jsonDecode(jsonEncode(valid)) as Map<String, Object?>;
    (json['nodes']! as Map<String, Object?>)['lost'] = {
      'text': 'x',
      'ending': 'death',
    };
    write('rusty/story.en.json', json);

    final (code, out) = run([root.path]);
    expect(code, 0);
    expect(out, contains('1 warning(s)'));
    expect(run([root.path, '--strict']).$1, 1);
  });

  test('translation differences are reported as warnings', () {
    final pt = jsonDecode(jsonEncode(valid)) as Map<String, Object?>
      ..['lang'] = 'pt';
    (pt['nodes']! as Map<String, Object?>)['bonus'] = {
      'text': 'x',
      'ending': 'death',
    };
    write('rusty/story.en.json', valid);
    write('rusty/story.pt.json', pt);

    final (_, out) = run([root.path]);

    expect(out, contains('node "bonus" exists in pt but not in en'));
  });

  test('no story files is a usage error', () {
    expect(run([root.path]).$1, 2);
    expect(run([]).$1, 2);
  });
}
