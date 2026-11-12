import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/json_reader.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

Rules resolve(Map<String, Object?> json) =>
    Rules.resolve(RulesSpec.fromJson(JsonObject(json, 'rules')));

String failure(Map<String, Object?> json) {
  try {
    resolve(json);
  } on StoryFormatException catch (e) {
    return e.toString();
  }
  fail('expected a StoryFormatException');
}

/// Everything a resolved [Rules] holds, as plain values, so two can be
/// compared.
Map<String, Object?> describe(Rules r) => {
  'stats': [
    for (final s in r.stats)
      [s.id, s.label, '${s.roll}', s.max, s.limit, s.min, s.hidden],
  ],
  'health': r.health,
  'rerolls': r.rerolls,
  'undo': r.undo,
  'combat': switch (r.combat) {
    null => null,
    final c => [
      c.mode,
      '${c.attackRoll}',
      c.attackStat,
      '${c.damage}',
      c.defenseStat,
      c.defenseBase,
      c.luck == null,
      c.table.length,
      '${c.tableRoll}',
    ],
  },
};

void main() {
  group('the preset files in spec/presets are the presets', () {
    for (final name in ['fighting-fantasy', 'd20-lite']) {
      test(name, () {
        final file = jsonDecode(
          File('../../spec/presets/$name.json').readAsStringSync(),
        );
        expect(
          describe(
            Rules.resolve(RulesSpec.fromJson(JsonObject(file, 'rules'))),
          ),
          describe(Rules.resolve(RulesSpec(preset: name))),
        );
      });
    }
  });

  group('presets', () {
    test('fighting-fantasy', () {
      final rules = resolve({'preset': 'fighting-fantasy'});

      expect(rules.stats.map((s) => s.id), ['skill', 'stamina', 'luck']);
      expect(rules.stats.map((s) => s.roll.toString()), [
        '1d6+6',
        '2d6+12',
        '1d6+6',
      ]);
      expect(rules.stats.every((s) => s.max), isTrue);
      expect(rules.health, 'stamina');
      expect(rules.rerolls, 2);
      final combat = rules.combat!;
      expect(combat.mode, CombatMode.opposed);
      expect(combat.attackRoll.toString(), '2d6');
      expect(combat.attackStat, 'skill');
      expect(combat.damage.toString(), '2');
      expect(combat.defenseStat, isNull);
    });

    test('d20-lite', () {
      final rules = resolve({'preset': 'd20-lite'});

      expect(rules.stats.map((s) => s.id), ['might', 'agility', 'wits', 'hp']);
      expect(rules.stats.map((s) => s.max), [false, false, false, true]);
      expect(rules.health, 'hp');
      final combat = rules.combat!;
      expect(combat.mode, CombatMode.vsDefense);
      expect(combat.defenseStat, 'agility');
      expect(combat.defenseBase, 10);
      expect(combat.damage.toString(), '1d6');
    });

    test('every preset name resolves', () {
      for (final name in presetNames) {
        expect(() => resolve({'preset': name}), returnsNormally, reason: name);
      }
    });
  });

  group('overrides', () {
    test('win over the preset field by field', () {
      final rules = resolve({
        'preset': 'fighting-fantasy',
        'rerolls': 0,
        'stats': {
          'skill': {'label': 'Habilidade'},
          'gold': {'label': 'Ouro', 'roll': '0'},
        },
        'combat': {'damage': '3'},
      });

      expect(rules.rerolls, 0);
      expect(rules.stats.first.label, 'Habilidade');
      expect(rules.stats.first.roll.toString(), '1d6+6');
      expect(rules.stats.last.id, 'gold');
      expect(rules.stats.last.max, isFalse);
      expect(rules.combat!.damage.toString(), '3');
      expect(rules.combat!.attackStat, 'skill');
    });

    test('a story can define its rules without any preset', () {
      final rules = resolve({
        'health': 'hp',
        'stats': {
          'hp': {'roll': '10', 'max': true},
        },
      });

      expect(rules.stats.single.label, 'hp');
      expect(rules.rerolls, 0);
      expect(rules.combat, isNull);
    });
  });

  group('errors', () {
    test('unknown preset', () {
      expect(
        failure({'preset': 'nope'}),
        'rules.preset: unknown preset "nope"',
      );
    });

    test('no stats', () {
      expect(failure({'health': 'hp'}), 'rules.stats: missing');
    });

    test('no health', () {
      expect(
        failure({
          'stats': {
            'hp': {'roll': '1'},
          },
        }),
        'rules.health: missing',
      );
    });

    test('health is not a stat', () {
      expect(
        failure({'preset': 'fighting-fantasy', 'health': 'hp'}),
        'rules.health: unknown stat "hp"',
      );
    });

    test('stat without roll', () {
      expect(
        failure({
          'health': 'hp',
          'stats': {
            'hp': {'label': 'x'},
          },
        }),
        'rules.stats.hp.roll: missing',
      );
    });

    test('bad dice name the path', () {
      expect(
        failure({
          'preset': 'fighting-fantasy',
          'stats': {
            'skill': {'roll': '1d0'},
          },
        }),
        startsWith('rules.stats.skill.roll: invalid dice notation'),
      );
      expect(
        failure({
          'preset': 'fighting-fantasy',
          'combat': {'damage': 'lots'},
        }),
        startsWith('rules.combat.damage: invalid dice notation'),
      );
    });

    test('negative rerolls', () {
      expect(
        failure({'preset': 'fighting-fantasy', 'rerolls': -1}),
        'rules.rerolls: must not be negative',
      );
    });

    test('combat mode', () {
      expect(
        failure({
          'preset': 'fighting-fantasy',
          'combat': {'mode': 'telepathy'},
        }),
        'rules.combat.mode: expected "opposed", "vs-defense" or "table", '
        'got "telepathy"',
      );
      expect(
        failure({
          'health': 'hp',
          'stats': {
            'hp': {'roll': '5'},
          },
          'combat': {'damage': '1'},
        }),
        'rules.combat.mode: missing',
      );
    });

    test('combat stats must exist', () {
      expect(
        failure({
          'preset': 'fighting-fantasy',
          'combat': {'attackStat': 'might'},
        }),
        'rules.combat.attackStat: unknown stat "might"',
      );
    });

    test('vs-defense needs its extra fields', () {
      final base = {
        'health': 'hp',
        'stats': {
          'hp': {'roll': '5'},
        },
      };
      expect(
        failure({
          ...base,
          'combat': {
            'mode': 'vs-defense',
            'attackRoll': '1d20',
            'attackStat': 'hp',
            'damage': '1',
            'defenseStat': 'hp',
          },
        }),
        'rules.combat.defenseBase: missing',
      );
    });
  });

  group('stat limits', () {
    test('a limit is a fixed ceiling and the start can be far below it', () {
      final rules = resolve({
        'health': 'hp',
        'stats': {
          'hp': {'roll': '10', 'max': true},
          'gold': {'roll': '0', 'limit': 50},
        },
      });

      final stats = rules.rollStats(Random(1));

      expect(rules.stats.last.limit, 50);
      expect(stats['gold']!.value, 0);
      expect(stats['gold']!.max, 50);
      expect(stats['hp']!.max, 10);
    });

    test('a roll above the limit is cut to it', () {
      final rules = resolve({
        'health': 'hp',
        'stats': {
          'hp': {'roll': '10'},
          'luck': {'roll': '3d6+10', 'limit': 12},
        },
      });

      for (var seed = 0; seed < 50; seed++) {
        expect(
          rules.rollStats(Random(seed))['luck']!.value,
          lessThanOrEqualTo(12),
        );
      }
    });

    test('a story limit replaces the max of a preset stat', () {
      final rules = resolve({
        'preset': 'fighting-fantasy',
        'stats': {
          'luck': {'limit': 9},
        },
      });

      final luck = rules.stats.firstWhere((s) => s.id == 'luck');
      expect(luck.limit, 9);
      expect(luck.max, isFalse);
      expect(rules.rollStats(Random(3))['luck']!.max, 9);
    });

    test('a limit cannot be combined with max: true', () {
      expect(
        failure({
          'health': 'hp',
          'stats': {
            'hp': {'roll': '5', 'max': true, 'limit': 8},
          },
        }),
        'rules.stats.hp.limit: cannot be combined with "max": true',
      );
    });

    test('a limit must be at least 1', () {
      String error() {
        try {
          RulesSpec.fromJson(
            JsonObject({
              'stats': {
                'g': {'roll': '1', 'limit': 0},
              },
            }, 'rules'),
          );
        } on StoryFormatException catch (e) {
          return e.toString();
        }
        fail('expected a StoryFormatException');
      }

      expect(error(), 'rules.stats.g.limit: must be at least 1');
    });
  });

  group('inventory rules', () {
    test('default to an unlimited pack that picks things up at once', () {
      final inventory = resolve({'preset': 'fighting-fantasy'}).inventory;

      expect(inventory.capacity, isNull);
      expect(inventory.pickup, PickupMode.auto);
    });

    test('come from the story', () {
      final inventory = resolve({
        'preset': 'fighting-fantasy',
        'inventory': {'capacity': 4, 'pickup': 'choose'},
      }).inventory;

      expect(inventory.capacity, 4);
      expect(inventory.pickup, PickupMode.choose);
    });

    test('a capacity alone still picks things up at once', () {
      final inventory = resolve({
        'preset': 'fighting-fantasy',
        'inventory': {'capacity': 2},
      }).inventory;

      expect(inventory.pickup, PickupMode.auto);
    });
  });

  group('rollStats', () {
    test('stays within the dice bounds and sets max from the roll', () {
      final rules = resolve({'preset': 'fighting-fantasy'});
      final random = Random(5);
      for (var i = 0; i < 500; i++) {
        final stats = rules.rollStats(random);
        expect(stats['skill']!.value, inInclusiveRange(7, 12));
        expect(stats['stamina']!.value, inInclusiveRange(14, 24));
        expect(stats['luck']!.value, inInclusiveRange(7, 12));
        for (final stat in stats.values) {
          expect(stat.max, stat.value);
        }
      }
    });

    test('only stats with max get a ceiling', () {
      final stats = resolve({'preset': 'd20-lite'}).rollStats(Random(1));
      expect(stats['might']!.max, isNull);
      expect(stats['hp']!.max, stats['hp']!.value);
    });

    test('is deterministic for a seed', () {
      final rules = resolve({'preset': 'fighting-fantasy'});
      expect(
        rules.rollStats(Random(9)).map((k, v) => MapEntry(k, v.value)),
        rules.rollStats(Random(9)).map((k, v) => MapEntry(k, v.value)),
      );
    });
  });
}
