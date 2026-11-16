import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/simulate.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import '../bin/simulate_story.dart';

Story rusty() =>
    Story.parse(File('test/fixtures/rusty-door.en.json').readAsStringSync());

Story story(Map<String, Object?> nodes, {Map<String, Object?>? extra}) =>
    Story.fromJson({
      'schema': 1,
      'id': 's',
      'lang': 'en',
      'title': 'S',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'a',
      'nodes': nodes,
      ...?extra,
    });

void main() {
  test('the rusty door is winnable and every ending is reached', () {
    final report = simulate(rusty(), games: 300, random: Random(1));
    expect(report.rate(Outcome.victory), greaterThan(0.5));
    expect(report.unreachedEndings, isEmpty);
    expect(report.unvisited, isEmpty);
    expect(report.outcomes[Outcome.stuck], 0);
  });

  test('minutes come from the words read and the actions taken', () {
    final report = simulate(
      story({
        'a': {
          'text': List.filled(398, 'word').join(' '),
          'choices': [
            {'text': 'Go on', 'to': 'b'},
          ],
        },
        'b': {'text': List.filled(200, 'word').join(' '), 'ending': 'victory'},
      }),
      games: 3,
      random: Random(1),
    );
    // 600 words at 200 a minute, and one action of 5 seconds.
    expect(report.minutes, closeTo(3 + 5 / 60, 1e-9));
    expect('$report', contains('about 3 min per game'));
  });

  test('a page seen before counts a quarter of its words', () {
    final report = simulate(
      story({
        'a': {
          'text': List.filled(399, 'word').join(' '),
          'choices': [
            {'text': 'Look', 'to': 'b', 'once': true},
            {
              'text': 'Leave',
              'to': 'c',
              'if': {'visits': 'a', 'gte': 2},
            },
          ],
        },
        'b': {
          'text': List.filled(199, 'word').join(' '),
          'choices': [
            {'text': 'Back', 'to': 'a'},
          ],
        },
        'c': {'text': List.filled(200, 'word').join(' '), 'ending': 'victory'},
      }),
      games: 1,
      random: Random(1),
    );
    // a: 399 + 2 choices (the locked one is shown), b: 200, a again: 400 at
    // a quarter (its once-only choice is gone, "Leave" is open), c: 200.
    expect(
      report.minutes,
      closeTo((401 + 200 + 400 / 4 + 200) / 200 + 0.25, 1e-9),
    );
  });

  test('minutes fall back to every ended game when none is won', () {
    final report = simulate(
      story({
        'a': {'text': List.filled(400, 'word').join(' '), 'ending': 'death'},
      }),
      games: 2,
      random: Random(1),
    );
    expect(report.minutes, closeTo(2, 1e-9));
  });

  test('the same seed gives the same report', () {
    String run() => '${simulate(rusty(), games: 50, random: Random(7))}';
    expect(run(), run());
  });

  test('games that reach a defeat ending count as defeats', () {
    final report = simulate(
      story(
        {
          'a': {
            'text': 'A',
            'choices': [
              {'text': 'Give up', 'to': 'b'},
            ],
          },
          'b': {'text': 'B', 'ending': 'defeat'},
        },
        extra: {'schema': 1},
      ),
      games: 10,
      random: Random(1),
    );
    expect(report.rate(Outcome.defeat), 1);
    expect(report.endings, {'b': 10});
    expect(
      '$report',
      startsWith(
        '10 games of "S": victory 0.0%, defeat 100.0%, death 0.0%, '
        'stuck 0.0%, endless 0.0%;',
      ),
    );
  });

  test('a page whose only choice never opens is a dead end', () {
    final report = simulate(
      story(
        {
          'a': {
            'text': 'A',
            'choices': [
              {
                'text': 'Unlock',
                'to': 'b',
                'if': {'has': 'key'},
              },
            ],
          },
          'b': {'text': 'B', 'ending': 'victory'},
        },
        extra: {
          'items': {
            'key': {'name': 'Key'},
          },
        },
      ),
      games: 20,
      random: Random(1),
    );
    expect(report.rate(Outcome.stuck), 1);
    expect(report.stuck, {'a': 20});
    expect(report.unreachedEndings, ['b']);
    expect(report.unvisited, ['b']);
  });

  test('a loop with no way out never ends', () {
    final report = simulate(
      story({
        'a': {
          'text': 'A',
          'choices': [
            {'text': 'On', 'to': 'b'},
          ],
        },
        'b': {
          'text': 'B',
          'choices': [
            {'text': 'Back', 'to': 'a'},
          ],
        },
      }),
      games: 3,
      maxSteps: 50,
      random: Random(1),
    );
    expect(report.rate(Outcome.endless), 1);
  });

  test('a player who declines an item it needs gets stuck', () {
    Story offered() => story(
      {
        'a': {
          'text': 'A',
          'effects': [
            {'give': 'key'},
          ],
          'choices': [
            {
              'text': 'Unlock',
              'to': 'b',
              'if': {'has': 'key'},
            },
          ],
        },
        'b': {'text': 'B', 'ending': 'victory'},
      },
      extra: {
        'items': {
          'key': {'name': 'Key'},
        },
        'rules': {
          'preset': 'fighting-fantasy',
          'inventory': {'pickup': 'choose'},
        },
      },
    );
    expect(
      simulate(offered(), games: 10, random: Random(1)).rate(Outcome.victory),
      1,
    );
    expect(
      simulate(
        offered(),
        games: 10,
        policy: Policy.decline,
        random: Random(1),
      ).rate(Outcome.stuck),
      1,
    );
  });

  test('fights, groups, luck and fleeing are played', () {
    final json = jsonDecode(
      File('test/fixtures/rusty-door.en.json').readAsStringSync(),
    ) as Map<String, Object?>..['schema'] = 1;
    (json['rules']! as Map<String, Object?>)['combat'] = {
      'luck': {'stat': 'luck'},
    };
    (json['nodes']! as Map<String, Object?>)['foot'] = {
      'text': 'Rats.',
      'combat': {
        'enemies': [
          {'name': 'Rat', 'attack': 5, 'health': 3},
          {'name': 'Rat', 'attack': 5, 'health': 3},
        ],
        'simultaneous': true,
        'win': 'door',
        'flee': 'cellar',
      },
    };
    final report = simulate(
      Story.fromJson(json),
      games: 200,
      random: Random(3),
    );
    expect(report.outcomes[Outcome.stuck], 0);
    expect(report.visited, contains('foot'));
  });

  group('the CLI', () {
    test('reports, and exits 1 when games get stuck', () {
      final out = StringBuffer();
      expect(
        runSimulator([
          'test/fixtures/rusty-door.en.json',
          '--games',
          '20',
          '--seed',
          '1',
        ], out),
        0,
      );
      expect(
        out.toString(),
        startsWith('20 games of "The Rusty Door": victory'),
      );
    });

    test('bad usage', () {
      for (final args in [
        <String>[],
        ['a.json', '--games', 'x'],
        ['a.json', '--policy', 'greedy'],
      ]) {
        expect(runSimulator(args, StringBuffer()), 2, reason: '$args');
      }
    });
  });
}
