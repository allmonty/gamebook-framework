// Builds the site into site/build: `dart run tool/build.dart [--no-js]`.
// --no-js skips compiling the player, for quick content edits.
import 'dart:io';

import 'package:gamebook_site/src/content/site_builder.dart';

Future<void> main(List<String> args) async {
  final site = Directory.fromUri(Platform.script.resolve('..'));
  final output = Directory.fromUri(site.uri.resolve('build'));
  SiteBuilder(source: site, output: output).build();
  if (args.contains('--no-js')) return;
  final result = await Process.run('dart', [
    'compile',
    'js',
    '-O2',
    '-o',
    '${output.path}/js/main.dart.js',
    site.uri.resolve('web/main.dart').toFilePath(),
  ]);
  if (result.exitCode != 0) {
    stderr
      ..write(result.stdout)
      ..write(result.stderr);
    exit(result.exitCode);
  }
  stdout.writeln('Built ${output.path}');
}
