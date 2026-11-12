// Pure text formatting for the player; no DOM, so it is tested on the VM.
import '../play/views.dart';

/// The `player.*` strings of the page's language, with `{name}` arguments.
class Messages {
  const Messages(this._strings);

  final Map<String, String> _strings;

  /// The string [key] with each `{arg}` replaced. A missing key shows the key
  /// itself, so a gap is visible without breaking the game.
  String call(String key, [Map<String, Object> args = const {}]) {
    var text = _strings[key] ?? key;
    for (final MapEntry(:key, :value) in args.entries) {
      text = text.replaceAll('{$key}', '$value');
    }
    return text;
  }
}

/// Why a locked choice cannot be taken: the author's words, or "Needs: ...".
String lockedReason(ChoiceItem choice, Messages m) {
  if (choice.lockedText case final text?) return text;
  if (choice.needs.isEmpty) return m('player.locked');
  return m('player.needs', {
    'list': choice.needs.map((r) => requirementText(r, m)).join(', '),
  });
}

String requirementText(Requirement r, Messages m) {
  final what = switch (r.kind) {
    RequirementKind.item || RequirementKind.flag => r.name,
    RequirementKind.visited => m('player.visited', {'name': r.name}),
    RequirementKind.visits => m('player.visits', {
      'name': r.name,
      'op': _symbol(r.op!),
      'target': r.target!,
    }),
    RequirementKind.stat => '${r.name} ${_symbol(r.op!)} ${r.target}',
  };
  return r.negated ? m('player.not', {'what': what}) : what;
}

String _symbol(CompareOp op) => switch (op) {
  CompareOp.gte => '≥',
  CompareOp.lte => '≤',
  CompareOp.eq => '=',
};

/// The `[01] //` index before a choice.
String choiceIndex(int position) =>
    '[${(position + 1).toString().padLeft(2, '0')}] //';

/// A log line in words: the string `player.log.<key>` with its arguments.
String logText(LogLine line, Messages m) =>
    m('player.log.${line.key}', line.args);
