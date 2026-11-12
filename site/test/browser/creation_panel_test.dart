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

  test('picking an option keeps keyboard focus on it', () {
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      PlaySession.start(_story, random: Random(1)),
      const Messages({}),
    );
    final option = host.querySelector('.gb-picks .gb-choice')! as HTMLElement
      ..focus();
    option.click();

    final focused = document.activeElement!;
    expect(focused, isNot(same(option)), reason: 'the panel was redrawn');
    expect(focused.getAttribute('data-key'), 'kit.rope');
    expect(focused.getAttribute('aria-pressed'), 'true');
    host.remove();
  });

  test('a full group marks the options that can no longer be picked', () {
    final json = {
      'schema': 1,
      'id': 't',
      'lang': 'en',
      'title': 'Hero',
      'rules': {
        'preset': 'fighting-fantasy',
        'creation': {
          'picks': [
            {
              'id': 'kit',
              'title': 'Kit',
              'count': 1,
              'options': [
                {'id': 'rope', 'label': 'Rope'},
                {'id': 'lamp', 'label': 'Lamp'},
              ],
            },
          ],
        },
      },
      'start': 'a',
      'nodes': {
        'a': {'text': 'A.', 'ending': 'victory'},
      },
    };
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      PlaySession.start(Story.fromJson(json), random: Random(1)),
      const Messages({}),
    );
    expect(host.querySelector('[aria-disabled]'), isNull);
    expect(
      host.querySelector('.gb-index')!.getAttribute('aria-hidden'),
      'true',
    );

    (host.querySelector('[data-key="kit.rope"]')! as HTMLElement).click();

    final lamp = host.querySelector('[data-key="kit.lamp"]')!;
    expect(lamp.getAttribute('aria-disabled'), 'true');
    expect(
      host
          .querySelector('[data-key="kit.rope"]')!
          .getAttribute('aria-disabled'),
      isNull,
    );
    host.remove();
  });
}
