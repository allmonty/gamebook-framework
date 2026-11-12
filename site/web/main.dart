// Browser entry point: wiring only. Turns every example embed on the page
// into a player.
import 'dart:convert';
import 'dart:math';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/ui/dom.dart';
import 'package:gamebook_site/src/ui/player_view.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:web/web.dart';

void main() {
  final messages = Messages(
    (jsonDecode(
      document.getElementById('gb-strings')?.textContent ?? '{}',
    ) as Map<String, Object?>).cast<String, String>(),
  );
  final embeds = document.querySelectorAll('.gb-embed');
  for (var i = 0; i < embeds.length; i++) {
    _mount(embeds.item(i)! as HTMLElement, messages);
  }
}

void _mount(HTMLElement embed, Messages messages) {
  final source = embed.querySelector('script[type="application/json"]');
  final host = el('div');
  embed.append(host);
  try {
    final story = Story.parse(source?.textContent ?? '');
    PlayerView(host, PlaySession.start(story, random: Random()), messages);
  } on StoryFormatException catch (e) {
    host.textContent = e.toString();
  }
}
