import 'dart:convert';
import 'dart:io';

import 'package:gamebook_engine/graph.dart';
import 'package:gamebook_engine/quantity.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

Story rustyDoor() =>
    Story.parse(File('test/fixtures/rusty-door.en.json').readAsStringSync());

const dot = r'''
digraph "rusty-door" {
  rankdir=TB;
  node [shape=box, style=rounded, fontname="Helvetica"];
  edge [fontname="Helvetica", fontsize=10];
  "cellar" [label="cellar\nYou wake in a cold cellar. Shelves line…", penwidth=3];
  "shelves" [label="shelves\nBehind a jar you find a rusty key."];
  "door" [label="door\nThe door is locked."];
  "foot" [label="foot\nOuch. The door does not move."];
  "treasure" [label="treasure\nA chest of gold. You win!", style="rounded,filled", fillcolor="#c8e6c9"];
  "cellar" -> "shelves" [label="Search the shelves"];
  "cellar" -> "door" [label="Go to the door"];
  "shelves" -> "cellar" [label="Go back"];
  "door" -> "treasure" [label="Unlock it\n[has rusty-key]", style=dashed];
  "door" -> "treasure" [label="Kick it open\npass: 2d6+skill >= 15", color="#2e7d32"];
  "door" -> "foot" [label="Kick it open\nfail", color="#c62828"];
  "foot" -> "door" [label="Try something else"];
}
''';

const mermaid = '''
flowchart TD
  n_cellar["cellar<br/>You wake in a cold cellar. Shelves line…"]
  n_shelves["shelves<br/>Behind a jar you find a rusty key."]
  n_door["door<br/>The door is locked."]
  n_foot["foot<br/>Ouch. The door does not move."]
  n_treasure(["treasure<br/>A chest of gold. You win!"])
  n_cellar -->|"Search the shelves"| n_shelves
  n_cellar -->|"Go to the door"| n_door
  n_shelves -->|"Go back"| n_cellar
  n_door -.->|"Unlock it<br/>[has rusty-key]"| n_treasure
  n_door -->|"Kick it open<br/>pass: 2d6+skill >= 15"| n_treasure
  n_door -->|"Kick it open<br/>fail"| n_foot
  n_foot -->|"Try something else"| n_door
''';

Story fightStory() => Story.fromJson({
  'schema': 1,
  'id': 'f',
  'lang': 'en',
  'title': 'F',
  'rules': {'preset': 'fighting-fantasy'},
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A "quoted" start',
      'choices': [
        {
          'text': 'Go',
          'to': 'ring',
          'if': {
            'all': [
              {'stat': 'skill', 'gte': 8},
              {
                'not': {'flag': 'x'},
              },
            ],
          },
        },
      ],
    },
    'ring': {
      'text': 'Fight',
      'combat': {
        'enemies': [
          {'name': 'Rat', 'attack': 5, 'health': 3},
        ],
        'win': 'end',
        'flee': 'a',
      },
    },
    'end': {'text': 'Dead', 'ending': 'death'},
  },
});

void main() {
  test('storyEdges gives each exit its kind, choice and port', () {
    final json = jsonDecode(
      File('test/fixtures/rusty-door.en.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final nodes = json['nodes']! as Map<String, Object?>;
    nodes['foot'] = {
      'text': 'A rat bites.',
      'combat': {
        'enemies': [
          {'name': 'Rat', 'attack': 5, 'health': 2},
        ],
        'win': 'door',
        'flee': 'cellar',
      },
    };
    final edges = [
      for (final e in storyEdges(Story.fromJson(json)))
        if (e.from == 'door' || e.from == 'foot')
          (e.to, e.kind, e.choice, e.port),
    ];

    expect(edges, [
      ('treasure', EdgeKind.locked, 0, 0),
      ('treasure', EdgeKind.pass, 1, 0),
      ('foot', EdgeKind.fail, 1, 1),
      ('door', EdgeKind.win, null, 0),
      ('cellar', EdgeKind.flee, null, 1),
    ]);
  });

  test('DOT output for the rusty door', () {
    expect(toDot(rustyDoor()), dot);
  });

  test('DOT colours a defeat ending apart from victory and death', () {
    final out = toDot(
      Story.fromJson({
        'schema': 1,
        'id': 'd',
        'lang': 'en',
        'title': 'D',
        'rules': {'preset': 'fighting-fantasy'},
        'start': 'a',
        'nodes': {
          'a': {
            'text': 'A',
            'choices': [
              {'text': 'Go', 'to': 'b'},
            ],
          },
          'b': {'text': 'Lost', 'ending': 'defeat'},
        },
      }),
    );
    expect(
      out,
      contains(
        '"b" [label="b\\nLost", style="rounded,filled", fillcolor="#ffe0b2"];',
      ),
    );
  });

  test("a fight's events are exits of their own", () {
    final story = Story.fromJson({
      'schema': 1,
      'id': 'e',
      'lang': 'en',
      'title': 'E',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'pit',
      'nodes': {
        'pit': {
          'text': 'A scorpion.',
          'combat': {
            'enemies': [
              {'name': 'Scorpion', 'attack': 7, 'health': 6},
            ],
            'win': 'won',
            'wounded': 'stung',
            'rounds': {'after': 3, 'to': 'slow'},
          },
        },
        'won': {'text': 'x', 'ending': 'victory'},
        'stung': {'text': 'x', 'ending': 'defeat'},
        'slow': {'text': 'x', 'ending': 'defeat'},
      },
    });
    expect(
      [for (final e in storyEdges(story)) (e.to, e.kind, e.port)],
      [
        ('won', EdgeKind.win, 0),
        ('stung', EdgeKind.wounded, 2),
        ('slow', EdgeKind.rounds, 3),
      ],
    );
    final dot = toDot(story);
    expect(
      dot,
      contains('"pit" -> "stung" [label="wounded", color="#ef6c00"];'),
    );
    expect(
      dot,
      contains('"pit" -> "slow" [label="after 3 rounds", color="#ef6c00"];'),
    );
  });

  test('Mermaid output for the rusty door', () {
    expect(toMermaid(rustyDoor()), mermaid);
  });

  test('DOT styles fights, flee, death and escapes quotes', () {
    final out = toDot(fightStory());

    expect(out, contains(r'A \"quoted\" start'));
    expect(
      out,
      contains(
        '"ring" [label="ring\\nFight", style="rounded,filled", fillcolor="#f4c7c3"];',
      ),
    );
    expect(
      out,
      contains(
        '"end" [label="end\\nDead", style="rounded,filled", fillcolor="#cccccc"];',
      ),
    );
    expect(out, contains('"ring" -> "end" [label="win", color="#2e7d32"];'));
    expect(out, contains('"ring" -> "a" [label="flee", style=dashed];'));
    expect(out, contains(r'[skill >= 8 and not flag x]'));
    expect(
      describeCondition(const VisitCount('inn', CompareOp.gte, 3)),
      'visits inn >= 3',
    );
  });

  test('Mermaid ids never collide with keywords', () {
    final out = toMermaid(fightStory());

    expect(out, contains('n_end(["end<br/>Dead"])'));
    expect(out, contains('n_ring{{"ring<br/>Fight"}}'));
    expect(out, contains('n_ring -.->|"flee"| n_a'));
    expect(out, contains('A #quot;quoted#quot; start'));
  });

  test('a random table has one edge per outcome with its range', () {
    final story = Story.fromJson({
      'schema': 1,
      'id': 's',
      'lang': 'en',
      'title': 'S',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'a',
      'nodes': {
        'a': {
          'text': 'x',
          'choices': [
            {
              'text': 'Search',
              'table': {
                'roll': '1d6',
                'outcomes': [
                  {'upTo': 1, 'to': 'b'},
                  {'upTo': 4, 'to': 'c'},
                  {'upTo': 6, 'to': 'd'},
                ],
              },
            },
          ],
        },
        'b': {'text': 'y', 'ending': 'death'},
        'c': {'text': 'y', 'ending': 'victory'},
        'd': {'text': 'y', 'ending': 'victory'},
      },
    });

    final dot = toDot(story);

    expect(dot, contains(r'"a" -> "b" [label="Search\nroll 1d6: 1"];'));
    expect(dot, contains(r'"a" -> "c" [label="Search\nroll 1d6: 2-4"];'));
    expect(dot, contains(r'"a" -> "d" [label="Search\nroll 1d6: 5-6"];'));
  });

  test('a stat compared with another stat reads naturally', () {
    expect(
      describeCondition(
        const StatCompare('gold', CompareOp.gte, Quantity.ofStat('price', 2)),
      ),
      'gold >= price*2',
    );
  });

  test('once-only choices say so on the edge', () {
    final story = Story.fromJson({
      'schema': 1,
      'id': 's',
      'lang': 'en',
      'title': 'S',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'a',
      'nodes': {
        'a': {
          'text': 'x',
          'choices': [
            {'text': 'Search', 'to': 'b', 'once': true},
          ],
        },
        'b': {'text': 'y', 'ending': 'victory'},
      },
    });

    expect(toDot(story), contains('label="Search (once)"'));
    expect(toMermaid(story), contains('"Search (once)"'));
  });

  test('titles label the nodes and chapters become clusters', () {
    final json =
        jsonDecode(File('test/fixtures/rusty-door.en.json').readAsStringSync())
              as Map<String, Object?>
          ..['schema'] = 1
          ..['chapters'] = {
            'start': {'title': 'Act "1"'},
          };
    final nodes = json['nodes']! as Map<String, Object?>;
    (nodes['cellar']! as Map<String, Object?>)
      ..['title'] = 'Cold cellar'
      ..['chapter'] = 'start';
    (nodes['shelves']! as Map<String, Object?>)['chapter'] = 'start';
    final story = Story.fromJson(json);

    final dot = toDot(story);
    expect(dot, contains(r'label="Cold cellar [cellar]\nYou wake'));
    expect(
      dot,
      contains(
        '  subgraph "cluster_start" {\n'
        '    label="Act \\"1\\"";\n'
        '    "cellar";\n'
        '    "shelves";\n'
        '  }\n',
      ),
    );
    expect(
      toMermaid(story),
      contains(
        '  subgraph c_start ["Act #quot;1#quot;"]\n'
        '    n_cellar\n'
        '    n_shelves\n'
        '  end\n',
      ),
    );
  });

  test('long text is cut to a one-line excerpt', () {
    final story = Story.fromJson({
      'schema': 1,
      'id': 's',
      'lang': 'en',
      'title': 'S',
      'rules': {'preset': 'fighting-fantasy'},
      'start': 'a',
      'nodes': {
        'a': {'text': 'line one\n\nline   two ' * 10, 'ending': 'death'},
      },
    });

    final label = RegExp(r'label="a\\n([^"]*)"').firstMatch(toDot(story))!;
    expect(label.group(1)!.length, 40);
    expect(label.group(1), endsWith('…'));
    expect(label.group(1), isNot(contains('\n')));
  });
}
