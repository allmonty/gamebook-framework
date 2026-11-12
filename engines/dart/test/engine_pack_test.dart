import 'dart:convert';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// camp (gives a rope, a lamp and bread) with ways to a shed (a bag), a tower
/// (a sword and a map), a thief (takes the bag), a river (offers a map, then
/// takes everything)
/// and a den (a fight that also gives a sword). The bag adds 2 slots.
Story story(Map<String, Object?>? inventory) => Story.fromJson({
  'schema': 1,
  'id': 'pack',
  'lang': 'en',
  'title': 'Pack',
  'rules': {'preset': 'fighting-fantasy', 'inventory': ?inventory},
  'start': 'camp',
  'items': {
    'rope': {'name': 'Rope'},
    'lamp': {'name': 'Lamp'},
    'bread': {
      'name': 'Bread',
      'use': {
        'effects': [
          {'stat': 'stamina', 'add': 1},
        ],
        'when': ['story'],
      },
    },
    'sword': {'name': 'Sword'},
    'map': {'name': 'Map'},
    'bag': {'name': 'Bag', 'capacity': 2},
  },
  'nodes': {
    'camp': {
      'text': 'Camp',
      'once': true,
      'effects': [
        {'give': 'rope'},
        {'give': 'lamp'},
        {'give': 'bread'},
      ],
      'choices': [
        {'text': 'Shed', 'to': 'shed'},
        {'text': 'Tower', 'to': 'tower'},
        {'text': 'Thief', 'to': 'thief'},
        {'text': 'River', 'to': 'river'},
        {'text': 'Den', 'to': 'den'},
        {'text': 'Camp again', 'to': 'camp'},
      ],
    },
    'shed': {
      'text': 'Shed',
      'effects': [
        {'give': 'bag'},
      ],
      'choices': [
        {'text': 'Back', 'to': 'camp'},
      ],
    },
    'tower': {
      'text': 'Tower',
      'effects': [
        {'give': 'sword'},
        {'give': 'map'},
      ],
      'choices': [
        {'text': 'Back', 'to': 'camp'},
      ],
    },
    'thief': {
      'text': 'Thief',
      'effects': [
        {'take': 'bag'},
      ],
      'choices': [
        {'text': 'Back', 'to': 'camp'},
      ],
    },
    'river': {
      'text': 'River',
      'effects': [
        {'give': 'map'},
        {'takeAll': true},
      ],
      'choices': [
        {'text': 'Back', 'to': 'camp'},
      ],
    },
    'den': {
      'text': 'Den',
      'effects': [
        {'give': 'sword'},
      ],
      'combat': {
        'enemies': [
          {'name': 'Rat', 'attack': 5, 'health': 2},
        ],
        'win': 'won',
      },
    },
    'won': {'text': 'Won', 'ending': 'victory'},
  },
});

const stats = {
  'skill': StatValue(9, 12),
  'stamina': StatValue(12, 24),
  'luck': StatValue(8, 12),
};

GameEngine start(
  Map<String, Object?>? inventory, {
  List<int> dice = const [],
  List<GameEvent>? events,
}) {
  final s = story(inventory);
  final (engine, first) = GameEngine.newGame(
    story: s,
    rules: Rules.resolve(s.rules),
    random: ScriptedRandom(dice),
    stats: stats,
  );
  events?.addAll(first);
  return engine;
}

/// Walks to [node] from the camp, using the choice with that text.
void go(GameEngine e, String text) =>
    e.choose(e.choices.firstWhere((c) => c.choice.text == text).index);

void main() {
  group('no inventory rules: today\'s behavior', () {
    test('every give just adds the item, without limit', () {
      final e = start(null);

      expect(e.state.inventory.toList(), ['rope', 'lamp', 'bread']);
      expect(e.capacity, isNull);
      expect(e.offer, isNull);
      expect(e.canHold('sword'), isTrue);
      go(e, 'Tower');
      expect(e.state.inventory, containsAll(['sword', 'map']));
      expect(e.state.offers, isEmpty);
    });
  });

  group('capacity with pickup auto', () {
    test('items that do not fit are refused, and the player is told', () {
      final events = <GameEvent>[];
      final e = start({'capacity': 2}, events: events);

      expect(e.state.inventory.toList(), ['rope', 'lamp']);
      expect(events.whereType<ItemRefused>().single.item, 'bread');
      expect(e.offer, isNull);
      expect(e.slotsUsed, 2);
      expect(e.canHold('map'), isFalse);
    });

    test('a container always fits and adds room', () {
      final e = start({'capacity': 2});

      go(e, 'Shed');

      expect(e.state.inventory, contains('bag'));
      expect(e.capacity, 4);
      expect(e.slotsUsed, 2, reason: 'the bag uses no slot');
      go(e, 'Back');
      go(e, 'Tower');
      expect(e.state.inventory, containsAll(['sword', 'map']));
    });
  });

  group('pickup choose', () {
    final rules = {'capacity': 2, 'pickup': 'choose'};

    test('found items become offers, in order, and nothing is added yet', () {
      final e = start(rules);

      expect(e.state.inventory, isEmpty);
      expect(e.state.offers, ['rope', 'lamp', 'bread']);
      expect(e.offer, 'rope');
      expect(e.moreOffers, 2);
    });

    test('choices and fights wait until the offers are settled', () {
      final e = start(rules);

      expect(() => e.choose(0), throwsStateError);
      e.resolveOffer(take: false);
      e.resolveOffer(take: false);
      expect(() => e.choose(0), throwsStateError);
      e.resolveOffer(take: false);
      expect(() => go(e, 'Tower'), returnsNormally);
    });

    test('taking an offer with room adds it', () {
      final e = start(rules);

      final events = e.resolveOffer(take: true);

      expect(e.state.inventory, {'rope'});
      expect(e.offer, 'lamp');
      expect(events.whereType<ItemGained>().single.item, 'rope');
    });

    test('leaving an offer changes nothing but is reported', () {
      final e = start(rules);

      final events = e.resolveOffer(take: false);

      expect(e.state.inventory, isEmpty);
      expect(events.whereType<OfferDeclined>().single.item, 'rope');
      expect(e.offer, 'lamp');
    });

    test('with a full pack, taking needs an item to leave behind', () {
      final e = start(rules)
        ..resolveOffer(take: true)
        ..resolveOffer(take: true);
      expect(e.canHold('bread'), isFalse);

      expect(() => e.resolveOffer(take: true), throwsStateError);
      expect(
        () => e.resolveOffer(take: true, replacing: 'sword'),
        throwsStateError,
        reason: 'not carried',
      );
      final events = e.resolveOffer(take: true, replacing: 'rope');

      expect(e.state.inventory.toList(), ['lamp', 'bread']);
      expect(events.whereType<ItemGained>().single.item, 'bread');
      expect(events.whereType<ItemLost>().single.item, 'rope');
      expect(e.offer, isNull);
    });

    test('with a full pack the player may still just leave it', () {
      final e = start(rules)
        ..resolveOffer(take: true)
        ..resolveOffer(take: true);

      e.resolveOffer(take: false);

      expect(e.state.inventory, {'rope', 'lamp'});
    });

    test('a container needs no room, and cannot be swapped out', () {
      final e = start(rules)
        ..resolveOffer(take: true)
        ..resolveOffer(take: true)
        ..resolveOffer(take: false);
      go(e, 'Shed');

      expect(e.canHold('bag'), isTrue);
      e.resolveOffer(take: true);

      expect(e.state.inventory, containsAll(['rope', 'lamp', 'bag']));
      expect(e.capacity, 4);
      go(e, 'Back');
      go(e, 'Tower');
      e.resolveOffer(take: true);
      e.resolveOffer(take: true);
      expect(e.slotsUsed, 4);
      go(e, 'Back');
      go(e, 'Tower'); // nothing new: already carried
      expect(e.state.offers, isEmpty);
      expect(
        () => e.resolveOffer(take: true),
        throwsStateError,
        reason: 'no offer left',
      );
    });

    test('an item already carried is not offered again, a declined one is', () {
      final e = start({'pickup': 'choose'});
      for (var i = 0; i < 3; i++) {
        e.resolveOffer(take: false);
      }
      go(e, 'Tower');
      e.resolveOffer(take: true); // sword
      e.resolveOffer(take: false); // map
      go(e, 'Back');

      go(e, 'Tower');

      expect(e.state.offers, ['map']);
    });

    test('without a capacity the pack is unlimited but still asks', () {
      final e = start({'pickup': 'choose'});

      expect(e.capacity, isNull);
      expect(e.canHold('map'), isTrue);
      e.resolveOffer(take: true);
      expect(e.state.inventory, {'rope'});
    });

    test('using an item makes room while an offer waits', () {
      final e = start(rules)
        ..resolveOffer(take: false)
        ..resolveOffer(take: true)
        ..resolveOffer(take: true); // lamp and bread: full
      go(e, 'Tower');
      expect(e.offer, 'sword');
      expect(e.canHold('sword'), isFalse);

      e.useItem('bread');

      expect(e.canHold('sword'), isTrue);
      e.resolveOffer(take: true);
      expect(e.state.inventory, {'lamp', 'sword'});
    });

    test('a fight cannot start while an item is on offer', () {
      final e = start({'pickup': 'choose'});
      e.resolveOffer(take: false);
      e.resolveOffer(take: false);
      e.resolveOffer(take: false);
      go(e, 'Den');
      expect(e.offer, 'sword');

      expect(() => e.fight(), throwsStateError);
      expect(() => e.flee(), throwsStateError);
      e.resolveOffer(take: false);
      expect(e.combat, isNotNull);
    });

    test('offers do not outlive the game', () {
      final e = start({'pickup': 'choose'}, dice: [6, 6, 1, 1]);
      for (var i = 0; i < 3; i++) {
        e.resolveOffer(take: false);
      }
      go(e, 'Den');
      e.resolveOffer(take: true);

      e.fight();

      expect(e.ending, Ending.victory);
      expect(e.offer, isNull);
    });

    test('offers survive a save', () {
      final e = start(rules);
      final saved = jsonDecode(jsonEncode(e.state.toJson()));

      final s = story(rules);
      final restored = GameEngine(
        story: s,
        rules: Rules.resolve(s.rules),
        random: ScriptedRandom([]),
        state: GameState.fromJson(saved),
      );

      expect(restored.offer, 'rope');
      expect(restored.state.offers, ['rope', 'lamp', 'bread']);
    });
  });

  group('losing room and losing everything', () {
    test('taking the container drops the newest items that no longer fit', () {
      final e = start({'capacity': 2});
      go(e, 'Shed'); // capacity 4
      go(e, 'Back');
      go(e, 'Tower'); // sword, map: 4 items
      go(e, 'Back');
      expect(e.slotsUsed, 4);

      final events = go2(e, 'Thief');

      expect(e.state.inventory.toList(), ['rope', 'lamp']);
      expect(events.whereType<ItemOverflow>().map((o) => o.item), [
        'map',
        'sword',
      ]);
      expect(events.whereType<ItemLost>().map((l) => l.item), [
        'bag',
      ], reason: 'overflow already says why the others went');
      expect(e.capacity, 2);
    });

    test('nothing is lost when the items still fit', () {
      final e = start({'capacity': 2});
      go(e, 'Shed');
      go(e, 'Back');

      final events = go2(e, 'Thief');

      expect(events.whereType<ItemOverflow>(), isEmpty);
      expect(e.state.inventory.toList(), ['rope', 'lamp']);
    });

    test('takeAll empties the pack but not the offers', () {
      final e = start({'capacity': 2, 'pickup': 'choose'})
        ..resolveOffer(take: true)
        ..resolveOffer(take: true)
        ..resolveOffer(take: false);

      final swept = go2(e, 'River');

      expect(e.state.inventory, isEmpty);
      expect(e.state.offers, ['map'], reason: 'offered before it, still open');
      expect(
        swept.whereType<ItemLost>().map((l) => l.item),
        unorderedEquals(['rope', 'lamp']),
      );
    });
  });
}

/// Like [go] but returns the events.
List<GameEvent> go2(GameEngine e, String text) =>
    e.choose(e.choices.firstWhere((c) => c.choice.text == text).index);
