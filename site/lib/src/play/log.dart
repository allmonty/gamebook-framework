import 'package:gamebook_engine/dice.dart';
import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/story.dart';

/// How a log line should feel: good news, bad news, or neither.
enum Tone { good, bad, neutral }

/// One line of what just happened. The UI words it from the string
/// `player.log.<key>`, filling `{arg}`s from [args].
class LogLine {
  const LogLine(this.key, this.args, [this.tone = Tone.neutral]);

  final String key;
  final Map<String, Object> args;
  final Tone tone;
}

/// Turns engine events into log lines. Names are looked up through [name]
/// (items, stats, journal entries, achievements by id) so lines are ready to
/// show.
List<LogLine> logLines(
  Iterable<GameEvent> events, {
  required Story story,
  required String Function(String stat) statLabel,
}) => [for (final event in events) ...?_line(event, story, statLabel)];

List<LogLine>? _line(
  GameEvent event,
  Story story,
  String Function(String) statLabel,
) {
  String item(String id) => story.items[id]?.name ?? id;
  return switch (event) {
    CheckRolled(:final result) => [
      LogLine(result.passed ? 'check.pass' : 'check.fail', {
        'dice': dice(result.roll),
        'added': result.added,
        'total': result.total,
        'op': result.op == CheckOp.gte ? '≥' : '≤',
        'target': result.target,
      }, result.passed ? Tone.good : Tone.bad),
    ],
    TableRolled(:final roll) => [
      LogLine('table', {'dice': dice(roll), 'total': roll.total}),
    ],
    CombatRound(:final result) => [
      _round(
        result.enemy.name,
        result.playerAttack,
        result.playerTotal,
        result.damageToEnemy,
        result.damageToPlayer,
      ),
    ],
    CombatGroupRound(:final result) => [
      _round(
        result.target.name,
        result.playerAttack,
        result.playerTotal,
        result.damageToEnemy,
        result.attacks.fold(0, (sum, a) => sum + a.damageToPlayer),
      ),
    ],
    CombatStrike(:final result) => [
      LogLine('strike', {
        'enemy': result.enemy.name,
        'taken': result.damageToPlayer,
      }, result.damageToPlayer > 0 ? Tone.bad : Tone.neutral),
    ],
    CombatLuck(:final result) => [
      LogLine(result.lucky ? 'luck.lucky' : 'luck.unlucky', {
        'dice': dice(result.roll),
        'target': result.target,
      }, result.lucky ? Tone.good : Tone.bad),
    ],
    ItemGained(item: final id) => [
      LogLine('gained', {'item': item(id)}, Tone.good),
    ],
    ItemLost(item: final id) || ItemOverflow(item: final id) => [
      LogLine('lost', {'item': item(id)}, Tone.bad),
    ],
    ItemRefused(item: final id) => [
      LogLine('refused', {'item': item(id)}, Tone.bad),
    ],
    ItemUsed(item: final id) => [
      LogLine('used', {'item': item(id)}),
    ],
    StatChanged(:final stat, :final from, :final to) => [
      LogLine('stat', {
        'stat': statLabel(stat),
        'from': from,
        'to': to,
        'delta': to > from ? '+${to - from}' : '${to - from}',
      }, to > from ? Tone.good : Tone.bad),
    ],
    JournalUnlocked(:final entry) => [
      LogLine('journal', {
        'title': story.journal[entry]?.title ?? entry,
      }, Tone.good),
    ],
    AchievementEarned(:final achievement) => [
      LogLine('achievement', {
        'title': story.achievements[achievement]?.title ?? achievement,
      }, Tone.good),
    ],
    // Shown elsewhere (page, ending, audio) or the player's own decision.
    NodeEntered() ||
    Ended() ||
    MusicChanged() ||
    SoundPlayed() ||
    OfferDeclined() => null,
  };
}

LogLine _round(String enemy, DiceRoll roll, int total, int dealt, int taken) =>
    LogLine('round', {
      'enemy': enemy,
      'dice': dice(roll),
      'total': total,
      'dealt': dealt,
      'taken': taken,
    }, taken > dealt ? Tone.bad : Tone.good);

/// The faces rolled, e.g. `4+3`, with the modifier if any (`4+3+2`).
String dice(DiceRoll roll) => [
  ...roll.dice.map((d) => '$d'),
  if (roll.modifier != 0) '${roll.modifier}',
].join('+').replaceAll('+-', '-');
