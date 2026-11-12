import 'dart:math';

import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/play/views.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';
import 'support/stories.dart';

void main() {
  test('shows the first page, its choices and the rolled stats', () {
    final session = PlaySession.start(
      conformanceStory('locked-choice'),
      random: Random(1),
    );
    final view = session.view;
    expect(view.storyTitle, 'The Rusty Door');
    expect(view.paragraphs.single, startsWith('You wake in a cold cellar.'));
    expect(view.choices.map((c) => c.text), [
      'Search the shelves',
      'Go to the door',
    ]);
    expect(view.stats.map((s) => s.label), ['Skill', 'Stamina', 'Luck']);
    expect(view.stats.every((s) => s.value > 0), isTrue);
    expect(view.ending, isNull);
  });

  test('a locked choice says which item it needs; a check is marked', () {
    final session = PlaySession.start(
      conformanceStory('locked-choice'),
      random: Random(1),
    )..choose(1);
    final [unlock, kick] = session.view.choices;
    expect(unlock.locked, isTrue);
    expect(unlock.needs.single.kind, RequirementKind.item);
    expect(unlock.needs.single.name, 'Rusty key');
    expect(kick.locked, isFalse);
    expect(kick.kind, ChoiceKind.check);
  });

  test('a stat requirement names the label, comparison and target', () {
    final session = PlaySession.start(
      storyOf({
        'gate': {
          'text': 'A toll gate.',
          'choices': [
            {
              'text': 'Pay',
              'to': 'end',
              'if': {'stat': 'luck', 'gte': 99},
            },
            {
              'text': 'Pay',
              'to': 'end',
              'if': {'stat': 'luck', 'gte': 99},
              'lockedText': 'Too poor',
            },
          ],
        },
        'end': {'text': 'Done.', 'ending': 'victory'},
      }),
      random: Random(1),
    );
    final [plain, worded] = session.view.choices;
    final need = plain.needs.single;
    expect(need.kind, RequirementKind.stat);
    expect(need.name, 'Luck');
    expect(need.op, CompareOp.gte);
    expect(need.target, 99);
    expect(worded.lockedText, 'Too poor');
  });

  test('reaching an ending removes the choices; restart starts over', () {
    final session = PlaySession.start(
      storyOf({
        'start': {
          'text': 'Go.',
          'choices': [
            {'text': 'Win', 'to': 'won'},
          ],
        },
        'won': {'text': 'You won.', 'ending': 'victory'},
      }),
      random: Random(1),
    )..choose(0);
    expect(session.view.ending, Ending.victory);
    expect(session.view.choices, isEmpty);
    session.restart();
    expect(session.view.ending, isNull);
    expect(session.view.paragraphs, ['Go.']);
  });

  test('a defeat ending ends the game with the hero alive', () {
    final session = PlaySession.start(
      storyOf(
        {
          'start': {
            'text': 'Go.',
            'choices': [
              {'text': 'Surrender', 'to': 'cell'},
            ],
          },
          'cell': {'text': 'Locked up.', 'ending': 'defeat'},
        },
        extra: {'schema': 8},
      ),
      random: Random(1),
    )..choose(0);
    expect(session.view.ending, Ending.defeat);
    expect(session.view.choices, isEmpty);
  });

  test('a stat at a quarter of its ceiling is low', () {
    expect(const StatPill(id: 'h', label: 'H', value: 3, max: 12).low, isTrue);
    expect(const StatPill(id: 'h', label: 'H', value: 4, max: 12).low, isFalse);
    expect(const StatPill(id: 'g', label: 'G', value: 0).low, isFalse);
  });

  test('with showTitles the heading is the page title, or none', () {
    final session = PlaySession.start(
      storyOf(
        {
          'a': {
            'title': 'The gate',
            'text': 'A.',
            'choices': [
              {'text': 'On', 'to': 'b'},
            ],
          },
          'b': {'text': 'B.', 'ending': 'victory'},
        },
        extra: {'showTitles': true},
      ),
      random: Random(1),
    );
    expect(session.view.heading, 'The gate');
    session.choose(0);
    expect(session.view.heading, isNull);
  });

  test('the page image comes with its description, or none', () {
    final session = PlaySession.start(
      storyOf(
        {
          'a': {
            'text': 'A.',
            'image': 'images/gate.webp',
            'imageAlt': 'An iron gate in the fog.',
            'choices': [
              {'text': 'On', 'to': 'b'},
            ],
          },
          'b': {'text': 'B.', 'image': 'images/b.webp', 'ending': 'victory'},
        },
        extra: {'schema': 8},
      ),
      random: Random(1),
    );
    expect(session.view.imageAlt, 'An iron gate in the fog.');
    session.choose(0);
    expect(session.view.image, 'images/b.webp');
    expect(session.view.imageAlt, isNull);
  });

  test('the cursed gauntlet takes Might below zero', () {
    for (final lang in ['en', 'pt']) {
      // Might 1, Agility 1, Wits 1, HP 2+2+8.
      final session = PlaySession.start(
        storyFile('examples/04-stats-and-hero/cursed-gauntlet.$lang.json'),
        random: ScriptedRandom([1, 1, 1, 2, 2]),
      )..choose(0);
      final might = session.view.stats.firstWhere((s) => s.id == 'might');
      expect((might.value, might.bonus), (-3, -4), reason: lang);
      expect(session.view.paragraphs.single, contains('-3'), reason: lang);
    }
  });

  test('without showTitles the heading is the story title', () {
    final session = PlaySession.start(
      conformanceStory('locked-choice'),
      random: Random(1),
    );
    expect(session.view.heading, 'The Rusty Door');
  });
}
