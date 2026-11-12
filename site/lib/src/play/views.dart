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
    required this.pack,
    this.offer,
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
  final PackView pack;

  /// An item found that the player must take or leave before going on.
  final OfferView? offer;

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

/// What the player carries.
class PackView {
  const PackView({required this.items, required this.used, this.capacity});

  final List<PackItem> items;

  /// Slots in use (containers use none) and how many there are; null
  /// [capacity] is an unlimited pack.
  final int used;
  final int? capacity;

  bool get full => capacity != null && used >= capacity!;
}

class PackItem {
  const PackItem({
    required this.id,
    required this.name,
    this.description,
    this.bonus = const [],
    this.usable = false,
    this.room,
  });

  /// Pass to [PlaySession.useItem] or as the item to leave behind.
  final String id;
  final String name;
  final String? description;

  /// Stat changes while carried, as (stat label, amount).
  final List<(String, int)> bonus;

  /// Whether it can be used here and now.
  final bool usable;

  /// Extra slots it gives: set only for a container.
  final int? room;
}

/// An item waiting for the player's decision (`pickup: "choose"`).
class OfferView {
  const OfferView({required this.item, required this.swapFrom, this.more = 0});

  final PackItem item;

  /// Items the player may leave behind to make room; empty when it fits.
  final List<PackItem> swapFrom;

  /// More offers waiting after this one.
  final int more;

  bool get needsSwap => swapFrom.isNotEmpty;
}
