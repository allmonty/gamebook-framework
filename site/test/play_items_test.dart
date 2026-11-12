import 'dart:math';

import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/play/views.dart';
import 'package:test/test.dart';

import 'support/stories.dart';

PlaySession _start(String conformanceCase) =>
    PlaySession.start(conformanceStory(conformanceCase), random: Random(1));

void main() {
  test('a usable item is listed as usable and using it spends it', () {
    final session = _start('use-item');
    final potion = session.view.pack.items.single;
    expect(potion.name, 'Potion');
    expect(potion.usable, isTrue);
    session.useItem('potion');
    expect(session.view.pack.items, isEmpty);
  });

  test('using one of several logs the count going down', () {
    final session = _start('stack-use-spends-one')..useItem('meal');
    final line = session.view.log.singleWhere((l) => l.key == 'count');
    expect(line.args, {'item': 'Meal', 'from': 2, 'to': 1});
  });

  test('the pack shows how many of a countable item it holds', () {
    final session = _start('stack-use-spends-one');
    expect(session.view.pack.items.single.count, 2);
  });

  test('an offer of a countable item is for the whole count', () {
    final session = _start('stack-offer-whole-count');
    expect(session.view.offer!.item.count, 7);
  });

  test('a choice that needs several of an item says how many', () {
    final session = _start('stack-has-count');
    final need = session.view.choices.first.needs.single;
    expect(
      (need.kind, need.name, need.target),
      (RequirementKind.item, 'Meal', 2),
    );
  });

  test('gaining several at once is one line with the count', () {
    final session = _start('stack-partly-refused');
    expect([
      for (final l in session.view.log) (l.key, l.args['count']),
    ], containsAll([('gainedMany', 5), ('refusedMany', 2)]));
  });

  test('the provisions example eats its meals down to none', () {
    for (final lang in ['en', 'pt']) {
      final session = PlaySession.start(
        storyFile('examples/03-items/provisions.$lang.json'),
        random: Random(1),
      );
      for (final left in [4, 3, 2, 1]) {
        session.useItem('meal');
        expect(session.view.pack.items.single.count, left, reason: lang);
      }
      expect(session.view.choices, hasLength(1));
      session
        ..choose(0)
        ..useItem('meal');
      expect(session.view.pack.items, isEmpty, reason: lang);
      // Two meals for the ferry: now locked.
      expect(session.view.choices.first.locked, isTrue, reason: lang);
    }
  });

  test('an offer hides the choices until it is settled', () {
    final session = _start('offer-swap');
    final offer = session.view.offer!;
    expect(offer.item.name, 'Rope');
    expect(offer.needsSwap, isFalse);
    expect(session.view.choices, isEmpty);
    session.takeOffer();
    expect(session.view.offer, isNull);
    expect(session.view.pack.items.map((i) => i.name), ['Rope']);
    expect(session.view.choices, isNotEmpty);
  });

  test('a full pack offers a swap with the carried items', () {
    final session = _start('offer-swap')
      ..takeOffer()
      ..choose(0);
    final offer = session.view.offer!;
    expect(offer.item.name, 'Lamp');
    expect(offer.swapFrom.map((i) => i.id), ['rope']);
    expect(session.view.pack.full, isTrue);
    session.takeOffer(replacing: 'rope');
    expect(session.view.pack.items.map((i) => i.id), ['lamp']);
  });

  test('leaving an offer moves on to the next one', () {
    final session = _start('offer-leave');
    expect(session.view.offer!.more, 1);
    session.leaveOffer();
    expect(session.view.offer!.item.name, 'Lamp');
    expect(session.view.pack.items, isEmpty);
  });

  test('pack shows slots, bonuses and container room', () {
    final session = PlaySession.start(
      storyOf(
        {
          'a': {
            'text': 'Gear.',
            'effects': [
              {'give': 'sword'},
              {'give': 'bag'},
            ],
            'choices': [
              {'text': 'On', 'to': 'a'},
            ],
          },
        },
        extra: {
          'rules': {
            'preset': 'fighting-fantasy',
            'inventory': {'capacity': 1},
          },
          'items': {
            'sword': {
              'name': 'Sword',
              'bonus': {'skill': 1},
            },
            'bag': {'name': 'Bag', 'capacity': 2},
          },
        },
      ),
      random: Random(1),
    );
    final pack = session.view.pack;
    expect(pack.used, 1);
    expect(pack.capacity, 3);
    final [sword, bag] = pack.items;
    expect(sword.bonus, [('Skill', 1)]);
    expect(bag.room, 2);
    expect(session.view.stats.first.bonus, 1);
  });
}
