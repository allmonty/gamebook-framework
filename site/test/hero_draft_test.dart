import 'dart:math';

import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_site/src/play/hero_draft.dart';
import 'package:gamebook_site/src/play/play_session.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';
import 'support/stories.dart';

Rules _rules(String conformanceCase) =>
    Rules.resolve(conformanceStory(conformanceCase).rules);

void main() {
  test('rerolls replace every stat until none are left', () {
    final draft = HeroDraft(
      _rules('creation-rerolls'),
      ScriptedRandom([1, 1, 1, 1, 6, 6, 6, 6]),
    );
    expect(draft.view.stats.map((s) => s.value), [7, 14, 7]);
    expect(draft.rerollsLeft, 2);
    draft.reroll();
    expect(draft.view.stats.map((s) => s.value), [12, 24, 12]);
    expect(draft.rerollsLeft, 1);
  });

  test('picks fill each group up to its count, effects in file order', () {
    final draft = HeroDraft(_rules('creation-picks'), Random(1));
    expect(draft.ready, isFalse);
    draft
      ..toggle('kit', 'lamp')
      ..toggle('kit', 'torch')
      ..toggle('kit', 'rope') // the group is full: ignored
      ..toggle('trait', 'brave');
    expect(draft.ready, isTrue);
    final kit = draft.view.groups.first;
    expect(kit.picked, 2);
    expect(kit.options.map((o) => o.picked), [true, false, true]);
    expect(draft.effects, hasLength(4));
    draft.toggle('kit', 'lamp'); // unpick
    expect(draft.ready, isFalse);
  });

  test('a story that asks for a name waits for it', () {
    final session = PlaySession.start(
      conformanceStory('creation-name'),
      random: Random(1),
    );
    final draft = session.creation!;
    expect(draft.view.asksName, isTrue);
    expect(() => session.view, throwsStateError);
    expect(session.beginAdventure, throwsStateError);
    draft.name = '  Ann ';
    session.beginAdventure();
    expect(session.creation, isNull);
    expect(session.view.paragraphs, ['Good luck, Ann.']);
  });

  test('stories without creation skip it, restart included', () {
    final session = PlaySession.start(
      conformanceStory('locked-choice'),
      random: Random(1),
    );
    expect(session.creation, isNull);
    session.restart();
    expect(session.creation, isNull);
  });

  test('picked items and flags reach the game', () {
    final session = PlaySession.start(
      conformanceStory('creation-picks'),
      random: Random(1),
    );
    session.creation!
      ..toggle('kit', 'torch')
      ..toggle('kit', 'rope')
      ..toggle('trait', 'brave');
    session.beginAdventure();
    // Capacity 1: the newest pick (rope) is dropped.
    expect(session.view.pack.items.map((i) => i.id), ['torch']);
  });
}
