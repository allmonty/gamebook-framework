// Plays a story many times at random and reports what happened:
// `dart run gamebook_engine:simulate_story <story.json> [--games N]
// [--policy random|explore|decline] [--seed N]`.
// Exits 1 if any game got stuck or never ended, 2 on bad usage.
import 'dart:io';
import 'dart:math';

import 'package:gamebook_engine/simulate.dart';
import 'package:gamebook_engine/story.dart';

const _usage =
    'Usage: simulate_story <story.json> [--games N] '
    '[--policy random|explore|decline] [--seed N]';

/// Runs the simulator over [args], reporting to [out]. Returns the exit code.
int runSimulator(List<String> args, StringSink out) {
  String? option(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final files = [
    for (var i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') &&
          (i == 0 || !args[i - 1].startsWith('--')))
        args[i],
  ];
  final games = int.tryParse(option('games') ?? '1000');
  final policy = Policy.values
      .where((p) => p.name == (option('policy') ?? 'random'))
      .firstOrNull;
  final seed = option('seed') == null ? null : int.tryParse(option('seed')!);
  if (files.length != 1 ||
      games == null ||
      games < 1 ||
      policy == null ||
      (option('seed') != null && seed == null)) {
    out.writeln(_usage);
    return 2;
  }
  final Story story;
  try {
    story = Story.parse(File(files.single).readAsStringSync());
  } on Object catch (e) {
    out.writeln('${files.single}: $e');
    return 2;
  }
  final report = simulate(
    story,
    games: games,
    policy: policy,
    random: seed == null ? null : Random(seed),
  );
  out.writeln(report);
  return report.outcomes[Outcome.stuck]! + report.outcomes[Outcome.endless]! > 0
      ? 1
      : 0;
}

void main(List<String> args) => exit(runSimulator(args, stdout));
