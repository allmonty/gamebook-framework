/// A malformed story, with the JSON path of the problem.
class StoryFormatException implements Exception {
  const StoryFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => path.isEmpty ? message : '$path: $message';
}

final _idPattern = RegExp(r'^[A-Za-z0-9_-]+$');

String joinPath(String base, String key) => base.isEmpty ? key : '$base.$key';

/// Strict view of a JSON object: every key must be read or [finish] throws,
/// so a typo in a story is an error instead of silently ignored.
class JsonObject {
  JsonObject(Object? json, this.path) : _map = _asMap(json, path);

  final Map<String, Object?> _map;
  final String path;
  final Set<String> _read = {};

  static Map<String, Object?> _asMap(Object? json, String path) {
    if (json is Map<String, Object?>) return json;
    throw StoryFormatException(path, 'expected an object');
  }

  bool has(String key) => _map.containsKey(key);

  String childPath(String key) => joinPath(path, key);

  StoryFormatException error(String key, String message) =>
      StoryFormatException(childPath(key), message);

  Object? _take(String key) {
    _read.add(key);
    return _map[key];
  }

  T _typed<T>(String key, String what) {
    final value = _take(key);
    if (value is T) return value;
    throw error(key, has(key) ? 'expected $what' : 'missing');
  }

  String string(String key) => _typed<String>(key, 'a string');

  String? optString(String key) => has(key) ? string(key) : null;

  int integer(String key) => _typed<int>(key, 'an integer');

  int? optInt(String key) => has(key) ? integer(key) : null;

  bool optBool(String key, {bool fallback = false}) =>
      has(key) ? _typed<bool>(key, 'true or false') : fallback;

  /// The raw value of [key], for callers that accept several types.
  Object? raw(String key) => _take(key);

  JsonObject object(String key) {
    _take(key);
    if (!has(key)) throw error(key, 'missing');
    return JsonObject(_map[key], childPath(key));
  }

  JsonObject? optObject(String key) => has(key) ? object(key) : null;

  List<T> list<T>(
    String key,
    T Function(Object? json, String path) parse, {
    bool optional = false,
  }) {
    if (!has(key)) {
      if (optional) return const [];
      throw error(key, 'missing');
    }
    final value = _take(key);
    if (value is! List<Object?>) throw error(key, 'expected a list');
    return [
      for (var i = 0; i < value.length; i++)
        parse(value[i], '${childPath(key)}[$i]'),
    ];
  }

  /// An object whose keys are ids, kept in file order.
  Map<String, T> idMap<T>(
    String key,
    T Function(String id, Object? json, String path) parse, {
    bool optional = false,
  }) {
    if (!has(key)) {
      if (optional) return const {};
      throw error(key, 'missing');
    }
    final value = _take(key);
    if (value is! Map<String, Object?>) throw error(key, 'expected an object');
    return {
      for (final entry in value.entries)
        entry.key: parse(
          checkId(entry.key, childPath(key)),
          entry.value,
          joinPath(childPath(key), entry.key),
        ),
    };
  }

  /// Throws on any key that was not read.
  void finish() {
    for (final key in _map.keys) {
      if (!_read.contains(key)) throw error(key, 'unknown key');
    }
  }
}

/// Ids of nodes, items, stats and flags.
String checkId(String id, String path) {
  if (!_idPattern.hasMatch(id)) {
    throw StoryFormatException(
      path,
      'invalid id "$id" (use letters, digits, "_" and "-")',
    );
  }
  return id;
}
