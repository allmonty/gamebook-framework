import 'dice.dart';
import 'story.dart';

/// What kind of exit a link is; tools draw each kind its own way.
enum EdgeKind {
  /// A choice that always leads there.
  plain,

  /// A choice with a condition (`if`).
  locked,

  /// A dice check passed / failed.
  pass,
  fail,

  /// One row of a random table.
  outcome,

  /// A fight won / fled.
  win,
  flee,
}

/// One link from a page to another: an exit of a choice (a check has two, a
/// table one per outcome) or of a fight.
class StoryEdge {
  const StoryEdge(
    this.from,
    this.to,
    this.label,
    this.kind, {
    this.choice,
    this.port = 0,
  });

  final String from;
  final String to;

  /// What the graph tool writes on the link.
  final String label;
  final EdgeKind kind;

  /// The position of the choice in the page's `choices`, or null for a
  /// fight's exits.
  final int? choice;

  /// Which exit of its choice or fight this is: 0, or 1 for a failed check
  /// or for fleeing, or the outcome's position in a table.
  final int port;
}

/// One-line summary of a condition, for edge labels.
String describeCondition(Condition condition) => switch (condition) {
  HasItem(:final item) => 'has $item',
  FlagSet(:final flag) => 'flag $flag',
  Visited(:final node) => 'visited $node',
  VisitCount(:final node, :final op, :final value) =>
    'visits $node ${switch (op) {
      CompareOp.gte => '>=',
      CompareOp.lte => '<=',
      CompareOp.eq => '==',
    }} $value',
  StatCompare(:final stat, :final op, :final value) =>
    '$stat ${switch (op) {
      CompareOp.gte => '>=',
      CompareOp.lte => '<=',
      CompareOp.eq => '==',
    }} $value',
  All(:final conditions) => conditions.map(describeCondition).join(' and '),
  Any(:final conditions) =>
    '(${conditions.map(describeCondition).join(' or ')})',
  Not(:final condition) => 'not ${describeCondition(condition)}',
};

String _operand(Operand? operand) => switch (operand) {
  null => '',
  Const(:final value) => '$value',
  StatRef(:final stat) => stat,
};

/// Every link of [story], page by page in file order.
List<StoryEdge> storyEdges(Story story) => [
  for (final MapEntry(:key, :value) in story.nodes.entries) ...[
    for (var i = 0; i < value.choices.length; i++)
      ..._choiceEdges(key, i, value.choices[i]),
    if (value.combat case final combat?) ...[
      StoryEdge(key, combat.win, 'win', EdgeKind.win),
      if (combat.flee case final flee?)
        StoryEdge(key, flee, 'flee', EdgeKind.flee, port: 1),
    ],
  ],
];

List<StoryEdge> _choiceEdges(String from, int index, Choice choice) {
  final text = choice.once ? '${choice.text} (once)' : choice.text;
  final gate = choice.condition == null
      ? ''
      : '\n[${describeCondition(choice.condition!)}]';
  if (choice.check case final check?) {
    final roll =
        '${check.roll}${check.add == null ? '' : '+${_operand(check.add)}'} '
        '${check.op == CheckOp.gte ? '>=' : '<='} ${_operand(check.vs)}';
    return [
      StoryEdge(
        from,
        check.pass,
        '$text$gate\npass: $roll',
        EdgeKind.pass,
        choice: index,
      ),
      StoryEdge(
        from,
        check.fail,
        '$text\nfail',
        EdgeKind.fail,
        choice: index,
        port: 1,
      ),
    ];
  }
  if (choice.table case final table?) {
    final min = Dice.parse(table.roll).min;
    var low = min;
    return [
      for (final (j, o) in table.outcomes.indexed)
        () {
          final range = low >= o.upTo ? '${o.upTo}' : '$low-${o.upTo}';
          low = o.upTo + 1;
          return StoryEdge(
            from,
            o.to,
            '$text$gate\nroll ${table.roll}: $range',
            EdgeKind.outcome,
            choice: index,
            port: j,
          );
        }(),
    ];
  }
  return [
    StoryEdge(
      from,
      choice.to!,
      '$text$gate',
      choice.condition == null ? EdgeKind.plain : EdgeKind.locked,
      choice: index,
    ),
  ];
}

String _excerpt(String text) {
  final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return line.length <= 40 ? line : '${line.substring(0, 39)}…';
}

String _nodeLabel(Node node) => [
  node.title == null ? node.id : '${node.title} [${node.id}]',
  _excerpt(node.text),
].join('\n');

/// The ids of the nodes in each chapter, in the order of `chapters`.
Iterable<(String, Chapter, List<String>)> _chapters(Story story) => [
  for (final MapEntry(:key, :value) in story.chapters.entries)
    (
      key,
      value,
      [
        for (final node in story.nodes.values)
          if (node.chapter == key) node.id,
      ],
    ),
];

String _dotEscape(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

/// The story as a Graphviz graph: render with `dot -Tsvg`. Dashed edges are
/// gated by a condition, checks split into green (pass) and red (fail) edges,
/// fights are red boxes and endings are green (victory), amber (defeat) or
/// grey (death).
/// Chapters (schema 6) are drawn as labelled clusters.
String toDot(Story story) {
  final out = StringBuffer()
    ..writeln('digraph "${_dotEscape(story.id)}" {')
    ..writeln('  rankdir=TB;')
    ..writeln('  node [shape=box, style=rounded, fontname="Helvetica"];')
    ..writeln('  edge [fontname="Helvetica", fontsize=10];');
  for (final node in story.nodes.values) {
    final attrs = [
      'label="${_dotEscape(_nodeLabel(node))}"',
      if (node.id == story.start) 'penwidth=3',
      if (node.draft) 'style="rounded,dashed"',
      if (node.combat != null) 'style="rounded,filled", fillcolor="#f4c7c3"',
      if (node.ending == Ending.victory)
        'style="rounded,filled", fillcolor="#c8e6c9"',
      if (node.ending == Ending.defeat)
        'style="rounded,filled", fillcolor="#ffe0b2"',
      if (node.ending == Ending.death)
        'style="rounded,filled", fillcolor="#cccccc"',
    ];
    out.writeln('  "${_dotEscape(node.id)}" [${attrs.join(', ')}];');
  }
  for (final (id, chapter, nodes) in _chapters(story)) {
    out
      ..writeln('  subgraph "cluster_${_dotEscape(id)}" {')
      ..writeln('    label="${_dotEscape(chapter.title)}";');
    for (final node in nodes) {
      out.writeln('    "${_dotEscape(node)}";');
    }
    out.writeln('  }');
  }
  for (final e in storyEdges(story)) {
    final attrs = [
      'label="${_dotEscape(e.label)}"',
      switch (e.kind) {
        EdgeKind.plain || EdgeKind.outcome => null,
        EdgeKind.locked || EdgeKind.flee => 'style=dashed',
        EdgeKind.pass || EdgeKind.win => 'color="#2e7d32"',
        EdgeKind.fail => 'color="#c62828"',
      },
    ].nonNulls;
    out.writeln(
      '  "${_dotEscape(e.from)}" -> "${_dotEscape(e.to)}" [${attrs.join(', ')}];',
    );
  }
  return (out..writeln('}')).toString();
}

String _mermaidEscape(String s) =>
    s.replaceAll('"', '#quot;').replaceAll('\n', '<br/>');

// Prefixed so ids such as "end" never collide with Mermaid keywords.
String _mermaidId(String id) => 'n_${id.replaceAll('-', '_')}';

/// The story as a Mermaid flowchart (paste into any Mermaid viewer or a
/// GitHub markdown ```mermaid block).
String toMermaid(Story story) {
  final out = StringBuffer('flowchart TD\n');
  for (final node in story.nodes.values) {
    final label = _mermaidEscape(_nodeLabel(node));
    final id = _mermaidId(node.id);
    out.writeln(
      node.combat != null
          ? '  $id{{"$label"}}'
          : node.ending != null
          ? '  $id(["$label"])'
          : '  $id["$label"]',
    );
  }
  for (final (id, chapter, nodes) in _chapters(story)) {
    out.writeln(
      '  subgraph c_${id.replaceAll('-', '_')} ["${_mermaidEscape(chapter.title)}"]',
    );
    for (final node in nodes) {
      out.writeln('    ${_mermaidId(node)}');
    }
    out.writeln('  end');
  }
  for (final e in storyEdges(story)) {
    final label = '"${_mermaidEscape(e.label)}"';
    final arrow = switch (e.kind) {
      EdgeKind.locked || EdgeKind.flee => '-.->|$label|',
      _ => '-->|$label|',
    };
    out.writeln('  ${_mermaidId(e.from)} $arrow ${_mermaidId(e.to)}');
  }
  return out.toString();
}
