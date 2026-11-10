// Packs a game folder into a .gamebook file (spec/framework.md B14):
// `dart run gamebook_engine:pack_game <game-folder> [out.gamebook]`.
// Exits 1 if the game cannot be packed, 2 on bad usage.
import 'dart:io';
import 'dart:typed_data';

import 'package:gamebook_engine/package.dart';

/// The package for the game in [dir], its story id, and the files of the
/// folder left out because they do not belong in a package.
({Uint8List bytes, String id, List<String> skipped}) packFolder(String dir) {
  var root = Directory(dir).absolute.path;
  if (root.endsWith(Platform.pathSeparator)) {
    root = root.substring(0, root.length - 1);
  }
  final files = <String, List<int>>{};
  final skipped = <String>[];
  for (final entity in Directory(
    root,
  ).listSync(recursive: true, followLinks: false)) {
    final path = entity.path
        .substring(root.length + 1)
        .replaceAll(Platform.pathSeparator, '/');
    if (entity is Directory) continue;
    if (entity is File && belongsInPackage(path)) {
      files[path] = entity.readAsBytesSync();
    } else {
      skipped.add(path);
    }
  }
  final bytes = writePackage(files);
  return (bytes: bytes, id: readPackage(bytes).id, skipped: skipped..sort());
}

/// Runs the packer over [args], reporting to [out]. Returns the exit code.
int runPackGame(List<String> args, StringSink out) {
  if (args.isEmpty || args.length > 2 || !Directory(args.first).existsSync()) {
    out.writeln('Usage: pack_game <game-folder> [out.gamebook]');
    return 2;
  }
  try {
    final (:bytes, :id, :skipped) = packFolder(args.first);
    final target = args.length == 2 ? args[1] : '$id.gamebook';
    File(target).writeAsBytesSync(bytes);
    for (final path in skipped) {
      out.writeln('left out: $path');
    }
    out.writeln('wrote $target (${bytes.length} bytes)');
    return 0;
  } on PackageException catch (e) {
    out.writeln('cannot pack ${args.first}: $e');
    return 1;
  }
}

void main(List<String> args) => exit(runPackGame(args, stdout));
