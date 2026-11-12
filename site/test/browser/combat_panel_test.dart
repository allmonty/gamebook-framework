@TestOn('browser')
library;

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/ui/dom.dart';
import 'package:gamebook_site/src/ui/player_view.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

import '../support/scripted_random.dart';

final _story = Story.fromJson({
  'schema': 5,
  'id': 't',
  'lang': 'en',
  'title': 'Fight',
  'rules': {'preset': 'fighting-fantasy'},
  'start': 'ring',
  'nodes': {
    'ring': {
      'text': 'A rat.',
      'combat': {
        'enemies': [
          {'name': 'Rat', 'attack': 2, 'health': 2},
        ],
        'win': 'won',
        'flee': 'out',
      },
    },
    'won': {'text': 'Won.', 'ending': 'victory'},
    'out': {'text': 'Out.', 'ending': 'death'},
  },
});

void main() {
  test('attack until the enemy falls, with a log line per round', () {
    final host = el('div');
    document.body!.append(host);
    PlayerView(
      host,
      // Stats, then one round: you 6+6, the rat 1+1.
      PlaySession.start(
        _story,
        random: ScriptedRandom([3, 3, 3, 3, 6, 6, 1, 1]),
      ),
      const Messages({'player.fight': 'Attack', 'player.flee': 'Flee'}),
    );
    expect(host.querySelector('.gb-enemy strong')!.textContent, 'Rat');
    expect(host.querySelectorAll('.gb-combat button').length, 2);

    (host.querySelector('.gb-combat .btn')! as HTMLElement).click();

    expect(host.querySelector('.gb-combat'), isNull);
    expect(host.querySelector('.gb-ending.victory'), isNotNull);
    expect(host.querySelector('.gb-log li'), isNotNull);
    host.remove();
  });
}
