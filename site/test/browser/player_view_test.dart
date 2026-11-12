@TestOn('browser')
library;

import 'dart:math';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/ui/dom.dart';
import 'package:gamebook_site/src/ui/player_view.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

final _story = Story.fromJson({
  'schema': 1,
  'id': 't',
  'lang': 'en',
  'title': 'Smoke',
  'rules': {'preset': 'fighting-fantasy'},
  'items': {
    'key': {'name': 'Key'},
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'First page.',
      'choices': [
        {'text': 'Onward', 'to': 'b'},
        {
          'text': 'Unlock',
          'to': 'b',
          'if': {'has': 'key'},
        },
      ],
    },
    'b': {'text': 'Second page.', 'ending': 'victory'},
  },
});

void main() {
  test('renders a page, takes a choice and reaches the ending', () {
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      PlaySession.start(_story, random: Random(1)),
      const Messages({'player.needs': 'Needs: {list}'}),
    );
    expect(host.querySelector('.gb-page p')!.textContent, 'First page.');
    final locked = host.querySelector('.gb-choice.locked')!;
    expect(locked.textContent, contains('Needs: Key'));

    (host.querySelector('.gb-choice:not(.locked)')! as HTMLElement).click();

    expect(host.querySelector('.gb-page p')!.textContent, 'Second page.');
    expect(host.querySelector('.gb-ending.victory'), isNotNull);
    expect(host.querySelectorAll('.gb-choice').length, 0);
    host.remove();
  });

  test('the page image carries its description as alt text', () {
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      PlaySession.start(
        Story.fromJson({
          'schema': 8,
          'id': 't',
          'lang': 'en',
          'title': 'Pictures',
          'rules': {'preset': 'fighting-fantasy'},
          'start': 'a',
          'nodes': {
            'a': {
              'text': 'A.',
              'image': 'images/gate.webp',
              'imageAlt': 'An iron gate in the fog.',
              'ending': 'victory',
            },
          },
        }),
        random: Random(1),
      ),
      const Messages({}),
    );
    expect(
      host.querySelector('.gb-page img')!.getAttribute('alt'),
      'An iron gate in the fog.',
    );
    host.remove();
  });
}
