import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:gamebook_engine/package.dart';
import 'package:test/test.dart';

import '../bin/pack_game.dart';

final fixture = File('test/fixtures/rusty-door.en.json').readAsStringSync();

/// The fixture in [lang], optionally changed by [mutate].
List<int> storyBytes({
  String lang = 'en',
  void Function(Map<String, Object?>)? mutate,
}) {
  final json = jsonDecode(fixture) as Map<String, Object?>..['lang'] = lang;
  mutate?.call(json);
  return utf8.encode(jsonEncode(json));
}

/// A zip with exactly these entries, bypassing [writePackage]'s checks.
List<int> zip(Map<String, List<int>> files, {Map<String, String>? links}) {
  final archive = Archive();
  files.forEach((path, data) => archive.addFile(ArchiveFile.bytes(path, data)));
  links?.forEach((path, to) => archive.addFile(ArchiveFile.symlink(path, to)));
  return ZipEncoder().encodeBytes(archive);
}

Matcher refused(String message) => throwsA(
  isA<PackageException>().having((e) => e.message, 'message', message),
);

void main() {
  test('a package round-trips its stories and media', () {
    final bytes = writePackage({
      'story.en.json': storyBytes(),
      'story.pt.json': storyBytes(lang: 'pt'),
      'images/cellar.webp': [1, 2, 3],
      'audio/drip.ogg': [4],
      'builder.json': utf8.encode('{}'),
    });
    final package = readPackage(bytes);

    expect(package.id, 'rusty-door');
    expect(package.stories.keys, ['en', 'pt']);
    expect(package.stories['pt']!.nodes.keys, contains('cellar'));
    expect(package.sources.keys, ['story.en.json', 'story.pt.json']);
    expect(package.sources['story.en.json'], utf8.decode(storyBytes()));
    expect(package.files.keys, [
      'audio/drip.ogg',
      'builder.json',
      'images/cellar.webp',
    ]);
    expect(package.files['images/cellar.webp'], [1, 2, 3]);
  });

  test('folder entries are fine', () {
    final archive = Archive()
      ..addFile(ArchiveFile.directory('images/'))
      ..addFile(ArchiveFile.bytes('story.en.json', storyBytes()));
    expect(readPackage(ZipEncoder().encodeBytes(archive)).id, 'rusty-door');
  });

  group('refuses', () {
    test('a file that is not a zip', () {
      for (final bytes in ['hello', 'nope', 'PK']) {
        expect(
          () => readPackage(utf8.encode(bytes)),
          refused('not a zip file'),
          reason: bytes,
        );
      }
    });

    test('a package without a story', () {
      expect(
        () => readPackage(
          zip({
            'images/a.png': [1],
          }),
        ),
        refused('no story file'),
      );
    });

    for (final path in [
      '../story.en.json',
      '/etc/passwd',
      'images/../../x.png',
      'notes.txt',
      'README.md',
      'images/run.exe',
      'images/a.png.sh',
      'other/a.png',
      'deep/story.en.json',
    ]) {
      test('the path $path', () {
        expect(
          () => readPackage(
            zip({
              'story.en.json': storyBytes(),
              path: [1],
            }),
          ),
          throwsA(
            isA<PackageException>().having(
              (e) => e.message,
              'message',
              startsWith('$path: '),
            ),
          ),
        );
      });
    }

    test('links', () {
      expect(
        () => readPackage(
          zip({'story.en.json': storyBytes()}, links: {'images/a.png': '/'}),
        ),
        refused('images/a.png: links are not allowed'),
      );
    });

    test('too many files, before unpacking', () {
      expect(
        () => readPackage(
          zip({
            'story.en.json': storyBytes(),
            'images/a.png': [1],
            'images/b.png': [2],
          }),
          maxFiles: 2,
        ),
        refused('too many files: 3 (at most 2)'),
      );
    });

    test('too many bytes', () {
      expect(
        () => readPackage(
          zip({'story.en.json': storyBytes()}),
          maxBytes: 1024 * 1024 ~/ 2,
        ),
        returnsNormally,
      );
      expect(
        () => readPackage(
          zip({
            'story.en.json': storyBytes(),
            'images/big.png': List.filled(2048, 0),
          }),
          maxBytes: 2048,
        ),
        refused('too big: more than 0 MB unpacked'),
      );
    });

    test('a file over the limit before it is even opened', () {
      expect(
        () => readPackage(List.filled(4096, 0), maxBytes: 2048),
        refused('too big: more than 0 MB unpacked'),
      );
    });

    test('a story that does not parse, naming the file and the path', () {
      expect(
        () => readPackage(
          zip({'story.en.json': storyBytes(mutate: (j) => j['typo'] = 1)}),
        ),
        refused('story.en.json: typo: unknown key'),
      );
    });

    test('a story with validator errors', () {
      expect(
        () => readPackage(
          zip({'story.en.json': storyBytes(mutate: (j) => j['start'] = 'x')}),
        ),
        throwsA(
          isA<PackageException>().having(
            (e) => e.message,
            'message',
            startsWith('story.en.json: error: start:'),
          ),
        ),
      );
    });

    test('a file whose name and lang disagree', () {
      expect(
        () => readPackage(zip({'story.pt.json': storyBytes()})),
        refused('story.pt.json: lang is "en" but the file name says "pt"'),
      );
    });

    test('stories of two games', () {
      expect(
        () => readPackage(
          zip({
            'story.en.json': storyBytes(),
            'story.pt.json': storyBytes(
              lang: 'pt',
              mutate: (j) => j['id'] = 'other',
            ),
          }),
        ),
        refused('stories have different ids: "rusty-door" and "other"'),
      );
    });

    test('translations that do not match', () {
      expect(
        () => readPackage(
          zip({
            'story.en.json': storyBytes(),
            'story.pt.json': storyBytes(
              lang: 'pt',
              mutate: (j) => (j['items']! as Map<String, Object?>)['lamp'] = {
                'name': 'Lamp',
              },
            ),
          }),
        ),
        throwsA(
          isA<PackageException>().having(
            (e) => e.message,
            'message',
            startsWith('translations do not match:'),
          ),
        ),
      );
    });

    test('and writePackage refuses what readPackage would', () {
      expect(
        () => writePackage({
          'story.en.json': storyBytes(),
          'notes.txt': [1],
        }),
        throwsA(isA<PackageException>()),
      );
    });
  });

  test('belongsInPackage picks the files a packer keeps', () {
    expect(
      [
        'story.en.json',
        'builder.json',
        'images/a.webp',
        'audio/sub/b.MP3',
        'README.md',
        'images/notes.txt',
        'story.schema.json',
        r'images\a.png',
      ].where(belongsInPackage),
      ['story.en.json', 'builder.json', 'images/a.webp', 'audio/sub/b.MP3'],
    );
  });

  group('pack_game', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('pack'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('packs a folder, leaving out what does not belong', () {
      File('${dir.path}/game/story.en.json')
        ..createSync(recursive: true)
        ..writeAsBytesSync(storyBytes());
      File('${dir.path}/game/images/a.webp')
        ..createSync(recursive: true)
        ..writeAsBytesSync([7]);
      File('${dir.path}/game/README.md').writeAsStringSync('# Notes');
      final out = StringBuffer();
      final target = '${dir.path}/out.gamebook';

      expect(runPackGame(['${dir.path}/game/', target], out), 0);
      expect(out.toString(), startsWith('left out: README.md\nwrote $target'));
      final package = readPackage(File(target).readAsBytesSync());
      expect(package.id, 'rusty-door');
      expect(package.files.keys, ['images/a.webp']);
    });

    test('reports a game it cannot pack', () {
      File('${dir.path}/game/story.en.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{');
      final out = StringBuffer();
      expect(runPackGame(['${dir.path}/game'], out), 1);
      expect(out.toString(), contains('cannot pack'));
    });

    test('bad usage', () {
      final out = StringBuffer();
      expect(runPackGame([], out), 2);
      expect(runPackGame(['${dir.path}/missing'], out), 2);
    });
  });
}
