@TestOn('browser')
library;

import 'dart:math';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/play/views.dart';
import 'package:gamebook_site/src/ui/dom.dart';
import 'package:gamebook_site/src/ui/pack_panel.dart';
import 'package:gamebook_site/src/ui/player_view.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

final _story = Story.fromJson({
  'schema': 3,
  'id': 't',
  'lang': 'en',
  'title': 'Pack',
  'rules': {
    'preset': 'fighting-fantasy',
    'inventory': {'capacity': 1, 'pickup': 'choose'},
  },
  'items': {
    'potion': {
      'name': 'Potion',
      'use': {
        'effects': [
          {'stat': 'stamina', 'add': 1},
        ],
        'when': ['story'],
      },
    },
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'A potion.',
      'effects': [
        {'give': 'potion'},
      ],
      'choices': [
        {'text': 'On', 'to': 'a'},
      ],
    },
  },
});

void main() {
  test('take an offered item, then use it from the pack', () {
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      PlaySession.start(_story, random: Random(1)),
      const Messages({'player.take': 'Take it', 'player.use': 'Use'}),
    );
    expect(host.querySelectorAll('.gb-choice').length, 0);
    _button(host, '.gb-offer button', 'Take it').click();

    expect(host.querySelector('.gb-offer'), isNull);
    expect(host.querySelectorAll('.gb-choice').length, 1);
    _button(host, '.gb-pack button', 'Use').click();
    expect(host.querySelector('.gb-pack li'), isNull);
    host.remove();
  });

  test('a countable item shows how many', () {
    final panel = PackPanel(
      const PackView(
        items: [PackItem(id: 'meal', name: 'Meal', count: 3)],
        used: 1,
      ),
      const Messages({'player.items': '{count} × {item}'}),
      onUse: (_) {},
    );
    expect(panel.element.querySelector('strong')!.textContent, '3 × Meal');
  });
}

HTMLElement _button(HTMLElement host, String selector, String text) {
  final all = host.querySelectorAll(selector);
  for (var i = 0; i < all.length; i++) {
    final b = all.item(i)! as HTMLElement;
    if (b.textContent == text) return b;
  }
  throw StateError('no "$text" button in $selector');
}
