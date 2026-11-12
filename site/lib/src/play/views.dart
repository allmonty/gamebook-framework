// Immutable view models: what the UI draws, with no engine types leaking
// beyond the few enums the UI needs to pick a style.
import 'package:gamebook_engine/condition.dart' show CompareOp;
import 'package:gamebook_engine/story.dart' show Ending;

import 'log.dart';

export 'package:gamebook_engine/condition.dart' show CompareOp;
export 'package:gamebook_engine/story.dart' show Ending;

export 'log.dart' show LogLine, Tone;

/// One page as the player sees it.
class PageView {
  const PageView({
    required this.storyTitle,
    required this.paragraphs,
    required this.choices,
    required this.stats,
    required this.pack,
    this.log = const [],
    this.journal = const [],
    this.achievements = const [],
    this.audio = const AudioCue(),
    this.canUndo = false,
    this.combat,
    this.offer,
    this.heading,
    this.image,
    this.ending,
  });

  final String storyTitle;

  /// The heading above the page: the story's title, or with `showTitles` the
  /// page's own title (none when the page has no title, spec B13).
  final String? heading;
  final String? image;
  final List<String> paragraphs;
  final List<ChoiceItem> choices;
  final List<StatPill> stats;
  final PackView pack;

  /// What the last action did: rolls, wounds, items, stats.
  final List<LogLine> log;

  /// Unlocked journal entries, newest first.
  final List<JournalItem> journal;

  /// Achievements earned this visit, in story order.
  final List<String> achievements;
  final AudioCue audio;
  final bool canUndo;

  /// The fight under way on this page, if any.
  final CombatView? combat;

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

class JournalItem {
  const JournalItem(this.title, this.text);
  final String title;
  final String text;
}

/// What to play: the page's music (null is silence) and the sounds the last
/// action triggered. Paths are as the story wrote them.
class AudioCue {
  const AudioCue({this.music, this.sounds = const []});
  final String? music;
  final List<String> sounds;
}

class CombatView {
  const CombatView({
    required this.enemies,
    this.pickTarget = false,
    this.canFlee = false,
    this.canTestLuck = false,
  });

  final List<EnemyView> enemies;

  /// Several enemies at once: the player picks whom to attack.
  final bool pickTarget;
  final bool canFlee;
  final bool canTestLuck;
}

class EnemyView {
  const EnemyView({
    required this.index,
    required this.name,
    required this.health,
    required this.maxHealth,
    this.armor = 0,
    this.current = false,
  });

  /// Pass to [PlaySession.fight] as the target.
  final int index;
  final String name;
  final int health;
  final int maxHealth;
  final int armor;

  /// The one being fought now (one-at-a-time fights).
  final bool current;

  bool get alive => health > 0;
}

/// The character creation screen.
class CreationView {
  const CreationView({
    required this.stats,
    required this.rerollsLeft,
    required this.asksName,
    required this.name,
    required this.groups,
    required this.ready,
  });

  final List<StatPill> stats;
  final int rerollsLeft;
  final bool asksName;
  final String name;
  final List<PickGroupView> groups;

  /// Everything required is filled in: the adventure can begin.
  final bool ready;
}

class PickGroupView {
  const PickGroupView({
    required this.id,
    required this.title,
    required this.count,
    required this.options,
  });

  final String id;
  final String title;

  /// How many options must be picked.
  final int count;
  final List<PickOptionView> options;

  int get picked => options.where((o) => o.picked).length;
}

class PickOptionView {
  const PickOptionView({
    required this.id,
    required this.label,
    required this.picked,
    this.description,
  });

  final String id;
  final String label;
  final String? description;
  final bool picked;
}
