import 'package:test/test.dart';

import '../bin/story_graph.dart';

const fixture = 'test/fixtures/rusty-door.en.json';

void main() {
  (int, String, String) run(List<String> args) {
    final out = StringBuffer();
    final err = StringBuffer();
    return (runGraph(args, out, err), out.toString(), err.toString());
  }

  test('prints DOT by default', () {
    final (code, out, _) = run([fixture]);
    expect(code, 0);
    expect(out, startsWith('digraph "rusty-door" {'));
  });

  test('--mermaid prints a flowchart', () {
    final (code, out, _) = run([fixture, '--mermaid']);
    expect(code, 0);
    expect(out, startsWith('flowchart TD'));
  });

  test('usage, missing file and bad story are failures', () {
    expect(run([]).$1, 2);
    expect(run(['nope.json']).$1, 1);
    expect(run(['pubspec.yaml']).$3, contains('invalid JSON'));
  });
}
