import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// A pack with Meals (5 to a slot), Arrows (1 to a slot), a Sword, a Bag
/// (one more slot) and a Ring with a bonus. Page `a` applies [start]; its
/// first choice applies [then] and comes back.
Story pack({
  int? capacity,
  String pickup = 'auto',
  List<Map<String, Object?>> start = const [],
  List<Map<String, Object?>> then = const [],
  Map<String, Object?>? needs,
}) => Story.fromJson({
  'schema': 8,
  'id': 'pack',
  'lang': 'en',
  'title': 'Pack',
  'rules': {
    'preset': 'fighting-fantasy',
    'inventory': {'capacity': ?capacity, 'pickup': pickup},
  },
  'items': {
    'meal': {
      'name': 'Meal',
      'stack': 5,
      'use': {
        'effects': [
          {'stat': 'stamina', 'add': 4},
        ],
        'when': ['story'],
      },
    },
    'arrow': {'name': 'Arrow', 'stack': 1},
    'herb': {'name': 'Herb', 'stack': 3, 'max': 4},
    'sword': {'name': 'Sword'},
    'bag': {'name': 'Bag', 'capacity': 1},
    'ring': {
      'name': 'Ring',
      'stack': 3,
      'bonus': {'luck': 1},
    },
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'Herbs: {herb.count}.',
      // The choices come back here; the start applies only the first time.
      'once': true,
      'effects': start,
      'choices': [
        {'text': 'Then', 'to': 'a', 'effects': then},
        {'text': 'Needs', 'to': 'a', 'if': ?needs},
      ],
    },
  },
});

(GameEngine, List<GameEvent>) begin(Story story, {List<Effect>? picks}) =>
    GameEngine.newGame(
      story: story,
      rules: Rules.resolve(story.rules),
      random: ScriptedRandom(const []),
      stats: const {
        'skill': StatValue(9, 12),
        'stamina': StatValue(6, 24),
        'luck': StatValue(8, 12),
      },
      creationEffects: picks ?? const [],
    );

Map<String, Object?> give(String item, [int? count]) => {
  'give': item,
  'count': ?count,
};

void main() {
  group('pack room', () {
    test('a stack of 5 fills one slot with 5, a second with the 6th', () {
      final (engine, _) = begin(
        pack(start: [give('meal', 5)], then: [give('meal')]),
      );
      expect((engine.state.count('meal'), engine.slotsUsed), (5, 1));

      engine.choose(0);

      expect((engine.state.count('meal'), engine.slotsUsed), (6, 2));
    });

    test('a stack of 1 fills a slot with each', () {
      final (engine, _) = begin(pack(start: [give('arrow', 3)]));
      expect((engine.state.count('arrow'), engine.slotsUsed), (3, 3));
    });

    test('without a capacity the count has no limit', () {
      final (engine, _) = begin(pack(start: [give('meal', 400)]));
      expect(engine.state.count('meal'), 400);
    });
  });

  group('give, take and has', () {
    test('a give of a unique item still changes nothing when held', () {
      final (engine, _) = begin(pack(start: [give('sword'), give('sword')]));
      expect(engine.state.count('sword'), 1);
    });

    test('a take stops at 0, and the item leaves the pack', () {
      final (engine, _) = begin(
        pack(
          start: [
            give('meal', 5),
            {'take': 'meal', 'count': 2},
          ],
          then: [
            {'take': 'meal', 'count': 9},
          ],
        ),
      );
      expect(engine.state.count('meal'), 3);

      engine.choose(0);

      expect(engine.state.count('meal'), 0);
      expect(engine.state.inventory, isNot(contains('meal')));
      expect(engine.state.counts, isEmpty);
    });

    test('has with a count needs at least that many', () {
      final needs = {'has': 'meal', 'count': 2};
      final (one, _) = begin(pack(start: [give('meal')], needs: needs));
      final (two, _) = begin(pack(start: [give('meal', 2)], needs: needs));

      expect(one.choices.last.locked, isTrue);
      expect(two.choices.last.locked, isFalse);
    });

    test('takeAll takes every one', () {
      final (engine, _) = begin(
        pack(
          start: [give('meal', 7)],
          then: [
            {'takeAll': true},
          ],
        ),
      );
      engine.choose(0);
      expect(engine.state.inventory, isEmpty);
      expect(engine.state.counts, isEmpty);
    });
  });

  group('using', () {
    test('spends one at a time; the last one leaves the pack', () {
      final (engine, _) = begin(pack(start: [give('meal', 2)]));

      final events = engine.useItem('meal');

      expect(engine.state.count('meal'), 1);
      expect(engine.state.stat('stamina'), 10);
      expect(
        events.whereType<ItemCountChanged>().single,
        isA<ItemCountChanged>()
            .having((e) => e.from, 'from', 2)
            .having((e) => e.to, 'to', 1),
      );

      engine.useItem('meal');

      expect(engine.state.inventory, isNot(contains('meal')));
      expect(engine.canUse('meal'), isFalse);
    });

    test('a bonus counts once, however many are held', () {
      final (engine, _) = begin(pack(start: [give('ring', 3)]));
      expect(engine.state.stat('luck'), 9);
    });
  });

  group('pickup "auto"', () {
    test('adds what fits and refuses the rest, saying how many', () {
      final (engine, events) = begin(
        pack(capacity: 1, start: [give('meal', 7)]),
      );

      expect(engine.state.count('meal'), 5);
      final refused = events.whereType<ItemRefused>().single;
      expect((refused.item, refused.count), ('meal', 2));
      expect(events.whereType<ItemGained>().single.count, 5);
    });

    test('fills the part-filled slot first', () {
      final (engine, _) = begin(
        pack(capacity: 1, start: [give('meal', 3), give('meal', 4)]),
      );
      expect(engine.state.count('meal'), 5);
    });
  });

  group('pickup "choose"', () {
    test('what fits in the part-filled slot is added without an offer', () {
      final (engine, _) = begin(
        pack(capacity: 1, pickup: 'choose', start: [give('meal', 3)]),
      );
      // The first give needed a new slot, so it was offered.
      expect((engine.offer, engine.offerCount), ('meal', 3));
      engine.resolveOffer(take: true);
      expect(engine.state.count('meal'), 3);
    });

    test('a give that fits the part-filled slot is added directly', () {
      final story = pack(
        capacity: 1,
        pickup: 'choose',
        start: [give('meal', 3)],
        then: [give('meal', 2)],
      );
      final (engine, _) = begin(story);
      engine.resolveOffer(take: true);

      engine.choose(0);

      expect(engine.offer, isNull);
      expect(engine.state.count('meal'), 5);
    });

    test('a give that needs a new slot is one offer for the whole count, '
        'and a further give adds to it', () {
      final (engine, _) = begin(
        pack(
          capacity: 2,
          pickup: 'choose',
          start: [give('meal', 3), give('meal', 4)],
        ),
      );
      expect(
        (engine.offer, engine.offerCount, engine.moreOffers),
        ('meal', 7, 0),
      );

      engine.resolveOffer(take: true);

      expect(engine.state.count('meal'), 7);
    });

    test('taking it adds what fits and leaves the rest', () {
      final (engine, _) = begin(
        pack(
          capacity: 1,
          pickup: 'choose',
          start: [give('sword'), give('meal', 7)],
        ),
      );
      engine.resolveOffer(take: true); // the sword
      expect(engine.canHold('meal'), isFalse);

      final events = engine.resolveOffer(take: true, replacing: 'sword');

      expect(engine.state.inventory, ['meal']);
      expect(engine.state.count('meal'), 5);
      expect(events.whereType<ItemRefused>().single.count, 2);
    });
  });

  test('losing room loses only the units that no longer fit', () {
    final (engine, events) = begin(
      pack(
        capacity: 1,
        start: [give('bag'), give('meal', 8)],
        then: [
          {'take': 'bag'},
        ],
      ),
    );
    expect(engine.state.count('meal'), 8);

    final lost = engine.choose(0);

    expect(engine.state.count('meal'), 5);
    final overflow = lost.whereType<ItemOverflow>().single;
    expect((overflow.item, overflow.count), ('meal', 3));
    expect(lost.whereType<ItemCountChanged>(), isEmpty);
  });

  group('a cap (max)', () {
    test('a give stops at the cap, and the rest is refused', () {
      final (engine, events) = begin(pack(start: [give('herb', 6)]));
      expect(engine.state.count('herb'), 4);
      expect(events.whereType<ItemRefused>().single.count, 2);
    });

    test('an offer is taken up to the cap, with no swap asked', () {
      final (engine, _) = begin(
        pack(pickup: 'choose', start: [give('herb', 6)]),
      );
      expect(engine.offerNeedsRoom, isFalse);

      final events = engine.resolveOffer(take: true);

      expect(engine.state.count('herb'), 4);
      expect(events.whereType<ItemRefused>().single.count, 2);
    });

    test('at the cap a give is refused at once, not offered', () {
      final (engine, _) = begin(
        pack(pickup: 'choose', start: [give('herb', 4)], then: [give('herb')]),
      );
      engine.resolveOffer(take: true);
      expect(engine.state.count('herb'), 4);

      final events = engine.choose(0);

      expect(engine.offer, isNull);
      expect(events.whereType<ItemRefused>().single.item, 'herb');
    });

    test('a creation pick stops at the cap too', () {
      final (engine, _) = begin(pack(), picks: const [GiveItem('herb', 9)]);
      expect(engine.state.count('herb'), 4);
    });
  });

  test('{item.count} in text shows how many are held', () {
    final (engine, _) = begin(pack(start: [give('herb', 2)]));
    expect(engine.paragraphs.single, 'Herbs: 2.');
  });

  test('a creation pick gives its count directly', () {
    final (engine, _) = begin(
      pack(capacity: 1, pickup: 'choose'),
      picks: const [GiveItem('meal', 4)],
    );
    expect(engine.state.count('meal'), 4);
    expect(engine.offer, isNull);
  });

  group('saves', () {
    test('keep the counts held and offered', () {
      final (engine, _) = begin(
        pack(capacity: 2, pickup: 'choose', start: [give('arrow', 3)]),
      );
      final saved = GameState.fromJson(engine.state.toJson());
      expect(saved.offered('arrow'), 3);
      expect(saved.offerCounts, {'arrow': 3});
    });

    test('a save from before counted items holds one of each', () {
      final json = const GameState(node: 'a', inventory: {'meal'}).toJson()
        ..remove('counts')
        ..remove('offerCounts');
      expect(GameState.fromJson(json).count('meal'), 1);
    });
  });
}
