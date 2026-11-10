import 'dart:convert';
import 'dart:io';

import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

Map<String, Object?> validJson() =>
    jsonDecode(File('test/fixtures/rusty-door.en.json').readAsStringSync())
        as Map<String, Object?>;

/// The error message produced by parsing the valid story after [mutate].
String failure(void Function(Map<String, Object?> json) mutate) {
  final json = validJson();
  mutate(json);
  try {
    Story.fromJson(json);
  } on StoryFormatException catch (e) {
    return e.toString();
  }
  fail('expected a StoryFormatException');
}

Map<String, Object?> node(Map<String, Object?> json, String id) =>
    ((json['nodes']! as Map<String, Object?>)[id]! as Map<String, Object?>);

Map<String, Object?> choice(Map<String, Object?> json, String id, int i) =>
    (node(json, id)['choices']! as List<Object?>)[i]! as Map<String, Object?>;

void main() {
  test('parses the valid story', () {
    final story = Story.parse(
      File('test/fixtures/rusty-door.en.json').readAsStringSync(),
    );

    expect(story.id, 'rusty-door');
    expect(story.rules.preset, 'fighting-fantasy');
    expect(story.items['rusty-key']!.name, 'Rusty key');
    expect(story.nodes.keys, ['cellar', 'shelves', 'door', 'foot', 'treasure']);
    expect(story.nodes['shelves']!.once, isTrue);
    expect(story.nodes['shelves']!.effects.single, isA<GiveItem>());
    expect(story.nodes['treasure']!.ending, Ending.victory);

    final unlock = story.nodes['door']!.choices[0];
    expect(unlock.to, 'treasure');
    expect((unlock.condition! as HasItem).item, 'rusty-key');

    final kick = story.nodes['door']!.choices[1].check!;
    expect(kick.add, isA<StatRef>());
    expect((kick.vs as Const).value, 15);
    expect(kick.op, CheckOp.gte);
    expect(kick.fail, 'foot');
  });

  test('parses combat, nested conditions and stat effects', () {
    final json = validJson();
    node(json, 'treasure')
      ..remove('ending')
      ..['combat'] = {
        'enemies': [
          {'name': 'Goblin', 'attack': 7, 'health': 6, 'damage': '1d6'},
        ],
        'win': 'cellar',
        'flee': 'door',
      };
    node(json, 'door')['choices'] = [
      {
        'text': 'x',
        'to': 'cellar',
        'if': {
          'all': [
            {'stat': 'skill', 'gte': 8},
            {
              'not': {'flag': 'angry'},
            },
            {
              'any': [
                {'visited': 'shelves'},
                {'stat': 'luck', 'eq': 3},
              ],
            },
          ],
        },
      },
    ];

    final story = Story.fromJson(json);

    final fight = story.nodes['treasure']!.combat!;
    expect(fight.enemies.single.damage, '1d6');
    expect(fight.flee, 'door');
    final all = story.nodes['door']!.choices.single.condition! as All;
    expect((all.conditions[0] as StatCompare).op, CompareOp.gte);
    expect(all.conditions[1], isA<Not>());
    expect((all.conditions[2] as Any).conditions, hasLength(2));
  });

  test(r'accepts the editor hint $schema', () {
    final json = validJson()..[r'$schema'] = '../story.schema.json';
    expect(Story.fromJson(json).id, 'rusty-door');
  });

  group('authoring fields (schema 6)', () {
    Map<String, Object?> authored() => validJson()
      ..['schema'] = 6
      ..['showTitles'] = true
      ..['chapters'] = {
        'below': {'title': 'Act 1: Below'},
        'out': {'title': 'Act 2: Out'},
      };

    test('titles, notes, chapters and showTitles are read', () {
      final json = authored();
      node(json, 'cellar')
        ..['title'] = 'Cellar'
        ..['note'] = 'Keep it short.'
        ..['chapter'] = 'below';
      final story = Story.fromJson(json);

      expect(story.showTitles, isTrue);
      expect(story.chapters.keys, ['below', 'out']);
      expect(story.chapters['out']!.title, 'Act 2: Out');
      final cellar = story.nodes['cellar']!;
      expect(
        (cellar.title, cellar.note, cellar.chapter),
        ('Cellar', 'Keep it short.', 'below'),
      );
      expect(story.nodes['door']!.title, isNull);
    });

    test('they default to nothing', () {
      final story = Story.fromJson(validJson());
      expect(story.showTitles, isFalse);
      expect(story.chapters, isEmpty);
      expect(story.nodes['cellar']!.chapter, isNull);
    });

    test('a chapter must be one of the story\'s chapters', () {
      final json = authored();
      node(json, 'door')['chapter'] = 'attic';
      expect(
        () => Story.fromJson(json),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'nodes.door.chapter: unknown chapter "attic"',
          ),
        ),
      );
    });

    test('an empty title is an error', () {
      final json = authored();
      node(json, 'door')['title'] = '  ';
      expect(
        () => Story.fromJson(json),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'nodes.door.title: must not be empty',
          ),
        ),
      );
    });

    for (final (field, mutate)
        in <(String, void Function(Map<String, Object?>))>[
          ('showTitles', (j) => j['showTitles'] = false),
          (
            'chapters',
            (j) => j['chapters'] = {
              'a': {'title': 'A'},
            },
          ),
          ('nodes.door.title', (j) => node(j, 'door')['title'] = 'Door'),
          ('nodes.door.note', (j) => node(j, 'door')['note'] = 'x'),
        ]) {
      test('$field needs schema 6', () {
        expect(
          failure((j) {
            j['schema'] = 5;
            mutate(j);
          }),
          '$field: needs "schema": 6',
        );
      });
    }
  });

  group('draft pages (schema 6)', () {
    test('a draft may have no text and no way out', () {
      final json = validJson()..['schema'] = 6;
      (json['nodes']! as Map<String, Object?>)['foot'] = {
        'draft': true,
        'title': 'Hurt foot',
      };
      final foot = Story.fromJson(json).nodes['foot']!;
      expect(foot.draft, isTrue);
      expect(foot.parts, isEmpty);
      expect(foot.choices, isEmpty);
    });

    test('a draft keeps what it has, even two ways out', () {
      final json = validJson()..['schema'] = 6;
      node(json, 'door')
        ..['draft'] = true
        ..['ending'] = 'death';
      final door = Story.fromJson(json).nodes['door']!;
      expect(door.choices, hasLength(2));
      expect(door.ending, Ending.death);
    });

    test('what a draft has must still be valid', () {
      expect(
        failure((j) {
          j['schema'] = 6;
          node(j, 'door')
            ..['draft'] = true
            ..['ending'] = 'maybe';
        }),
        'nodes.door.ending: expected "victory" or "death"',
      );
    });

    test('a page that is not a draft still needs a way out', () {
      expect(
        failure((j) {
          j['schema'] = 6;
          node(j, 'door')
            ..['draft'] = false
            ..remove('choices');
        }),
        startsWith('nodes.door: needs exactly one of'),
      );
    });

    test('draft needs schema 6', () {
      expect(
        failure((j) => node(j, 'door')['draft'] = true),
        'nodes.door.draft: needs "schema": 6',
      );
    });
  });

  group('quantities and limits (schema 5)', () {
    String error(
      void Function(Map<String, Object?> j) change, {
      int schema = 4,
    }) {
      final json = validJson()..['schema'] = schema;
      change(json);
      try {
        Story.fromJson(json);
      } on StoryFormatException catch (e) {
        return e.toString();
      }
      fail('expected a StoryFormatException');
    }

    test('a stat limit, a stat comparison and set need schema 5', () {
      expect(
        error(
          (j) => (j['rules']! as Map<String, Object?>)['stats'] = {
            'gold': {'roll': '0', 'limit': 50},
          },
        ),
        'rules.stats.gold.limit: needs "schema": 5',
      );
      expect(
        error(
          (j) => choice(j, 'door', 0)['if'] = {
            'stat': 'skill',
            'gte': {'stat': 'luck'},
          },
        ),
        'nodes.door.choices[0].if: needs "schema": 5',
      );
      expect(
        error(
          (j) => node(j, 'foot')['effects'] = [
            {'stat': 'stamina', 'set': 0},
          ],
        ),
        'nodes.foot.effects[0]: needs "schema": 5',
      );
      expect(
        error(
          (j) => choice(j, 'cellar', 0)['effects'] = [
            {
              'stat': 'stamina',
              'add': {'stat': 'luck'},
            },
          ],
        ),
        'nodes.cellar.choices[0].effects[0]: needs "schema": 5',
      );
      expect(
        error(
          (j) => node(j, 'cellar')['text'] = [
            'a',
            {
              'if': {
                'stat': 'skill',
                'gte': {'stat': 'luck'},
              },
              'text': 'b',
            },
          ],
        ),
        'nodes.cellar.text[1].if: needs "schema": 5',
      );
    });

    test('plain numbers and add stay valid before schema 5', () {
      final json = validJson()..['schema'] = 4;
      choice(json, 'door', 0)['if'] = {'stat': 'skill', 'gte': 8};
      node(json, 'foot')['effects'] = [
        {'stat': 'stamina', 'add': -2},
      ];

      expect(() => Story.fromJson(json), returnsNormally);
    });

    test('they parse in schema 5', () {
      final json = validJson()..['schema'] = 5;
      (json['rules']! as Map<String, Object?>)['stats'] = {
        'gold': {'roll': '0', 'limit': 50},
      };
      choice(json, 'door', 0)['if'] = {
        'stat': 'gold',
        'gte': {'stat': 'skill', 'times': 2},
      };
      node(json, 'foot')['effects'] = [
        {'stat': 'gold', 'set': 0},
      ];

      final story = Story.fromJson(json);

      expect(story.rules.stats['gold']!.limit, 50);
      final cond = story.nodes['door']!.choices[0].condition! as StatCompare;
      expect(cond.value.stat, 'skill');
      expect(cond.value.times, 2);
      final effect = story.nodes['foot']!.effects.single as StatChange;
      expect(effect.replace, isTrue);
    });
  });

  group('writing features (schema 4)', () {
    group('page text', () {
      Map<String, Object?> v4() => validJson()..['schema'] = 4;

      test('a plain string is one part', () {
        final node = Story.fromJson(validJson()).nodes['cellar']!;

        expect(node.parts, hasLength(1));
        expect(node.parts.single.condition, isNull);
        expect(node.textIsList, isFalse);
        expect(node.text, startsWith('You wake in a cold cellar'));
      });

      test('a list has plain and conditional parts', () {
        final json = v4();
        node(json, 'cellar')['text'] = [
          'First.',
          {
            'if': {'flag': 'met'},
            'text': 'Second.',
          },
          {'text': 'Third.'},
        ];

        final n = Story.fromJson(json).nodes['cellar']!;

        expect(n.textIsList, isTrue);
        expect(n.parts.map((p) => p.text), ['First.', 'Second.', 'Third.']);
        expect(n.parts.map((p) => p.condition.runtimeType), [
          Null,
          FlagSet,
          Null,
        ]);
        expect(n.text, 'First.\n\nSecond.\n\nThird.');
      });

      test('a list needs schema 4', () {
        final json = validJson()..['schema'] = 3;
        node(json, 'cellar')['text'] = ['One.', 'Two.'];

        expect(
          () => Story.fromJson(json),
          throwsA(
            isA<StoryFormatException>().having(
              (e) => e.toString(),
              'message',
              'nodes.cellar.text: needs "schema": 4',
            ),
          ),
        );
      });

      test('text errors name the path', () {
        String error(Object? text, {int schema = 4}) {
          final json = validJson()..['schema'] = schema;
          node(json, 'cellar')['text'] = text;
          try {
            Story.fromJson(json);
          } on StoryFormatException catch (e) {
            return e.toString();
          }
          fail('expected a StoryFormatException');
        }

        expect(
          error(<Object?>[]),
          'nodes.cellar.text: needs at least one part',
        );
        expect(
          error(5),
          'nodes.cellar.text: expected a string or a list of parts',
        );
        expect(
          error([
            'ok',
            {
              'if': {'flag': 'x'},
            },
          ]),
          'nodes.cellar.text[1].text: missing',
        );
        expect(
          error([
            {'text': 'x', 'extra': 1},
          ]),
          'nodes.cellar.text[0].extra: unknown key',
        );
        expect(
          error([
            {
              'text': 'x',
              'if': {'has': 'a', 'flag': 'b'},
            },
          ]),
          startsWith('nodes.cellar.text[0].if: a condition needs exactly one'),
        );
      });

      test('in schema 4 bad placeholders are rejected, with the path', () {
        String error(void Function(Map<String, Object?> json) change) {
          final json = v4();
          change(json);
          try {
            Story.fromJson(json);
          } on StoryFormatException catch (e) {
            return e.toString();
          }
          fail('expected a StoryFormatException');
        }

        expect(
          error((j) => node(j, 'cellar')['text'] = 'You have {gold'),
          startsWith('nodes.cellar.text: unclosed'),
        );
        expect(
          error((j) => node(j, 'cellar')['text'] = ['ok', 'stray } here']),
          startsWith('nodes.cellar.text[1]: stray'),
        );
        expect(
          error((j) => choice(j, 'cellar', 0)['text'] = 'Take {}'),
          startsWith('nodes.cellar.choices[0].text: bad placeholder'),
        );
      });

      test('before schema 4 braces are just text', () {
        final json = validJson();
        node(json, 'cellar')['text'] = 'A {strange} } thing';

        expect(
          Story.fromJson(json).nodes['cellar']!.text,
          'A {strange} } thing',
        );
      });
    });

    test('a choice can be once-only', () {
      final json = validJson()..['schema'] = 4;
      choice(json, 'cellar', 0)['once'] = true;

      final story = Story.fromJson(json);

      expect(story.nodes['cellar']!.choices[0].once, isTrue);
      expect(story.nodes['cellar']!.choices[1].once, isFalse);
    });

    test('parses a visits condition, alone or nested', () {
      final json = validJson()..['schema'] = 4;
      choice(json, 'door', 0)['if'] = {
        'all': [
          {'visits': 'cellar', 'gte': 2},
          {
            'not': {'visits': 'foot', 'eq': 0},
          },
        ],
      };

      final all =
          Story.fromJson(json).nodes['door']!.choices[0].condition! as All;

      final first = all.conditions[0] as VisitCount;
      expect((first.node, first.op, first.value), ('cellar', CompareOp.gte, 2));
      expect(((all.conditions[1] as Not).condition as VisitCount).value, 0);
    });

    test('a visits condition needs one comparison and schema 4', () {
      String error(Map<String, Object?> condition, {int schema = 4}) {
        final json = validJson()..['schema'] = schema;
        choice(json, 'door', 0)['if'] = condition;
        try {
          Story.fromJson(json);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(
        error({'visits': 'cellar'}),
        'nodes.door.choices[0].if: a visits condition needs exactly one of gte, lte, eq',
      );
      expect(
        error({'visits': 'cellar', 'gte': 1}, schema: 3),
        'nodes.door.choices[0].if: needs "schema": 4',
      );
      expect(
        error({
          'not': {'visits': 'cellar', 'gte': 1},
        }, schema: 3),
        'nodes.door.choices[0].if: needs "schema": 4',
      );
    });

    Map<String, Object?> table({
      String roll = '1d6',
      List<Map<String, Object?>>? outcomes,
    }) => {
      'roll': roll,
      'outcomes':
          outcomes ??
          [
            {'upTo': 2, 'to': 'foot'},
            {
              'upTo': 6,
              'to': 'treasure',
              'effects': [
                {'stat': 'luck', 'add': 1},
              ],
            },
          ],
    };

    Map<String, Object?> tableChoice(Map<String, Object?> json) {
      final c = choice(json, 'door', 0)
        ..remove('to')
        ..remove('if');
      return c;
    }

    test('parses a random table', () {
      final json = validJson()..['schema'] = 4;
      tableChoice(json)['table'] = table();

      final parsed = Story.fromJson(json).nodes['door']!.choices[0];

      expect(parsed.to, isNull);
      expect(parsed.table!.roll, '1d6');
      expect(parsed.table!.outcomes.map((o) => (o.upTo, o.to)), [
        (2, 'foot'),
        (6, 'treasure'),
      ]);
      expect(parsed.table!.outcomes.last.effects.single, isA<StatChange>());
      expect(parsed.table!.outcomeFor(2).to, 'foot');
      expect(parsed.table!.outcomeFor(3).to, 'treasure');
      expect(parsed.table!.outcomeFor(99).to, 'treasure');
    });

    test('a table needs schema 4', () {
      final json = validJson()..['schema'] = 3;
      tableChoice(json)['table'] = table();

      expect(
        () => Story.fromJson(json),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'nodes.door.choices[0].table: needs "schema": 4',
          ),
        ),
      );
    });

    test('table errors name the path', () {
      String error(Map<String, Object?> t, {bool keepTo = false}) {
        final json = validJson()..['schema'] = 4;
        final c = tableChoice(json)..['table'] = t;
        if (keepTo) c['to'] = 'treasure';
        try {
          Story.fromJson(json);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(
        error(table(), keepTo: true),
        'nodes.door.choices[0]: needs exactly one of "to", "check" or "table"',
      );
      expect(
        error(table(outcomes: [])),
        'nodes.door.choices[0].table.outcomes: needs at least one',
      );
      expect(
        error(
          table(
            outcomes: [
              {'upTo': 4, 'to': 'foot'},
              {'upTo': 4, 'to': 'treasure'},
            ],
          ),
        ),
        'nodes.door.choices[0].table.outcomes[1].upTo: must be greater than the one before (4)',
      );
      expect(
        error(
          table(
            outcomes: [
              {'upTo': 2, 'to': 'foot'},
              {'upTo': 5, 'to': 'treasure'},
            ],
          ),
        ),
        'nodes.door.choices[0].table.outcomes[1].upTo: must be at least 6, the largest possible roll of 1d6',
      );
      expect(
        error(table(roll: 'lots')),
        startsWith('nodes.door.choices[0].table.roll: invalid dice notation'),
      );
      expect(
        error({...table(), 'extra': 1}),
        'nodes.door.choices[0].table.extra: unknown key',
      );
    });

    test('needs schema 4', () {
      final json = validJson()..['schema'] = 3;
      choice(json, 'door', 0)['once'] = true;

      expect(
        () => Story.fromJson(json),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'nodes.door.choices[0].once: needs "schema": 4',
          ),
        ),
      );
    });
  });

  group('limited pack (schema 3)', () {
    Map<String, Object?> v3() => validJson()..['schema'] = 3;

    void inventory(Map<String, Object?> json, Map<String, Object?> block) =>
        (json['rules']! as Map<String, Object?>)['inventory'] = block;

    test('parses capacity and pickup', () {
      final json = v3();
      inventory(json, {'capacity': 3, 'pickup': 'choose'});

      final spec = Story.fromJson(json).rules.inventory!;

      expect(spec.capacity, 3);
      expect(spec.pickup, PickupMode.choose);
    });

    test('both fields are optional', () {
      final json = v3();
      inventory(json, {});

      final spec = Story.fromJson(json).rules.inventory!;

      expect(spec.capacity, isNull);
      expect(spec.pickup, isNull);
    });

    test('parses a container item and takeAll', () {
      final json = v3();
      (json['items']! as Map<String, Object?>)['bag'] = {
        'name': 'Bag',
        'capacity': 4,
      };
      node(json, 'foot')['effects'] = [
        {'takeAll': true},
      ];

      final story = Story.fromJson(json);

      expect(story.items['bag']!.capacity, 4);
      expect(story.items['rusty-key']!.capacity, isNull);
      expect(story.nodes['foot']!.effects.single, isA<TakeAll>());
    });

    test('every feature needs schema 3', () {
      String error(void Function(Map<String, Object?> json) change) {
        final json = validJson()..['schema'] = 2;
        change(json);
        try {
          Story.fromJson(json);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(
        error((j) => inventory(j, {'capacity': 3})),
        'rules.inventory: needs "schema": 3',
      );
      expect(
        error(
          (j) => (j['items']! as Map<String, Object?>)['bag'] = {
            'name': 'Bag',
            'capacity': 2,
          },
        ),
        'items.bag.capacity: needs "schema": 3',
      );
      expect(
        error(
          (j) => node(j, 'foot')['effects'] = [
            {'takeAll': true},
          ],
        ),
        'nodes.foot.effects[0]: needs "schema": 3',
      );
      expect(
        error(
          (j) => choice(j, 'door', 1)['check'] = {
            'roll': '1d6',
            'op': 'gte',
            'vs': 3,
            'pass': 'treasure',
            'fail': 'foot',
            'effects': [
              {'takeAll': true},
            ],
          },
        ),
        'nodes.door.choices[1].check.effects[0]: needs "schema": 3',
      );
      expect(
        error(
          (j) => choice(j, 'cellar', 0)['effects'] = [
            {'takeAll': true},
          ],
        ),
        'nodes.cellar.choices[0].effects[0]: needs "schema": 3',
      );
    });

    test('errors name the path', () {
      String error(Map<String, Object?> block) {
        final json = v3();
        inventory(json, block);
        try {
          Story.fromJson(json);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(
        error({'capacity': 0}),
        'rules.inventory.capacity: must be at least 1',
      );
      expect(
        error({'pickup': 'ask'}),
        'rules.inventory.pickup: expected "auto" or "choose"',
      );
      expect(error({'size': 3}), 'rules.inventory.size: unknown key');
    });

    test('bad container capacity and takeAll values', () {
      final json = v3();
      (json['items']! as Map<String, Object?>)['bag'] = {
        'name': 'Bag',
        'capacity': 0,
      };
      expect(
        () => Story.fromJson(json),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'items.bag.capacity: must be at least 1',
          ),
        ),
      );

      final other = v3();
      node(other, 'foot')['effects'] = [
        {'takeAll': false},
      ];
      expect(
        () => Story.fromJson(other),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'nodes.foot.effects[0].takeAll: must be true',
          ),
        ),
      );
    });
  });

  group('usable items', () {
    Map<String, Object?> potion(Map<String, Object?> use) {
      return {'name': 'Potion', 'use': use};
    }

    void define(Map<String, Object?> json, Map<String, Object?> use) {
      json['schema'] = 2;
      (json['items']! as Map<String, Object?>)['potion'] = potion(use);
    }

    test('parses effects, where it works and the combat cost', () {
      final json = validJson();
      define(json, {
        'effects': [
          {'stat': 'stamina', 'add': 6},
        ],
        'when': ['story', 'combat'],
        'combatCost': 'free',
      });

      final use = Story.fromJson(json).items['potion']!.use!;

      expect(use.effects.single, isA<StatChange>());
      expect(use.when, {UseWhen.story, UseWhen.combat});
      expect(use.combatCost, CombatCost.free);
    });

    test('the combat cost defaults to the round', () {
      final json = validJson();
      define(json, {
        'effects': <Object?>[],
        'when': ['combat'],
      });

      expect(
        Story.fromJson(json).items['potion']!.use!.combatCost,
        CombatCost.round,
      );
    });

    test('an item without use stays plain', () {
      expect(Story.fromJson(validJson()).items['rusty-key']!.use, isNull);
    });

    test('needs schema 2', () {
      final json = validJson();
      define(json, {
        'effects': <Object?>[],
        'when': ['story'],
      });
      json['schema'] = 1;

      expect(
        () => Story.fromJson(json),
        throwsA(
          isA<StoryFormatException>().having(
            (e) => e.toString(),
            'message',
            'items.potion.use: needs "schema": 2',
          ),
        ),
      );
    });

    test('errors name the path', () {
      String error(Map<String, Object?> use) {
        final json = validJson();
        define(json, use);
        try {
          Story.fromJson(json);
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(
        error({
          'when': ['story'],
        }),
        'items.potion.use.effects: missing',
      );
      expect(error({'effects': <Object?>[]}), 'items.potion.use.when: missing');
      expect(
        error({'effects': <Object?>[], 'when': <Object?>[]}),
        startsWith('items.potion.use.when: needs at least one'),
      );
      expect(
        error({
          'effects': <Object?>[],
          'when': ['night'],
        }),
        'items.potion.use.when[0]: expected "story" or "combat"',
      );
      expect(
        error({
          'effects': <Object?>[],
          'when': ['combat'],
          'combatCost': 'half',
        }),
        'items.potion.use.combatCost: expected "round" or "free"',
      );
      expect(
        error({
          'effects': <Object?>[],
          'when': ['story'],
          'combatCost': 'round',
        }),
        'items.potion.use.combatCost: only applies to items usable in "combat"',
      );
      expect(
        error({
          'effects': <Object?>[],
          'when': ['story'],
          'extra': 1,
        }),
        'items.potion.use.extra: unknown key',
      );
    });
  });

  test('rejects invalid JSON', () {
    expect(
      () => Story.parse('{'),
      throwsA(
        isA<StoryFormatException>().having(
          (e) => e.toString(),
          'message',
          startsWith('invalid JSON'),
        ),
      ),
    );
  });

  group('errors name the JSON path', () {
    test('unsupported schema', () {
      expect(failure((j) => j['schema'] = 7), startsWith('schema:'));
    });

    test('unknown top-level key', () {
      expect(failure((j) => j['typo'] = 1), 'typo: unknown key');
    });

    test('missing field', () {
      expect(failure((j) => j.remove('start')), 'start: missing');
    });

    test('bad story id', () {
      expect(failure((j) => j['id'] = 'Not A Slug'), startsWith('id:'));
    });

    test('bad node id', () {
      expect(
        failure((j) => (j['nodes']! as Map<String, Object?>)['a b'] = {}),
        startsWith('nodes: invalid id "a b"'),
      );
    });

    test('node with choices and ending', () {
      expect(
        failure((j) => node(j, 'cellar')['ending'] = 'death'),
        startsWith('nodes.cellar: needs exactly one of'),
      );
    });

    test('node with nothing to do', () {
      expect(
        failure((j) => node(j, 'treasure').remove('ending')),
        startsWith('nodes.treasure: needs exactly one of'),
      );
    });

    test('bad ending', () {
      expect(
        failure((j) => node(j, 'treasure')['ending'] = 'meh'),
        startsWith('nodes.treasure.ending:'),
      );
    });

    test('choice without to or check', () {
      expect(
        failure(
          (j) => node(j, 'cellar')['choices'] = [
            {'text': 'x'},
          ],
        ),
        'nodes.cellar.choices[0]: needs exactly one of "to", "check" or "table"',
      );
    });

    test('wrong type', () {
      expect(
        failure(
          (j) =>
              (node(j, 'cellar')['choices']! as List<Object?>)
                      .cast<Map<String, Object?>>()[0]['to'] =
                  5,
        ),
        'nodes.cellar.choices[0].to: expected a string',
      );
    });

    test('condition with two kinds', () {
      expect(
        failure(
          (j) =>
              (node(j, 'door')['choices']! as List<Object?>)
                  .cast<Map<String, Object?>>()[0]['if'] = {
                'has': 'a',
                'flag': 'b',
              },
        ),
        startsWith('nodes.door.choices[0].if: a condition needs exactly one'),
      );
    });

    test('stat condition without comparison', () {
      expect(
        failure(
          (j) =>
              (node(j, 'door')['choices']! as List<Object?>)
                  .cast<Map<String, Object?>>()[0]['if'] = {
                'stat': 'skill',
              },
        ),
        startsWith('nodes.door.choices[0].if: a stat condition needs'),
      );
    });

    test('unknown effect', () {
      expect(
        failure(
          (j) => node(j, 'foot')['effects'] = [
            {'boom': 'x'},
          ],
        ),
        startsWith('nodes.foot.effects[0]: an effect needs exactly one'),
      );
    });

    test('effect with extra key', () {
      expect(
        failure(
          (j) => node(j, 'shelves')['effects'] = [
            {'give': 'rusty-key', 'add': 2},
          ],
        ),
        'nodes.shelves.effects[0].add: unknown key',
      );
    });

    test('bad check operator', () {
      Map<String, Object?> check(Map<String, Object?> j) =>
          ((node(j, 'door')['choices']! as List<Object?>)[1]!
                  as Map<String, Object?>)['check']!
              as Map<String, Object?>;
      expect(
        failure((j) => check(j)['op'] = 'eq'),
        'nodes.door.choices[1].check.op: expected "gte" or "lte"',
      );
      expect(
        failure((j) => check(j)['vs'] = true),
        'nodes.door.choices[1].check.vs: expected an integer or a stat id',
      );
      expect(
        failure((j) => check(j)['extra'] = 1),
        'nodes.door.choices[1].check.extra: unknown key',
      );
    });

    test('combat without enemies', () {
      expect(
        failure(
          (j) => node(j, 'treasure')
            ..remove('ending')
            ..['combat'] = {'enemies': <Object?>[], 'win': 'cellar'},
        ),
        'nodes.treasure.combat.enemies: needs at least one enemy',
      );
    });

    test('unknown key in rules', () {
      expect(
        failure((j) => (j['rules']! as Map<String, Object?>)['x'] = 1),
        'rules.x: unknown key',
      );
    });
  });
}
