import 'dart:convert';
import 'dart:io';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

Map<String, Object?> validJson() =>
    jsonDecode(File('test/fixtures/rusty-door.en.json').readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?> node(Map<String, Object?> json, String id) =>
    (json['nodes']! as Map<String, Object?>)[id]! as Map<String, Object?>;

Map<String, Object?> choice(Map<String, Object?> json, String id, int i) =>
    (node(json, id)['choices']! as List<Object?>)[i]! as Map<String, Object?>;

List<Issue> issuesOf(
  void Function(Map<String, Object?> json) mutate, {
  bool Function(String)? assetExists,
}) {
  final json = validJson();
  mutate(json);
  return validateStory(Story.fromJson(json), assetExists: assetExists);
}

List<String> errors(
  void Function(Map<String, Object?> json) mutate, {
  bool Function(String)? assetExists,
}) => [
  for (final i in issuesOf(mutate, assetExists: assetExists))
    if (i.severity == Severity.error) i.toString(),
];

List<String> warnings(void Function(Map<String, Object?> json) mutate) => [
  for (final i in issuesOf(mutate))
    if (i.severity == Severity.warning) i.toString(),
];

void fight(Map<String, Object?> json, {Map<String, Object?>? enemy}) {
  node(json, 'treasure')
    ..remove('ending')
    ..['combat'] = {
      'enemies': [
        enemy ?? {'name': 'Rat', 'attack': 5, 'health': 3},
      ],
      'win': 'cellar',
    };
}

void main() {
  test('the valid story has no issues', () {
    expect(issuesOf((_) {}, assetExists: (_) => true), isEmpty);
  });

  group('references', () {
    test('unknown nodes', () {
      expect(
        errors((j) {
          j['start'] = 'nowhere';
          choice(j, 'cellar', 0)['to'] = 'gone';
          final check = choice(j, 'door', 1)['check']! as Map<String, Object?>;
          check['pass'] = 'gone2';
          check['fail'] = 'gone3';
        }),
        unorderedEquals([
          'error: start: unknown node "nowhere"',
          'error: nodes.cellar.choices[0].to: unknown node "gone"',
          'error: nodes.door.choices[1].check.pass: unknown node "gone2"',
          'error: nodes.door.choices[1].check.fail: unknown node "gone3"',
        ]),
      );
    });

    test('unknown combat targets', () {
      expect(
        errors((j) {
          fight(j);
          ((node(j, 'treasure')['combat']! as Map<String, Object?>)
            ..['win'] = 'x'
            ..['flee'] = 'y');
        }),
        containsAll([
          'error: nodes.treasure.combat.win: unknown node "x"',
          'error: nodes.treasure.combat.flee: unknown node "y"',
        ]),
      );
    });

    test('unknown items', () {
      expect(
        errors((j) {
          choice(j, 'door', 0)['if'] = {'has': 'axe'};
          node(j, 'shelves')['effects'] = [
            {'give': 'gem'},
            {'take': 'orb'},
          ];
        }),
        containsAll([
          'error: nodes.door.choices[0].if: unknown item "axe"',
          'error: nodes.shelves.effects[0]: unknown item "gem"',
          'error: nodes.shelves.effects[1]: unknown item "orb"',
        ]),
      );
    });

    test('unknown stats', () {
      expect(
        errors((j) {
          choice(j, 'door', 0)['if'] = {'stat': 'charm', 'gte': 1};
          node(j, 'foot')['effects'] = [
            {'stat': 'mana', 'add': 1},
          ];
          final check = choice(j, 'door', 1)['check']! as Map<String, Object?>;
          check['add'] = 'wit';
          check['vs'] = 'will';
        }),
        containsAll([
          'error: nodes.door.choices[0].if: unknown stat "charm"',
          'error: nodes.foot.effects[0]: unknown stat "mana"',
          'error: nodes.door.choices[1].check.add: unknown stat "wit"',
          'error: nodes.door.choices[1].check.vs: unknown stat "will"',
        ]),
      );
    });

    test('unknown node in a visits condition', () {
      expect(
        errors((j) {
          j['schema'] = 4;
          choice(j, 'door', 0)['if'] = {'visits': 'ghost', 'gte': 1};
        }),
        ['error: nodes.door.choices[0].if: unknown node "ghost"'],
      );
    });

    test('unknown visited node', () {
      expect(errors((j) => choice(j, 'door', 0)['if'] = {'visited': 'ghost'}), [
        'error: nodes.door.choices[0].if: unknown node "ghost"',
      ]);
    });
  });

  group('dice and rules', () {
    test('bad dice in a check and an enemy', () {
      expect(
        errors((j) {
          (choice(j, 'door', 1)['check']! as Map<String, Object?>)['roll'] =
              '2x6';
          fight(
            j,
            enemy: {'name': 'r', 'attack': 1, 'health': 1, 'damage': '0d6'},
          );
        }),
        containsAll([
          startsWith('error: nodes.door.choices[1].check.roll: invalid dice'),
          startsWith('error: nodes.treasure.combat.enemies[0].damage: invalid'),
        ]),
      );
    });

    test('broken rules are reported once and do not hide other checks', () {
      final found = errors((j) {
        j['rules'] = {'preset': 'nope'};
        choice(j, 'cellar', 0)['to'] = 'gone';
      });

      expect(found, [
        'error: rules.preset: unknown preset "nope"',
        'error: nodes.cellar.choices[0].to: unknown node "gone"',
      ]);
    });

    test('a fight needs combat rules', () {
      expect(
        errors((j) {
          j['rules'] = {
            'health': 'hp',
            'stats': {
              'hp': {'roll': '5'},
            },
          };
          choice(j, 'door', 1)['check'] = {
            'roll': '1d6',
            'op': 'gte',
            'vs': 3,
            'pass': 'treasure',
            'fail': 'foot',
          };
          node(j, 'foot')['effects'] = [];
          fight(j);
        }),
        [
          'error: nodes.treasure.combat: the story has a fight but its rules define no combat',
        ],
      );
    });

    test('vs-defense enemies need a defense and health of at least 1', () {
      expect(
        errors((j) {
          j['rules'] = {'preset': 'd20-lite'};
          node(j, 'foot').remove('effects');
          choice(j, 'door', 1)['check'] = {
            'roll': '1d20',
            'op': 'gte',
            'vs': 3,
            'pass': 'treasure',
            'fail': 'foot',
          };
          fight(j, enemy: {'name': 'Rat', 'attack': 1, 'health': 0});
        }),
        unorderedEquals([
          'error: nodes.treasure.combat.enemies[0].health: must be at least 1',
          'error: nodes.treasure.combat.enemies[0]: "Rat" needs a defense (vs-defense combat)',
        ]),
      );
    });
  });

  group('images', () {
    test('missing files are errors, found ones are fine', () {
      final found = errors((j) {
        j['cover'] = 'images/cover.webp';
        node(j, 'cellar')['image'] = 'images/cellar.webp';
        (j['items']! as Map<String, Object?>)['rusty-key'] = {
          'name': 'Key',
          'image': 'images/key.webp',
        };
      }, assetExists: (path) => path == 'images/cellar.webp');

      expect(found, [
        'error: cover: image file not found: images/cover.webp',
        'error: items.rusty-key.image: image file not found: images/key.webp',
      ]);
    });
  });

  group('stat quantities', () {
    test('a stat named in a comparison or an effect must exist', () {
      expect(
        errors((j) {
          j['schema'] = 5;
          choice(j, 'door', 0)['if'] = {
            'stat': 'skill',
            'gte': {'stat': 'price'},
          };
          node(j, 'foot')['effects'] = [
            {
              'stat': 'stamina',
              'add': {'stat': 'loot'},
            },
            {
              'stat': 'stamina',
              'set': {'stat': 'also', 'times': 2},
            },
          ];
        }),
        unorderedEquals([
          'error: nodes.door.choices[0].if: unknown stat "price"',
          'error: nodes.foot.effects[0]: unknown stat "loot"',
          'error: nodes.foot.effects[1]: unknown stat "also"',
        ]),
      );
    });

    test('real stats are fine', () {
      expect(
        issuesOf((j) {
          j['schema'] = 5;
          choice(j, 'door', 0)['if'] = {
            'stat': 'skill',
            'gte': {'stat': 'luck', 'times': 2},
          };
        }),
        isEmpty,
      );
    });
  });

  group('page text', () {
    void v4(Map<String, Object?> j, Object? text) {
      j['schema'] = 4;
      node(j, 'cellar')['text'] = text;
    }

    test('good conditions and placeholders have no issues', () {
      expect(
        issuesOf(
          (j) => v4(j, [
            'You have {stamina} of {stamina.max}.',
            {
              'if': {'has': 'rusty-key'},
              'text': 'The key is heavy.',
            },
          ]),
        ),
        isEmpty,
      );
    });

    test('placeholders must name stats', () {
      expect(
        errors((j) {
          v4(j, ['You have {gold} {stamina}.', 'Also {mana.max}']);
          choice(j, 'cellar', 0)['text'] = 'Pay {crowns}';
        }),
        unorderedEquals([
          'error: nodes.cellar.text[0]: unknown stat "gold"',
          'error: nodes.cellar.text[1]: unknown stat "mana"',
          'error: nodes.cellar.choices[0].text: unknown stat "crowns"',
        ]),
      );
    });

    test('conditions in parts are checked like any other', () {
      expect(
        errors(
          (j) => v4(j, [
            'ok',
            {
              'if': {'has': 'axe'},
              'text': 'x',
            },
            {
              'if': {'visits': 'ghost', 'gte': 1},
              'text': 'y',
            },
          ]),
        ),
        unorderedEquals([
          'error: nodes.cellar.text[1].if: unknown item "axe"',
          'error: nodes.cellar.text[2].if: unknown node "ghost"',
        ]),
      );
    });

    test('a story before schema 4 may use braces freely', () {
      expect(
        issuesOf((j) => node(j, 'cellar')['text'] = 'A {strange} thing'),
        isEmpty,
      );
    });
  });

  group('random tables', () {
    void table(Map<String, Object?> j, List<Map<String, Object?>> outcomes) {
      j['schema'] = 4;
      choice(j, 'cellar', 0)
        ..remove('to')
        ..['table'] = {'roll': '1d6', 'outcomes': outcomes};
    }

    test('a valid table has no issues, and its targets count as reachable', () {
      expect(
        issuesOf(
          (j) => table(j, [
            {'upTo': 3, 'to': 'shelves'},
            {'upTo': 6, 'to': 'door'},
          ]),
        ),
        isEmpty,
      );
    });

    test('outcome targets and effects are checked', () {
      expect(
        errors(
          (j) => table(j, [
            {'upTo': 3, 'to': 'nowhere'},
            {
              'upTo': 6,
              'to': 'door',
              'effects': [
                {'stat': 'mana', 'add': 1},
                {'give': 'gem'},
              ],
            },
          ]),
        ),
        unorderedEquals([
          'error: nodes.cellar.choices[0].table.outcomes[0].to: unknown node "nowhere"',
          'error: nodes.cellar.choices[0].table.outcomes[1].effects[0]: unknown stat "mana"',
          'error: nodes.cellar.choices[0].table.outcomes[1].effects[1]: unknown item "gem"',
        ]),
      );
    });
  });

  group('usable items', () {
    void potion(Map<String, Object?> j, List<Object?> effects) {
      j['schema'] = 2;
      (j['items']! as Map<String, Object?>)['potion'] = {
        'name': 'Potion',
        'use': {
          'effects': effects,
          'when': ['story', 'combat'],
        },
      };
      node(j, 'shelves')['effects'] = [
        {'give': 'rusty-key'},
        {'give': 'potion'},
      ];
    }

    test('a valid one has no issues', () {
      expect(
        issuesOf(
          (j) => potion(j, [
            {'stat': 'stamina', 'add': 6},
          ]),
        ),
        isEmpty,
      );
    });

    test('its effects are checked like any other', () {
      expect(
        errors(
          (j) => potion(j, [
            {'stat': 'mana', 'add': 1},
            {'give': 'gem'},
            {'take': 'orb'},
          ]),
        ),
        unorderedEquals([
          'error: items.potion.use.effects[0]: unknown stat "mana"',
          'error: items.potion.use.effects[1]: unknown item "gem"',
          'error: items.potion.use.effects[2]: unknown item "orb"',
        ]),
      );
    });

    test('a usable item nobody can get is a warning', () {
      final found = warnings((j) {
        potion(j, []);
        node(j, 'shelves')['effects'] = [
          {'give': 'rusty-key'},
        ];
      });

      expect(found, ['warning: items.potion: is usable but never given']);
    });
  });

  group('limited pack', () {
    void v3(Map<String, Object?> j, {Map<String, Object?>? inventory}) {
      j['schema'] = 3;
      (j['rules']! as Map<String, Object?>)['inventory'] = inventory ?? {};
      (j['items']! as Map<String, Object?>)['bag'] = {
        'name': 'Bag',
        'capacity': 2,
      };
      node(j, 'shelves')['effects'] = [
        {'give': 'rusty-key'},
        {'give': 'bag'},
      ];
    }

    test('a container in a story with a capacity is fine', () {
      expect(
        issuesOf((j) => v3(j, inventory: {'capacity': 2, 'pickup': 'choose'})),
        isEmpty,
      );
    });

    test('a container does nothing when the pack is unlimited', () {
      expect(warnings((j) => v3(j, inventory: {'pickup': 'choose'})), [
        'warning: items.bag.capacity: adds pack room but the story has no inventory capacity',
      ]);
    });

    test('takeAll needs no references', () {
      expect(
        issuesOf((j) {
          v3(j, inventory: {'capacity': 2});
          node(j, 'foot')['effects'] = [
            {'takeAll': true},
          ];
        }),
        isEmpty,
      );
    });
  });

  group('warnings', () {
    test('unreachable node', () {
      expect(
        warnings(
          (j) => (j['nodes']! as Map<String, Object?>)['lost'] = {
            'text': 'x',
            'ending': 'death',
          },
        ),
        ['warning: nodes.lost: is unreachable from the start'],
      );
    });

    test('no victory ending reachable', () {
      expect(warnings((j) => node(j, 'treasure')['ending'] = 'death'), [
        'warning: nodes: no victory ending is reachable',
      ]);
    });

    test('item required or taken but never given', () {
      final found = warnings((j) {
        node(j, 'shelves')['effects'] = [];
        node(j, 'foot')['effects'] = [
          {'take': 'rusty-key'},
        ];
      });

      expect(
        found,
        containsAll([
          'warning: nodes.door.choices[0].if: item "rusty-key" is required but never given',
          'warning: nodes.foot.effects[0]: item "rusty-key" is taken but never given',
        ]),
      );
    });

    test('flags set but never checked, checked but never set', () {
      final found = warnings((j) {
        node(j, 'shelves')['effects'] = [
          {'give': 'rusty-key'},
          {'set': 'looked'},
        ];
        choice(j, 'door', 1)['if'] = {'flag': 'angry'};
      });

      expect(
        found,
        unorderedEquals([
          'warning: flags.looked: is set but never checked',
          'warning: nodes.door.choices[1].if: flag "angry" is checked but never set',
        ]),
      );
    });
  });

  test('each draft page is a warning', () {
    expect(
      warnings((j) {
        j['schema'] = 6;
        node(j, 'foot')
          ..['draft'] = true
          ..remove('choices');
      }),
      contains('warning: nodes.foot: draft page, not written yet'),
    );
  });

  group('compareTranslations', () {
    Story story(void Function(Map<String, Object?>) mutate) {
      final json = validJson();
      mutate(json);
      return Story.fromJson(json);
    }

    List<String> diff(void Function(Map<String, Object?>) mutate) => [
      for (final i in compareTranslations(
        story((_) {}),
        story((j) {
          j['lang'] = 'pt';
          mutate(j);
        }),
      ))
        i.toString(),
    ];

    test('chapters and the chapter of each page must match', () {
      Map<String, Object?> withChapters(Map<String, Object?> j) => j
        ..['schema'] = 6
        ..['chapters'] = {
          'one': {'title': 'One'},
          'two': {'title': 'Two'},
        };
      final en = withChapters(validJson());
      node(en, 'door')['chapter'] = 'one';
      final pt = withChapters(validJson())
        ..['lang'] = 'pt'
        ..['chapters'] = {
          'one': {'title': 'Um'},
          'three': {'title': 'Três'},
        };
      node(pt, 'door')['chapter'] = 'three';
      node(pt, 'cellar')
        ..['title'] = 'Porão'
        ..['note'] = 'Notes may differ.';

      expect(
        [
          for (final i in compareTranslations(
            Story.fromJson(en),
            Story.fromJson(pt),
          ))
            i.toString(),
        ],
        unorderedEquals([
          'warning: chapters.two: chapter "two" exists in en but not in pt',
          'warning: chapters.three: chapter "three" exists in pt but not in en',
          'warning: nodes.door: is in chapter one in en but three in pt',
        ]),
      );
    });

    test('identical structure has no differences', () {
      expect(diff((_) {}), isEmpty);
    });

    test('reports node, item and choice differences', () {
      expect(
        diff((j) {
          (j['nodes']! as Map<String, Object?>).remove('foot');
          choice(j, 'door', 1)['to'] = 'treasure';
          (choice(j, 'door', 1)).remove('check');
          (j['items']! as Map<String, Object?>)['extra'] = {'name': 'x'};
          (node(j, 'door')['choices']! as List<Object?>).removeLast();
        }),
        unorderedEquals([
          'warning: nodes.foot: node "foot" exists in en but not in pt',
          'warning: items.extra: item "extra" exists in pt but not in en',
          'warning: nodes.door: has 2 choices in en but 1 in pt',
        ]),
      );
    });

    test('reports a different number of text parts', () {
      expect(
        diff((j) {
          j['schema'] = 4;
          node(j, 'cellar')['text'] = ['One.', 'Two.'];
        }),
        ['warning: nodes.cellar: has 1 text parts in en but 2 in pt'],
      );
    });

    test('reports stat and flag differences', () {
      expect(
        diff((j) {
          j['rules'] = {
            'preset': 'fighting-fantasy',
            'stats': {
              'gold': {'roll': '0'},
            },
          };
          node(j, 'shelves')['effects'] = [
            {'give': 'rusty-key'},
            {'set': 'looked'},
          ];
        }),
        unorderedEquals([
          'warning: rules.stats.gold: stat "gold" exists in pt but not in en',
          'warning: flags.looked: flag "looked" exists in pt but not in en',
        ]),
      );
    });
  });
}
