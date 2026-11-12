// Immutable view models: what the UI draws, with no engine types leaking
// beyond the few enums the UI needs to pick a style.
import 'package:gamebook_engine/condition.dart' show CompareOp;
import 'package:gamebook_engine/story.dart' show Ending;

export 'package:gamebook_engine/condition.dart' show CompareOp;
export 'package:gamebook_engine/story.dart' show Ending;

/// One page as the player sees it.
class PageView {
  const PageView({
    required this.storyTitle,
    required this.paragraphs,
    required this.choices,
    required this.stats,
    this.title,
    this.image,
    this.ending,
  });

  final String storyTitle;

  /// The page's own title, when the story shows titles.
  final String? title;
  final String? image;
  final List<String> paragraphs;
  final List<ChoiceItem> choices;
  final List<StatPill> stats;

  /// Set when the game is over.
  final Ending? ending;
}

enum ChoiceKind { plain, check, table }

class ChoiceItem {
  const ChoiceItem({
    required this.index,
    required this.text,
    this.kind = ChoiceKind.plain,
    this.locked = false,
    this.lockedText,
    this.needs = const [],
  });

  /// Pass to [PlaySession.choose].
  final int index;
  final String text;
  final ChoiceKind kind;
  final bool locked;

  /// The author's own wording for why it is locked; wins over [needs].
  final String? lockedText;

  /// What is missing, for the UI to word as "Needs: ...".
  final List<Requirement> needs;
}

enum RequirementKind { item, flag, visited, visits, stat }

/// One unmet requirement of a locked choice. [name] is already the display
/// name (item name, stat label); flags and pages fall back to their id.
class Requirement {
  const Requirement(
    this.kind,
    this.name, {
    this.negated = false,
    this.op,
    this.target,
  });

  final RequirementKind kind;
  final String name;

  /// The player must NOT have it.
  final bool negated;

  /// For [RequirementKind.stat] and [RequirementKind.visits].
  final CompareOp? op;
  final int? target;
}

class StatPill {
  const StatPill({
    required this.id,
    required this.label,
    required this.value,
    this.max,
    this.bonus = 0,
  });

  final String id;
  final String label;

  /// The value with item bonuses included.
  final int value;
  final int? max;
  final int bonus;

  /// At or under a quarter of its ceiling: shown as a warning.
  bool get low => max != null && max! > 0 && value * 4 <= max!;
}
