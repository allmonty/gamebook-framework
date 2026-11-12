import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/play/views.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';
import 'support/stories.dart';

/// Faces for the Fighting Fantasy stat rolls: Skill 9, Stamina 18, Luck 9.
const _stats = [3, 3, 3, 3];

PlaySession _start(String conformanceCase, [List<int> dice = const []]) =>
    PlaySession.start(
      conformanceStory(conformanceCase),
      random: ScriptedRandom([..._stats, ...dice]),
    );

List<String> _keys(PlaySession s) => [for (final l in s.view.log) l.key];

void main() {
  test('a check logs the dice, the total and the result', () {
    final session = _start('check-pass', [6, 6])
      ..choose(1)
      ..choose(1);
    final line = session.view.log.single;
    expect(line.key, 'check.pass');
    expect(line.args, containsPair('dice', '6+6'));
    expect(line.args, containsPair('total', 21));
    expect(line.tone, Tone.good);
  });

  test('a check that adds nothing has a line without "+ 0"', () {
    final session = _start('check-effects-after-roll', [4, 4])..choose(0);
    expect(session.view.log.first.key, 'check.pass.plain');
  });

  test('a round nobody won is neither good nor bad news', () {
    // You 1+1+9, the goblin 2+2+7.
    final session = _start('opposed-win', [1, 1, 2, 2])
      ..choose(0)
      ..fight();
    expect(session.view.log.single.tone, Tone.neutral);
  });

  test('an outcome table logs its roll and its effects', () {
    final session = _start('random-table', [4])..choose(0);
    expect(_keys(session), ['table', 'stat']);
    expect(session.view.log.last.args, containsPair('stat', 'Gold'));
  });

  test('a fight hides the choices, shows the enemy and logs rounds', () {
    final session = _start('opposed-win', [6, 6, 1, 1, 6, 6, 1, 1])..choose(0);
    final combat = session.view.combat!;
    expect(session.view.choices, isEmpty);
    expect(combat.enemies.single.name, 'Goblin');
    expect(combat.enemies.single.current, isTrue);
    expect(combat.canFlee, isTrue);
    expect(combat.pickTarget, isFalse);

    session.fight();
    expect(_keys(session), ['round.vs']);
    // You 6+6+9, the goblin 1+1+7: the line shows both totals.
    expect(session.view.log.single.args, containsPair('total', 21));
    expect(session.view.log.single.args, containsPair('enemyTotal', 9));
    expect(session.view.combat!.enemies.single.health, 2);
    session.fight();
    expect(session.view.combat, isNull);
    expect(session.view.ending, Ending.victory);
    expect(_keys(session), ['round.vs', 'gained']);
  });

  test('a wound can end the fight: the round is logged, its page follows', () {
    final session = _start('fight-wounded', [1, 1, 6, 6])..fight();
    expect(_keys(session).first, 'round.vs');
    expect(session.view.combat, isNull);
    expect(session.view.paragraphs, ['Stung']);
    expect(session.view.choices.single.text, 'On');
  });

  test('so can the round limit', () {
    final session = _start('fight-rounds', [3, 3, 4, 4, 3, 3, 4, 4])
      ..fight()
      ..fight();
    expect(_keys(session), ['round.vs']);
    expect(session.view.combat, isNull);
    expect(session.view.paragraphs, ['Gone']);
  });

  test('the poison-sting example leaves its fight both ways', () {
    PlaySession sting(List<int> dice) => PlaySession.start(
      storyFile('examples/06-combat/poison-sting.en.json'),
      random: ScriptedRandom([..._stats, ...dice]),
    )..choose(0);

    final stung = sting([1, 1, 6, 6])..fight();
    expect(stung.view.ending, Ending.defeat);

    final gone = sting([3, 3, 4, 4, 3, 3, 4, 4, 3, 3, 4, 4])
      ..fight()
      ..fight()
      ..fight();
    expect(gone.view.combat, isNull);
    expect(gone.view.choices.single.text, 'Walk on');
  });

  test('a flee that costs a round says so, and the enemy strikes first', () {
    for (final lang in ['en', 'pt']) {
      final session = PlaySession.start(
        storyFile('examples/06-combat/the-evasion.$lang.json'),
        random: ScriptedRandom(_stats),
      )..choose(0);
      expect(session.view.combat!.fleeCostsRound, isTrue, reason: lang);

      session.flee();

      expect(_keys(session).first, 'strike', reason: lang);
      expect(session.view.ending, Ending.defeat, reason: lang);
    }
  });

  test('fleeing leaves the fight', () {
    final session = _start('flee', [1, 1, 6, 6])
      ..choose(0)
      ..fight()
      ..flee();
    expect(session.view.combat, isNull);
    expect(session.view.paragraphs, ['Hall']);
  });

  test('several enemies at once ask for a target', () {
    final session = _start('group-fight-opposed', [4, 4, 6, 5, 1, 1]);
    expect(session.view.combat!.pickTarget, isTrue);
    session.fight(target: 1);
    expect(session.view.combat!.enemies[1].health, lessThan(4));
  });

  test('luck can be tested after a round that hurt someone', () {
    final session = _start('fight-luck-lucky', [6, 6, 1, 1, 2, 2])..fight();
    expect(session.view.combat!.canTestLuck, isTrue);
    session.testLuck();
    expect(session.view.log.first.key, 'luck.lucky');
  });

  test('journal entries, newest first, and achievements', () {
    final journal = _start('journal');
    expect(journal.view.journal.single.title, isNotEmpty);
    expect(_keys(journal), contains('journal'));

    final achievements = _start('achievements', _stats)..choose(0);
    expect(achievements.view.achievements, hasLength(2));
    achievements.restart();
    expect(achievements.view.achievements, hasLength(2), reason: 'kept');
  });

  test('undo goes back a page', () {
    final session = _start('undo')..choose(0);
    expect(session.view.canUndo, isTrue);
    session.undo();
    expect(session.view.paragraphs, ['A']);
    expect(session.view.canUndo, isFalse);
  });

  test('music carries over pages until changed', () {
    final session = _start('music-carries');
    expect(session.view.audio.music, 'audio/rain.ogg');
    session.choose(0);
    expect(session.view.audio.music, 'audio/rain.ogg');
  });
}
