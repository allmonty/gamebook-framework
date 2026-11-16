import 'dart:math';

import 'engine.dart';
import 'rules.dart';
import 'story.dart';

/// How a simulated player chooses.
enum Policy {
  /// Any open choice, at random; takes every item offered.
  random,

  /// Prefers choices that lead to a page it has not seen in this game.
  explore,

  /// Like [random], but leaves every item it is offered (framework B4: a
  /// story must stay winnable for a player who declines).
  decline,
}

/// How one simulated game ended.
enum Outcome { victory, defeat, death, stuck, endless }

/// What many simulated games of a story did. The simulated player takes
/// choices, fights, tests luck, flees and answers offers; it never uses an
/// item and never undoes, so a story that needs a potion drunk reads harder
/// than it is, and a page whose only way on is undo reads as stuck. It finds
/// what no static check can: dead ends that depend on state, endings that
/// are never reached, stories that are much too hard or too easy.
///
/// It also estimates how long a game takes ([minutes]): every page it enters
/// is read at 200 words a minute (the text shown and its choices), and every
/// action (a choice, a round of a fight, an offer) takes 5 seconds. Both
/// numbers are guesses for an unhurried reader, so the result is "about".
class SimulationReport {
  SimulationReport._(this.story, this.games);

  final Story story;
  final int games;
  final outcomes = <Outcome, int>{for (final o in Outcome.values) o: 0};

  /// How many games ended on each ending page.
  final endings = <String, int>{};

  /// How many games got stuck on each page (no choice open, no fight, not an
  /// ending: a draft, or every choice locked).
  final stuck = <String, int>{};

  /// Every page some game entered.
  final visited = <String>{};
  int _steps = 0;
  final _wonMinutes = <double>[];
  final _endedMinutes = <double>[];

  /// About how many minutes one game takes: the median of the games that
  /// reached a victory, or of every game that reached an ending when none
  /// won. The median, because a few random games wander far longer than a
  /// person would. 0 when no game reached an ending.
  double get minutes {
    final of = _wonMinutes.isEmpty ? _endedMinutes : _wonMinutes;
    if (of.isEmpty) return 0;
    final sorted = [...of]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Ending pages no game reached.
  List<String> get unreachedEndings => [
    for (final node in story.nodes.values)
      if (node.ending != null && !endings.containsKey(node.id)) node.id,
  ];

  /// Pages no game entered.
  List<String> get unvisited => [
    for (final id in story.nodes.keys)
      if (!visited.contains(id)) id,
  ];

  double rate(Outcome o) => games == 0 ? 0 : outcomes[o]! / games;
  double get averageSteps => games == 0 ? 0 : _steps / games;

  @override
  String toString() {
    String pct(Outcome o) => '${(rate(o) * 100).toStringAsFixed(1)}%';
    String list(Iterable<String> ids) => ids.isEmpty ? 'none' : ids.join(', ');
    final byCount = [...stuck.entries]..sort((a, b) => b.value - a.value);
    return [
      '$games games of "${story.title}": '
          'victory ${pct(Outcome.victory)}, defeat ${pct(Outcome.defeat)}, '
          'death ${pct(Outcome.death)}, '
          'stuck ${pct(Outcome.stuck)}, endless ${pct(Outcome.endless)}; '
          '${averageSteps.toStringAsFixed(1)} steps on average, '
          'about ${minutes.round()} min per game.',
      'Endings reached: ${list([for (final e in endings.entries) '${e.key} ${e.value}'])}.',
      'Endings never reached: ${list(unreachedEndings)}.',
      'Pages never entered: ${list(unvisited)}.',
      'Stuck on: ${list([for (final e in byCount) '${e.key} ${e.value}'])}.',
    ].join('\n');
  }
}

/// Plays [games] games of [story] with [policy], each with a fresh
/// character, and reports what happened. A game that takes more than
/// [maxSteps] actions counts as endless. The same [random] seed gives the
/// same report.
SimulationReport simulate(
  Story story, {
  int games = 1000,
  Policy policy = Policy.random,
  int maxSteps = 2000,
  Random? random,
}) {
  final rules = Rules.resolve(story.rules);
  final rng = random ?? Random();
  final report = SimulationReport._(story, games);
  for (var g = 0; g < games; g++) {
    final picks = <Effect>[
      for (final group in rules.creation?.picks ?? const <PickGroup>[])
        for (final option in ([
          ...group.options,
        ]..shuffle(rng)).take(group.count))
          ...option.effects,
    ];
    final (engine, _) = GameEngine.newGame(
      story: story,
      rules: rules,
      random: rng,
      stats: rules.rollStats(rng),
      name: (rules.creation?.name ?? false) ? 'Hero' : null,
      creationEffects: picks,
    );
    report.visited.add(engine.node.id);
    final outcome = _play(engine, policy, maxSteps, rng, report);
    report.outcomes[outcome] = report.outcomes[outcome]! + 1;
    final at = engine.node.id;
    switch (outcome) {
      case Outcome.victory || Outcome.defeat || Outcome.death:
        if (engine.node.ending != null) {
          report.endings[at] = (report.endings[at] ?? 0) + 1;
        }
      case Outcome.stuck:
        report.stuck[at] = (report.stuck[at] ?? 0) + 1;
      case Outcome.endless:
        break;
    }
  }
  return report;
}

Outcome _play(
  GameEngine engine,
  Policy policy,
  int maxSteps,
  Random rng,
  SimulationReport report,
) {
  final seen = <String>{engine.node.id};
  int words(Iterable<String> texts) => texts.fold(
    0,
    (n, t) => n + t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
  );
  int read() =>
      words(engine.paragraphs) + words(engine.choices.map((c) => c.text));
  var wordsRead = read();
  for (var step = 0; step < maxSteps; step++) {
    report._steps++;
    if (engine.ending case final ending?) {
      final minutes = wordsRead / 200 + step * 5 / 60;
      report._endedMinutes.add(minutes);
      if (ending == Ending.victory) report._wonMinutes.add(minutes);
      return switch (ending) {
        Ending.victory => Outcome.victory,
        Ending.defeat => Outcome.defeat,
        Ending.death => Outcome.death,
      };
    }
    if (engine.offer != null) {
      if (policy == Policy.decline) {
        engine.resolveOffer(take: false);
      } else if (!engine.offerNeedsRoom) {
        engine.resolveOffer(take: true);
      } else {
        final carried = [
          for (final i in engine.state.inventory)
            if (!engine.isContainer(i)) i,
        ];
        carried.isEmpty
            ? engine.resolveOffer(take: false)
            : engine.resolveOffer(
                take: true,
                replacing: carried[rng.nextInt(carried.length)],
              );
      }
      continue;
    }
    final before = engine.node.id;
    final choosing = engine.combat == null;
    if (engine.combat case final fight?) {
      if (engine.canTestLuck && rng.nextBool()) {
        engine.testLuck();
      } else if (engine.canFlee && rng.nextInt(10) == 0) {
        engine.flee();
      } else {
        final health = engine.state.combat!.enemyHealth;
        final living = [
          for (var i = 0; i < health.length; i++)
            if (health[i] > 0) i,
        ];
        engine.fight(
          target: fight.simultaneous
              ? living[rng.nextInt(living.length)]
              : null,
        );
      }
    } else {
      final open = engine.choices.where((c) => !c.locked).toList();
      if (open.isEmpty) return Outcome.stuck;
      var pool = open;
      if (policy == Policy.explore) {
        final fresh = [
          for (final c in open)
            if (c.choice.to case final to? when !seen.contains(to)) c,
        ];
        if (fresh.isNotEmpty) pool = fresh;
      }
      engine.choose(pool[rng.nextInt(pool.length)].index);
    }
    // A choice shows a page again even when it leads back to the same one.
    if (choosing || engine.node.id != before) wordsRead += read();
    seen.add(engine.node.id);
    report.visited.add(engine.node.id);
  }
  return Outcome.endless;
}
