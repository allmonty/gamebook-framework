import 'package:gamebook_site/src/play/play_session.dart';
import 'package:gamebook_site/src/play/views.dart';
import 'package:test/test.dart';

import 'support/scripted_random.dart';
import 'support/stories.dart';

/// Skill 9, Stamina 18, Luck 9, Credits 5.
const _stats = [3, 3, 3, 3, 3];

PlaySession _start(List<int> dice, {required String kit}) {
  final session = PlaySession.start(
    storyFile('examples/showcase/rune-vault.en.json'),
    random: ScriptedRandom([..._stats, ...dice]),
  );
  session.creation!
    ..name = 'Ann'
    ..toggle('kit', kit);
  return session..beginAdventure();
}

/// One opposed round won against [enemies] living enemies, all of them
/// rolling 1+1 against your 6+6.
List<int> _round(int enemies) => [
  6,
  6,
  for (var i = 0; i < enemies; i++) ...[1, 1],
];

void main() {
  test('the shiv route: shard, a two-enemy fight, the core lock', () {
    final session = _start([
      ..._round(2), ..._round(2), // the drone falls
      for (var i = 0; i < 6; i++) ..._round(1), // armor 1: 1 wound a round
    ], kit: 'shiv');
    expect(session.view.paragraphs.first, contains('Ann'));

    session
      ..choose(0) // search the bunk
      ..takeOffer() // the data shard
      ..choose(0); // back
    expect(session.view.journal.single.title, 'Guard rota');
    expect(session.view.paragraphs, hasLength(2), reason: 'second visit');

    session
      ..choose(1) // pry the door with the shiv
      ..choose(2); // the vault core
    expect(session.view.combat!.pickTarget, isTrue);
    session
      ..fight(target: 1)
      ..fight(target: 1);
    expect(session.view.combat!.enemies[1].alive, isFalse);
    for (var i = 0; i < 6; i++) {
      session.fight(target: 0);
    }
    expect(session.view.combat, isNull);
    session.choose(0); // slot the shard
    expect(session.view.ending, Ending.victory);
    expect(session.view.achievements, ['Vault breaker']);
  });

  test('the shaft can kill, and undo takes it back', () {
    final session = _start([6, 6, 1], kit: 'charm');
    expect(session.view.stats.firstWhere((s) => s.id == 'luck').bonus, 1);
    session
      ..choose(2) // force the door: 6+6+9 = 21
      ..choose(1); // the shaft: rolls 1
    expect(session.view.ending, Ending.death);
    expect(session.view.canUndo, isTrue);
    session.undo();
    expect(session.view.ending, isNull);
  });
}
