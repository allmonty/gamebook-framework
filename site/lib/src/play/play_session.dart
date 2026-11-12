import 'dart:math';

import 'package:gamebook_engine/engine.dart';
import 'package:gamebook_engine/rules.dart';
import 'package:gamebook_engine/story.dart';

import 'hero_draft.dart';
import 'log.dart';
import 'views.dart';

/// Plays one story: the use cases the UI calls, and the [view] it draws.
class PlaySession {
  PlaySession._(this.story, this.rules, this._random);

  /// Starts a new game. If the story has character creation (a name, picks,
  /// or its own `rerolls`), the session waits in [creation] until
  /// [beginAdventure]; otherwise stats are rolled and the first page shown.
  /// Throws `StoryFormatException` if the rules cannot be resolved.
  factory PlaySession.start(Story story, {required Random random}) {
    final session = PlaySession._(story, Rules.resolve(story.rules), random);
    session.restart();
    return session;
  }

  final Story story;
  final Rules rules;
  final Random _random;
  late GameEngine _engine;

  /// Character creation under way; null once the adventure has begun.
  HeroDraft? creation;
  List<GameEvent> _events = const [];
  String? _music;

  /// Earned in any game since this session began; ids in earning order.
  final Set<String> _achievements = {};

  /// Starts over: character creation again if the story has it, else the
  /// first page with new stats.
  void restart() {
    final draft = HeroDraft(rules, _random);
    if (_hasCreation) {
      creation = draft;
    } else {
      _begin(draft);
    }
  }

  bool get _hasCreation =>
      rules.creation != null || story.rules.rerolls != null;

  /// Starts the adventure from the finished [creation].
  void beginAdventure() {
    final draft = creation ?? (throw StateError('no character creation'));
    if (!draft.ready) throw StateError('character creation is not finished');
    creation = null;
    _begin(draft);
  }

  void _begin(HeroDraft draft) {
    final (engine, events) = GameEngine.newGame(
      story: story,
      rules: rules,
      random: _random,
      stats: draft.stats,
      name: draft.asksName ? draft.name.trim() : null,
      creationEffects: draft.effects,
    );
    _engine = engine;
    _music = null;
    _record(events);
  }

  /// Takes the choice at [index] (a [ChoiceItem.index]).
  void choose(int index) => _record(_engine.choose(index));

  /// Uses a carried item (a [PackItem.usable] one), on a page or in a fight.
  void useItem(String id) => _record(_engine.useItem(id));

  /// Takes the offered item, leaving [replacing] behind when the pack is full.
  void takeOffer({String? replacing}) =>
      _record(_engine.resolveOffer(take: true, replacing: replacing));

  /// Leaves the offered item where it is.
  void leaveOffer() => _record(_engine.resolveOffer(take: false));

  /// Plays a round of the fight; [target] is an [EnemyView.index] when the
  /// fight asks to pick one.
  void fight({int? target}) => _record(_engine.fight(target: target));

  /// Tests luck on the wounds of the last round.
  void testLuck() => _record(_engine.testLuck());

  void flee() => _record(_engine.flee());

  /// Goes back a page (`rules.undo`).
  void undo() => _record(_engine.undo());

  void _record(List<GameEvent> events) {
    _events = events;
    for (final event in events) {
      switch (event) {
        case MusicChanged(:final file):
          _music = file;
        case AchievementEarned(:final achievement):
          _achievements.add(achievement);
        default:
      }
    }
  }

  /// The page now. Only once the adventure has begun ([creation] is null).
  PageView get view {
    if (creation != null) throw StateError('character creation comes first');
    return _view;
  }

  PageView get _view => PageView(
    storyTitle: story.title,
    heading: story.showTitles ? _engine.node.title : story.title,
    image: _engine.node.image,
    paragraphs: _engine.paragraphs,
    // The engine refuses choices during an offer or a fight, so hide them.
    choices: _engine.offer != null || _engine.combat != null
        ? const []
        : [for (final c in _engine.choices) _choice(c)],
    stats: [for (final s in rules.stats) _stat(s)],
    pack: PackView(
      items: [for (final id in _engine.state.inventory) _item(id)],
      used: _engine.slotsUsed,
      capacity: _engine.capacity,
    ),
    offer: _offer(),
    log: logLines(_events, story: story, statLabel: _label),
    journal: [
      for (final id in _engine.state.journal.reversed)
        if (story.journal[id] case final entry?)
          JournalItem(entry.title, entry.text),
    ],
    achievements: [
      for (final id in _achievements) story.achievements[id]?.title ?? id,
    ],
    audio: AudioCue(
      music: _music,
      sounds: [
        for (final e in _events)
          if (e is SoundPlayed) e.file,
      ],
    ),
    canUndo: _engine.canUndo,
    combat: _combat(),
    ending: _engine.ending,
  );

  ChoiceItem _choice(ChoiceView c) => ChoiceItem(
    index: c.index,
    text: c.text,
    kind: c.choice.check != null
        ? ChoiceKind.check
        : c.choice.table != null
        ? ChoiceKind.table
        : ChoiceKind.plain,
    locked: c.locked,
    lockedText: c.locked ? c.choice.lockedText : null,
    needs: [for (final u in c.unmet) _requirement(u)],
  );

  Requirement _requirement(Unmet unmet) => switch (unmet.condition) {
    HasItem(:final item) => Requirement(
      RequirementKind.item,
      story.items[item]?.name ?? item,
      negated: unmet.negated,
    ),
    FlagSet(:final flag) => Requirement(
      RequirementKind.flag,
      flag,
      negated: unmet.negated,
    ),
    Visited(:final node) => Requirement(
      RequirementKind.visited,
      node,
      negated: unmet.negated,
    ),
    VisitCount(:final node, :final op, :final value) => Requirement(
      RequirementKind.visits,
      node,
      negated: unmet.negated,
      op: op,
      target: value,
    ),
    StatCompare(:final stat, :final op) => Requirement(
      RequirementKind.stat,
      _label(stat),
      negated: unmet.negated,
      op: op,
      target: unmet.target,
    ),
    // explain() never returns these: it breaks them into their leaves.
    All() || Any() || Not() => throw StateError('not a leaf condition'),
  };

  StatPill _stat(StatRules rule) {
    final state = _engine.state;
    return StatPill(
      id: rule.id,
      label: rule.label,
      value: state.stat(rule.id),
      max: state.stats[rule.id]?.max,
      bonus: state.bonusOf(rule.id),
    );
  }

  PackItem _item(String id) {
    final item = story.items[id];
    return PackItem(
      id: id,
      name: item?.name ?? id,
      description: item?.description,
      bonus: [
        for (final MapEntry(:key, :value) in (item?.bonus ?? {}).entries)
          (_label(key), value),
      ],
      usable: _engine.canUse(id),
      room: item?.capacity,
    );
  }

  OfferView? _offer() {
    final id = _engine.offer;
    if (id == null) return null;
    return OfferView(
      item: _item(id),
      swapFrom: _engine.canHold(id)
          ? const []
          : [
              for (final carried in _engine.state.inventory)
                if (!_engine.isContainer(carried)) _item(carried),
            ],
      more: _engine.moreOffers,
    );
  }

  CombatView? _combat() {
    final fight = _engine.combat;
    final state = _engine.state.combat;
    if (fight == null || state == null) return null;
    return CombatView(
      enemies: [
        for (var i = 0; i < fight.enemies.length; i++)
          EnemyView(
            index: i,
            name: fight.enemies[i].name,
            health: state.enemyHealth[i],
            maxHealth: fight.enemies[i].health,
            armor: fight.enemies[i].armor,
            current: !fight.simultaneous && state.enemy == i,
          ),
      ],
      pickTarget: fight.simultaneous,
      canFlee: _engine.canFlee,
      canTestLuck: _engine.canTestLuck,
    );
  }

  String _label(String stat) =>
      rules.stats.where((s) => s.id == stat).firstOrNull?.label ?? stat;
}
