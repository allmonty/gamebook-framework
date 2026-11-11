// Enforces the layer rules of AGENTS.md ("Architecture of site/").
import 'dart:io';

import 'package:test/test.dart';

const _forbidden = {
  'lib/src/play': [
    'package:web',
    'dart:io',
    'dart:js_interop',
    '/ui/',
    '/content/',
  ],
  'lib/src/ui': ['dart:io', '/content/'],
  'lib/src/content': ['package:web', 'dart:js_interop', '/ui/', '/play/'],
};

final _import = RegExp(
  r'''^(?:import|export) ['"]([^'"]+)['"]''',
  multiLine: true,
);

void main() {
  for (final MapEntry(key: folder, value: banned) in _forbidden.entries) {
    test('$folder respects its layer', () {
      final dir = Directory(folder);
      if (!dir.existsSync()) return;
      final violations = [
        for (final file in dir.listSync(recursive: true).whereType<File>())
          for (final match in _import.allMatches(file.readAsStringSync()))
            if (banned.any((b) => _isBanned(match[1]!, b)))
              '${file.path}: ${match[1]}',
      ];
      expect(violations, isEmpty);
    });
  }
}

bool _isBanned(String uri, String banned) => banned.startsWith('/')
    ? uri.contains(banned) ||
          uri.startsWith('..${banned.substring(0, banned.length - 1)}') ||
          uri.startsWith(
            'package:gamebook_site/src${banned.substring(0, banned.length - 1)}',
          )
    : uri == banned || uri.startsWith('$banned/');
