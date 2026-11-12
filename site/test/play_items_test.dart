import 'dart:math';

import 'package:gamebook_site/src/play/play_session.dart';
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
