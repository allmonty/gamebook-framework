// The front door must not lead nowhere: every relative link in the root
// README, AGENTS.md and llms.txt, and every GitHub link into this repo,
// points at a file or folder that exists. Links to the website are checked
// against the build in site_builder_test.dart.
import 'dart:io';

import 'package:test/test.dart';

final _link = RegExp(r'\]\(([^)\s]+)\)');
const _github = 'https://github.com/allmonty/gamebook-framework/';

/// The repo path [target] points at, or null when it is not in this repo.
String? repoPath(String target) {
  final path = target.split('#').first;
  for (final prefix in ['${_github}blob/main/', '${_github}tree/main/']) {
    if (path.startsWith(prefix)) return path.substring(prefix.length);
  }
  if (path.isEmpty || path.contains('://')) return null;
  return path;
}

void main() {
  for (final doc in ['README.md', 'AGENTS.md', 'llms.txt']) {
    test('$doc links to files that exist', () {
      final text = File('../$doc').readAsStringSync();
      final missing = [
        for (final m in _link.allMatches(text))
          if (repoPath(m[1]!) case final path?)
            if (FileSystemEntity.typeSync('../$path') ==
                FileSystemEntityType.notFound)
              path,
      ];
      expect(missing, isEmpty);
    });
  }

  test('a GitHub link maps to its path in the repo', () {
    expect(
      repoPath('${_github}blob/main/spec/framework.md#b4'),
      'spec/framework.md',
    );
    expect(repoPath('https://example.com/x'), isNull);
    expect(repoPath('#start-here'), isNull);
  });
}
