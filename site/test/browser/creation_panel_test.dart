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
  'schema': 5,
  'id': 't',
  'lang': 'en',
  'title': 'Hero',
  'rules': {
    'preset': 'fighting-fantasy',
    'creation': {
      'name': true,
      'picks': [
        {
          'id': 'kit',
          'title': 'Kit',
          'count': 1,
          'options': [
            {
              'id': 'rope',
              'label': 'Rope',
              'effects': [
                {'give': 'rope'},
              ],
            },
          ],
        },
      ],
    },
  },
  'items': {
    'rope': {'name': 'Rope'},
  },
  'start': 'a',
  'nodes': {
    'a': {'text': 'Hello, {name}.', 'ending': 'victory'},
  },
});

void main() {
  test('name the hero, pick a kit and begin', () {
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      PlaySession.start(_story, random: Random(1)),
      const Messages({'player.begin': 'Begin'}),
    );
    final begin =
        host.querySelector('.gb-creation > .btn:last-child')!
            as HTMLButtonElement;
    expect(begin.disabled, isTrue);

    final input = host.querySelector('input')! as HTMLInputElement
      ..value = 'Ann';
    input.dispatchEvent(Event('input'));
    (host.querySelector('.gb-picks .gb-choice')! as HTMLElement).click();
    final ready =
        host.querySelector('.gb-creation > .btn:last-child')!
            as HTMLButtonElement;
    expect(ready.disabled, isFalse);
    ready.click();

    expect(host.querySelector('.gb-page p')!.textContent, 'Hello, Ann.');
    expect(host.querySelector('.gb-pack summary'), isNotNull);
    host.remove();
  });
}
