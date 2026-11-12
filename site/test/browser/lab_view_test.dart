@TestOn('browser')
library;

import 'dart:convert';
import 'dart:math';

import 'package:gamebook_site/src/play/edit_session.dart';
import 'package:gamebook_site/src/ui/dom.dart';
import 'package:gamebook_site/src/ui/lab_view.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

final _source = const JsonEncoder.withIndent('  ').convert({
  'schema': 1,
  'id': 't',
  'lang': 'en',
  'title': 'Lab',
  'rules': {'preset': 'fighting-fantasy'},
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'Start.',
      'choices': [
        {'text': 'On', 'to': 'b'},
      ],
    },
    'b': {'text': 'End.', 'ending': 'victory'},
  },
});

void main() {
  test("pictures load from the example's folder", () {
    final host = el('div');
    document.body!.append(host);
    LabView(
      host,
      EditSession(
        jsonEncode({
          'schema': 1,
          'id': 't',
          'lang': 'en',
          'title': 'Lab',
          'rules': {'preset': 'fighting-fantasy'},
          'start': 'a',
          'nodes': {
            'a': {
              'text': 'Hall.',
              'image': 'images/hall.png',
              'imageAlt': 'A hall.',
              'ending': 'victory',
            },
          },
        }),
        Random(1),
      ),
      const Messages({}),
      mediaBase: '../../examples/x/',
    );
    final image = host.querySelector('.gb-page img')!;
    expect(image.getAttribute('src'), '../../examples/x/images/hall.png');
    expect(image.getAttribute('alt'), 'A hall.');
    host.remove();
  });

  test(
    'editing re-checks the story; errors stop play; reset restores',
    () async {
      final host = el('div');
      document.body!.append(host);
      LabView(
        host,
        EditSession(_source, Random(1)),
        const Messages({
          'player.cannotPlay': 'Fix it',
          'player.reset': 'Reset',
        }),
        pause: Duration.zero,
      );
      expect(host.querySelector('.gb-page p')!.textContent, 'Start.');

      final area = host.querySelector('textarea')! as HTMLTextAreaElement
        ..value = _source.replaceFirst('"to": "b"', '"to": "nowhere"');
      area.dispatchEvent(Event('input'));
      await Future<void>.delayed(Duration.zero);

      expect(host.querySelector('.gb-issues li.error'), isNotNull);
      expect(host.querySelector('.gb-cannot')!.textContent, 'Fix it');

      final buttons = host.querySelectorAll('.gb-edit .btn');
      (buttons.item(0)! as HTMLElement).click(); // Reset
      expect(host.querySelector('.gb-issues li.error'), isNull);
      expect(host.querySelector('.gb-page p')!.textContent, 'Start.');
      host.remove();
    },
  );
}
