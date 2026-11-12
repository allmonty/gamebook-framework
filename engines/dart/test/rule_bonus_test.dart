import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/state.dart';
import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/validate.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';

/// Fighting Fantasy with rule [bonuses]; page `a` gives [give] and its
/// choice takes [take].
Map<String, Object?> json({
  List<Map<String, Object?>> bonuses = const [],
  int schema = 1,
  List<String> give = const [],
  List<String> take = const [],
}) => {
  'schema': schema,
  'id': 'rb',
  'lang': 'en',
  'title': 'RB',
  'rules': {'preset': 'fighting-fantasy', 'bonuses': bonuses},
  'items': {
    'sword': {'name': 'Sword'},
    'ring': {
      'name': 'Ring',
      'bonus': {'skill': 1},
    },
  },
  'start': 'a',
  'nodes': {
    'a': {
      'text': 'Skill {skill}.',
      'once': true,
      'effects': [
        for (final i in give) {'give': i},
      ],
      'choices': [
        {
          'text': 'On',
          'to': 'a',
          'effects': [
            for (final i in take) {'take': i},
          ],
        },
      ],
    },
  },
};

const unarmed = {
  'if': {
    'not': {'has': 'sword'},
  },
  'bonus': {'skill': -4},
};

GameEngine play(Map<String, Object?> j) {
  final story = Story.fromJson(j);
  return GameEngine.newGame(
    story: story,
    rules: Rules.resolve(story.rules),
    random: ScriptedRandom(const []),
    stats: const {
      'skill': StatValue(9, 12),
      'stamina': StatValue(12, 24),
      'luck': StatValue(8, 12),
    },
  ).$1;
}

void main() {
  test('a rule bonus applies while its condition holds', () {
    final engine = play(
      json(bonuses: [unarmed], give: ['sword'], take: ['sword']),
    );
    expect(engine.state.stat('skill'), 9);

    engine.choose(0);

    expect(engine.state.stat('skill'), 5);
    expect(engine.state.bonusOf('skill'), -4);
    expect(engine.paragraphs.single, 'Skill 5.');
    expect(engine.state.stats['skill']!.value, 9);
  });

  test('it adds to item bonuses', () {
    final engine = play(json(bonuses: [unarmed], give: ['ring']));
    expect(engine.state.bonusOf('skill'), -3);
  });

  test('its condition sees item bonuses but no rule bonus, so it cannot '
      'switch itself', () {
    const sharp = {
      'if': {'stat': 'skill', 'gte': 10},
      'bonus': {'skill': 2},
    };
    // Skill 9: off; it would be on at 11 only if it could see itself.
    expect(play(json(bonuses: [sharp])).state.stat('skill'), 9);
    // Skill 9 + 1 from the ring is 10: on.
    expect(
      play(json(bonuses: [sharp], give: ['ring'])).state.stat('skill'),
      12,
    );
  });

  test('a rule bonus on the health stat is an error', () {
    final story = Story.fromJson(
      json(
        bonuses: [
          {
            'if': {'has': 'sword'},
            'bonus': {'stamina': 2},
          },
        ],
      ),
    );
    expect(
      [
        for (final i in validateStory(story))
          if (i.severity == Severity.error) '$i',
      ],
      [
        'error: rules.bonuses[0].bonus.stamina: '
            'a bonus to the health stat is not allowed',
      ],
    );
  });
}
