import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'story.dart';
import 'validate.dart';

/// Why a `.gamebook` file was refused (spec/framework.md B14).
class PackageException implements Exception {
  const PackageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A game read from a `.gamebook` file: its stories by language and every
/// other file (images, audio, `builder.json`) by its path in the package.
class GamePackage {
  const GamePackage({
    required this.id,
    required this.stories,
    required this.sources,
    required this.files,
  });

  /// The `id` every story in the package shares.
  final String id;

  /// Language code to story, in code order.
  final Map<String, Story> stories;

  /// Story file name (`story.en.json`) to its JSON text, as packed, so a
  /// player can store the game exactly as it came.
  final Map<String, String> sources;

  /// Path inside the package (`images/a.webp`) to its bytes. The story files
  /// themselves are not repeated here.
  final Map<String, Uint8List> files;
}

/// Limits from B14, checked before anything is unpacked.
const maxPackageBytes = 100 * 1024 * 1024;
const maxPackageFiles = 2000;

/// The file types of the media a game may ship (B14).
const mediaTypes = {
  '.webp',
  '.png',
  '.jpg',
  '.jpeg',
  '.ogg',
  '.mp3',
  '.wav',
  '.m4a',
};
// `story.schema.json` is the JSON Schema, not a story in some language.
final _storyFile = RegExp(r'^story\.(?!schema\.)([A-Za-z-]+)\.json$');

/// Reads and checks a `.gamebook` file. Throws [PackageException] saying why
/// it is refused. [maxBytes] and [maxFiles] exist for tests.
GamePackage readPackage(
  List<int> bytes, {
  int maxBytes = maxPackageBytes,
  int maxFiles = maxPackageFiles,
}) {
  // Every zip starts with "PK"; the decoder takes some other bytes for an
  // empty archive, which would read as "no story file".
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
    throw const PackageException('not a zip file');
  }
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes, verify: true);
  } on Object catch (_) {
    throw const PackageException('not a zip file');
  }
  final entries = archive.files.where((f) => f.isFile).toList();
  if (entries.length > maxFiles) {
    throw PackageException(
      'too many files: ${entries.length} (at most $maxFiles)',
    );
  }
  // The sizes the zip declares, checked before decompressing anything.
  final declared = entries.fold<int>(0, (sum, f) => sum + f.size);
  if (declared > maxBytes) throw _tooBig(maxBytes);
  for (final entry in archive.files) {
    _checkPath(entry.name, isLink: entry.isSymbolicLink);
  }

  final sources = <String, String>{};
  final files = <String, Uint8List>{};
  var total = 0;
  for (final entry in entries) {
    final Uint8List data;
    try {
      data = entry.readBytes() ?? Uint8List(0);
    } on Object catch (_) {
      throw PackageException('${entry.name}: cannot be unpacked');
    }
    // shortcut: an entry that lies about its size is only caught after it is
    // decompressed; stream with a cap if packages ever come from a server.
    total += data.length;
    if (total > maxBytes) throw _tooBig(maxBytes);
    if (_storyFile.hasMatch(entry.name)) {
      try {
        sources[entry.name] = utf8.decode(data);
      } on FormatException {
        throw PackageException('${entry.name}: not UTF-8 text');
      }
    } else {
      files[entry.name] = data;
    }
  }
  final stories = _stories(sources);
  return GamePackage(
    id: stories.values.first.id,
    stories: stories,
    sources: sources,
    files: files,
  );
}

/// Packs a game: [files] maps paths inside the package to their bytes. The
/// result is checked with [readPackage], so a package that would be refused
/// is never written.
Uint8List writePackage(Map<String, List<int>> files) {
  final archive = Archive();
  for (final path in files.keys.toList()..sort()) {
    archive.addFile(ArchiveFile.bytes(path, files[path]!));
  }
  final bytes = ZipEncoder().encodeBytes(archive);
  readPackage(bytes);
  return bytes;
}

/// Whether [path] (inside a game folder) belongs in a package: a story file
/// or `builder.json` at the root, or a media file under `images/` or
/// `audio/`. Packers use it to pick files from a folder.
bool belongsInPackage(String path) {
  try {
    _checkPath(path, isLink: false);
    return true;
  } on PackageException {
    return false;
  }
}

void _checkPath(String path, {required bool isLink}) {
  if (isLink) throw PackageException('$path: links are not allowed');
  final parts = path.split('/');
  if (path.contains(r'\') ||
      path.startsWith('/') ||
      parts.any((p) => p == '..' || p == '.')) {
    throw PackageException('$path: not a path inside the game folder');
  }
  if (path.endsWith('/')) return; // a folder entry, nothing to read
  if (parts.length == 1 &&
      (_storyFile.hasMatch(path) || path == 'builder.json')) {
    return;
  }
  final dot = path.lastIndexOf('.');
  final type = dot < 0 ? '' : path.substring(dot).toLowerCase();
  if (parts.length > 1 &&
      (parts.first == 'images' || parts.first == 'audio') &&
      mediaTypes.contains(type) &&
      parts.every((p) => p.isNotEmpty)) {
    return;
  }
  throw PackageException(
    '$path: not allowed (only story.<lang>.json, builder.json and media '
    'files under images/ or audio/)',
  );
}

PackageException _tooBig(int maxBytes) => PackageException(
  'too big: more than ${maxBytes ~/ (1024 * 1024)} MB unpacked',
);

/// Parses and checks the story files: each sound, all one game.
Map<String, Story> _stories(Map<String, String> sources) {
  if (sources.isEmpty) throw const PackageException('no story file');
  final stories = <String, Story>{};
  for (final name in sources.keys.toList()..sort()) {
    final lang = _storyFile.firstMatch(name)!.group(1)!;
    final Story story;
    try {
      story = Story.parse(sources[name]!);
    } on StoryFormatException catch (e) {
      throw PackageException('$name: $e');
    }
    if (story.lang != lang) {
      throw PackageException(
        '$name: lang is "${story.lang}" but the file name says "$lang"',
      );
    }
    // Media may be missing (B14); everything else must be sound.
    final errors = validateStory(story)
        .where((i) => i.severity == Severity.error);
    if (errors.isNotEmpty) throw PackageException('$name: ${errors.first}');
    stories[lang] = story;
  }
  final first = stories.values.first;
  for (final story in stories.values.skip(1)) {
    if (story.id != first.id) {
      throw PackageException(
        'stories have different ids: "${first.id}" and "${story.id}"',
      );
    }
    final differences = compareTranslations(first, story);
    if (differences.isNotEmpty) {
      throw PackageException('translations do not match: ${differences.first}');
    }
  }
  return stories;
}
