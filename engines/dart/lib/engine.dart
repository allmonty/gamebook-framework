import 'dart:math';

import 'check.dart';
import 'combat.dart';
import 'dice.dart';
import 'rules.dart';
import 'state.dart';
import 'story.dart';
import 'text.dart';

/// What happened as the result of one player action, in order. The engine
/// never plays sounds or animations; the UI decides how to show these.
sealed class GameEvent {
  const GameEvent();
}

class NodeEntered extends GameEvent {
  const NodeEntered(this.node);
  final String node;
}

class CheckRolled extends GameEvent {
  const CheckRolled(this.result);
  final CheckResult result;
}

class CombatRound extends GameEvent {
  const CombatRound(this.result);
  final RoundResult result;
}

/// A random outcome table was rolled.
class TableRolled extends GameEvent {
  const TableRolled(this.roll);
  final DiceRoll roll;
}

/// The player used [item]; its effects show up as the changes that follow.
class ItemUsed extends GameEvent {
  const ItemUsed(this.item);
  final String item;
}

/// The music changed to [file], or stopped when null.
class MusicChanged extends GameEvent {
  const MusicChanged(this.file);
  final String? file;
}

class SoundPlayed extends GameEvent {
  const SoundPlayed(this.file);
  final String file;
}

/// An achievement was earned (schema 7); the app keeps it for the player.
class AchievementEarned extends GameEvent {
  const AchievementEarned(this.achievement);
  final String achievement;
}

class JournalUnlocked extends GameEvent {
  const JournalUnlocked(this.entry);
  final String entry;
}

class CombatGroupRound extends GameEvent {
  const CombatGroupRound(this.result);
  final GroupRoundResult result;
}

class CombatLuck extends GameEvent {
  const CombatLuck(this.result);
  final LuckResult result;
}

/// The enemy struck while the player used an item that costs the round.
class CombatStrike extends GameEvent {
  const CombatStrike(this.result);
  final StrikeResult result;
}

/// The player chose to leave an offered item where it was.
class OfferDeclined extends GameEvent {
  const OfferDeclined(this.item);
  final String item;
}

/// [count] of an item could not be picked up because the pack is full
/// (`pickup: "auto"` with a capacity, or what did not fit of an offer).
class ItemRefused extends GameEvent {
  const ItemRefused(this.item, [this.count = 1]);
  final String item;
  final int count;
}

/// [count] of an item were lost because the pack shrank (a container was
/// taken away).
class ItemOverflow extends GameEvent {
  const ItemOverflow(this.item, [this.count = 1]);
  final String item;
  final int count;
}

/// The pack has an item it did not have: [count] of it.
class ItemGained extends GameEvent {
  const ItemGained(this.item, [this.count = 1]);
  final String item;
  final int count;
}

/// How many of a countable item the pack holds changed, and some are left
/// (schema 8).
class ItemCountChanged extends GameEvent {
  const ItemCountChanged(this.item, this.from, this.to);
  final String item;
  final int from;
  final int to;
}

class ItemLost extends GameEvent {
  const ItemLost(this.item);
  final String item;
}

class StatChanged extends GameEvent {
  const StatChanged(this.stat, this.from, this.to);
  final String stat;
  final int from;
  final int to;
}

class Ended extends GameEvent {
  const Ended(this.ending);
  final Ending ending;
}

/// A choice as the player sees it.
class ChoiceView {
  ChoiceView({
    required this.index,
    required this.choice,
    this.unmet = const [],
    String? text,
    bool? locked,
  }) : text = text ?? choice.text,
       locked = locked ?? unmet.isNotEmpty;

  /// Position in the node's `choices`; pass it to [GameEngine.choose].
  final int index;
  final Choice choice;

  /// The choice text with `{stat}` placeholders filled in.
  final String text;

  /// Why the choice is locked: the requirements not met. Empty when it can be
  /// chosen, and also for a condition that fails with nothing to name (an
  /// empty `any`).
  final List<Unmet> unmet;

  /// Whether the choice's condition fails, so it cannot be chosen.
  final bool locked;
}

/// Plays one story. Pure Dart; randomness comes from [random]. The order in
/// which things happen is spec/framework.md B10.
class GameEngine {
  GameEngine({
    required this.story,
    required this.rules,
    required this.random,
    required GameState state,
  }) {
    _state = state;
  }

  /// Starts a new game with freshly rolled [stats] and enters the first node.
  static (GameEngine, List<GameEvent>) newGame({
    required Story story,
    required Rules rules,
    required Random random,
    required Map<String, StatValue> stats,
    String? name,
    List<Effect> creationEffects = const [],
  }) {
    final engine = GameEngine(
      story: story,
      rules: rules,
      random: random,
      state: GameState(node: story.start, stats: stats, name: name),
    );
    return (
      engine,
      engine._run((events) {
        engine._applyCreation(creationEffects, events);
        engine._enter(story.start, events);
      }),
    );
  }

  /// The effects of what the player picked at character creation. A `give`
  /// here adds the item directly (it was chosen, so it is never an offer);
  /// a pack that is too small drops the newest items as usual.
  void _applyCreation(List<Effect> effects, List<GameEvent> events) {
    for (final effect in effects) {
      if (_dead) break;
      if (effect is Achieve) events.add(AchievementEarned(effect.achievement));
      _state = effect is GiveItem
          ? withCount(
              _state,
              effect.item,
              _stack(effect.item) == null
                  ? 1
                  : min(
                      _state.count(effect.item) + effect.amount,
                      story.items[effect.item]?.max ?? _unlimited,
                    ),
            )
          : applyEffect(effect, _state);
    }
    _enforceCapacity(events);
  }

  final Story story;
  final Rules rules;
  final Random random;
  late GameState _stateValue;

  /// The game as it is, with the stat bonuses of the items in the pack.
  GameState get state => _stateValue;

  GameState get _state => _stateValue;

  /// Every change of the state recomputes the bonuses, so nothing can read a
  /// stale one.
  set _state(GameState next) => _stateValue = next.withBonus(_bonusOf(next));

  Map<String, int> _bonusOf(GameState s) {
    final bonus = <String, int>{};
    void add(Map<String, int> more) {
      for (final MapEntry(:key, :value) in more.entries) {
        bonus[key] = (bonus[key] ?? 0) + value;
      }
    }

    for (final item in s.inventory) {
      add(story.items[item]?.bonus ?? const {});
    }
    // Rule bonuses see the item bonuses only, so none can switch itself on or
    // off (B5).
    final withItems = s.withBonus({...bonus});
    for (final rule in story.rules.bonuses) {
      if (evaluate(rule.condition, withItems)) add(rule.bonus);
    }
    return bonus;
  }

  Node get node => story.nodes[_state.node]!;

  /// Health at 0 is final: no effect applies after it (B4).
  bool get _dead => (_state.stats[rules.health]?.value ?? 0) <= 0;

  /// Set once the player has died (health at 0) or reached an ending node.
  Ending? get ending => _dead
      ? Ending.death
      : node.draft
      ? null
      : node.ending;

  /// The paragraphs of the current page: the parts whose condition holds, with
  /// `{stat}` placeholders filled in, split on blank lines.
  List<String> get paragraphs => [
    for (final part in node.parts)
      if (part.condition == null || evaluate(part.condition!, _state))
        ..._render(part.text).split('\n\n'),
  ];

  /// `{stat}` and `{stat.max}` become the current value or ceiling of the
  /// stat (schema 4 only; older stories keep braces as they are). A name that
  /// is not a stat is left as written.
  String _render(String text) {
    if (story.schema < 4) return text;
    return renderTemplate(text, (name) {
      if (name == 'name') {
        return (rules.creation?.name ?? false) ? _state.name : null;
      }
      if (name.endsWith('.count')) {
        final item = name.substring(0, name.length - '.count'.length);
        return story.items.containsKey(item) ? '${_state.count(item)}' : null;
      }
      final isMax = name.endsWith('.max');
      final stat = isMax ? name.substring(0, name.length - 4) : name;
      final value = _state.stats[stat];
      if (value == null) return null;
      return '${isMax ? (value.max ?? value.value) : _state.stat(stat)}';
    });
  }

  /// The choices to show: locked ones included unless `hideIfLocked`, and
  /// once-only choices already taken left out.
  List<ChoiceView> get choices {
    if (ending != null || node.draft) return const [];
    final shown = <ChoiceView>[];
    for (var i = 0; i < node.choices.length; i++) {
      if (_isTaken(i)) continue;
      final view = _view(i);
      if (!(view.locked && view.choice.hideIfLocked)) shown.add(view);
    }
    return shown;
  }

  bool _isTaken(int index) =>
      node.choices[index].once && _state.taken.contains('${node.id}#$index');

  ChoiceView _view(int index) {
    final choice = node.choices[index];
    return ChoiceView(
      index: index,
      choice: choice,
      text: _render(choice.text),
      unmet: choice.condition == null
          ? const []
          : explain(choice.condition!, _state),
      locked: choice.condition != null && !evaluate(choice.condition!, _state),
    );
  }

  /// The fight on this page, if one is under way.
  Combat? get combat =>
      ending == null && _state.combat != null ? node.combat : null;

  bool get canFlee => combat?.flee != null;

  bool isContainer(String item) => story.items[item]?.capacity != null;

  /// How many items fit now: the story's capacity plus every carried
  /// container's room. Null when the pack is unlimited.
  int? get capacity {
    final base = rules.inventory.capacity;
    if (base == null) return null;
    return _state.inventory.fold<int>(
      base,
      (sum, item) => sum + (story.items[item]?.capacity ?? 0),
    );
  }

  /// Slots in use: one per carried item, and for a countable item one per
  /// `stack` (schema 8); containers use none.
  int get slotsUsed => _state.inventory.fold(
    0,
    (sum, item) => sum + _slots(item, _state.count(item)),
  );

  int? _stack(String item) => story.items[item]?.stack;

  /// The slots [count] of [item] fill.
  int _slots(String item, int count) {
    if (isContainer(item)) return 0;
    final stack = _stack(item);
    return stack == null ? 1 : (count + stack - 1) ~/ stack;
  }

  /// Room left in the part-filled slot of a countable [item] (0 if none).
  int _slotRoom(String item) {
    final stack = _stack(item);
    final rest = stack == null ? 0 : _state.count(item) % stack;
    return rest == 0 ? 0 : stack! - rest;
  }

  /// How many more of [item] fit in the pack now: the room left in its
  /// part-filled slot, then the free slots.
  int _packRoom(String item) {
    if (isContainer(item) || capacity == null) return _unlimited;
    final free = max(0, capacity! - slotsUsed);
    final stack = _stack(item);
    return stack == null ? min(free, 1) : _slotRoom(item) + free * stack;
  }

  /// How many more of [item] its cap allows (schema 8: an item's `max`).
  int _capLeft(String item) {
    final cap = story.items[item]?.max;
    return cap == null ? _unlimited : max(0, cap - _state.count(item));
  }

  /// How many more of [item] can be added now.
  int _room(String item) => min(_packRoom(item), _capLeft(item));

  static const _unlimited = 1 << 30;

  /// Whether one more of [item] can be added to the pack right now (a
  /// container always can: it uses no slot).
  bool canHold(String item) => _room(item) > 0;

  /// The item the player is deciding about, if any (`pickup: "choose"`).
  String? get offer => _state.offers.firstOrNull;

  /// How many of [offer] are offered at once (schema 8: a countable item).
  int get offerCount => offer == null ? 0 : _state.offered(offer!);

  /// Whether taking [offer] needs a carried item left behind: the pack is
  /// full, and the item's cap would still let some in.
  bool get offerNeedsRoom {
    final item = offer;
    return item != null && _packRoom(item) == 0 && _capLeft(item) > 0;
  }

  /// More items waiting behind [offer].
  int get moreOffers => offer == null ? 0 : _state.offers.length - 1;

  /// Takes the choice at [index] of [node].
  List<GameEvent> choose(int index) {
    if (node.draft && ending == null) {
      throw StateError('the page is not written yet');
    }
    _requireNoFightOrEnd();
    if (index < 0 || index >= node.choices.length) {
      throw RangeError.index(index, node.choices, 'index');
    }
    if (_isTaken(index)) throw StateError('choice $index was already taken');
    if (_view(index).locked) throw StateError('choice $index is locked');
    final choice = node.choices[index];
    _remember();
    return _run((events) {
      if (choice.once) {
        _state = _state.copyWith(taken: {..._state.taken, '${node.id}#$index'});
      }
      _applyEffects(choice.effects, events);
      var target = choice.to;
      if (choice.check case final check?) {
        final result = resolveCheck(check, _state, random);
        _applyEffects(check.effects, events);
        events.add(CheckRolled(result));
        target = result.passed ? check.pass : check.fail;
      }
      if (choice.table case final table?) {
        final roll = Dice.parse(table.roll).roll(random);
        final outcome = table.outcomeFor(roll.total);
        _applyEffects(outcome.effects, events);
        events.add(TableRolled(roll));
        target = outcome.to;
      }
      _enter(target!, events);
    });
  }

  /// The states before the last choices, oldest first. In memory only: a
  /// resumed game starts with none.
  final List<GameState> _history = [];

  void _remember() {
    if (rules.undo == 0) return;
    _history.add(_state);
    if (_history.length > rules.undo) _history.removeAt(0);
  }

  /// Whether the player can go back a page (`rules.undo`, schema 5).
  bool get canUndo => _history.isNotEmpty;

  /// Goes back to the state before the last choice. Dice are not remembered:
  /// choosing again rolls again.
  List<GameEvent> undo() {
    if (_history.isEmpty) throw StateError('nothing to undo');
    _state = _history.removeLast();
    return [NodeEntered(_state.node)];
  }

  /// Plays one round of the fight on this page. Against several enemies at
  /// once ([Combat.simultaneous]) [target] is the index of the one to attack.
  List<GameEvent> fight({int? target}) {
    final fightNode = combat;
    if (fightNode == null) throw StateError('no fight under way');
    _requireNoOffer();
    if (fightNode.simultaneous) {
      if (target == null ||
          target < 0 ||
          target >= fightNode.enemies.length ||
          _state.combat!.enemyHealth[target] == 0) {
        throw StateError('pick a living enemy to attack');
      }
      return _run((events) {
        final healthBefore = _health;
        final round = groupRound(
          rules: rules,
          combat: fightNode,
          state: _state,
          random: random,
          target: target,
        );
        _state = round.state;
        events.add(CombatGroupRound(round));
        _afterRound(fightNode, round.outcome, healthBefore, events);
      });
    }
    return _run((events) {
      final healthBefore = _health;
      final round = fightRound(
        rules: rules,
        combat: fightNode,
        state: _state,
        random: random,
      );
      _state = round.state;
      events.add(CombatRound(round));
      _afterRound(fightNode, round.outcome, healthBefore, events);
    });
  }

  int get _health => _state.stats[rules.health]!.value;

  /// What ends a fight after a round, in this order (B11): death (the game
  /// ends by itself), the win, then the fight events of schema 8: a wound,
  /// then too many rounds.
  void _afterRound(
    Combat fightNode,
    CombatOutcome outcome,
    int healthBefore,
    List<GameEvent> events,
  ) {
    if (ending != null) return;
    if (outcome == CombatOutcome.won) return _enter(fightNode.win, events);
    final fight = _state.combat!;
    final round = fight.round + 1;
    _state = _state.withCombat(
      CombatState(fight.enemy, fight.enemyHealth, fight.luck, round),
    );
    if (fightNode.wounded case final page? when _health < healthBefore) {
      return _enter(page, events);
    }
    if (fightNode.rounds case final limit? when round >= limit.after) {
      _enter(limit.to, events);
    }
  }

  /// Whether the player may test luck on the last round of the fight.
  bool get canTestLuck => combat != null && _state.combat!.luck != null;

  /// Tests luck on the wounds of the last round of the fight.
  List<GameEvent> testLuck() {
    final fightNode = combat;
    if (fightNode == null || !canTestLuck) {
      throw StateError('luck cannot be tested now');
    }
    _requireNoOffer();
    return _run((events) {
      final result = testFightLuck(
        rules: rules,
        combat: fightNode,
        state: _state,
        random: random,
      );
      _state = result.state;
      events.add(CombatLuck(result));
      if (result.outcome == CombatOutcome.won) _enter(fightNode.win, events);
    });
  }

  /// Whether [item] can be used right now: held, usable, the game is not
  /// over, and it works where the player is (in a fight or on a page).
  bool canUse(String item) {
    final use = story.items[item]?.use;
    if (use == null || ending != null || !_state.inventory.contains(item)) {
      return false;
    }
    return use.when.contains(combat == null ? UseWhen.story : UseWhen.combat);
  }

  /// Uses [item]: it is removed from the pack and its effects apply. In a
  /// fight, an item that costs the round also lets the enemy strike.
  List<GameEvent> useItem(String item) {
    if (!canUse(item)) throw StateError('"$item" cannot be used now');
    final use = story.items[item]!.use!;
    final fightNode = combat;
    final events = _run((events) {
      events.add(ItemUsed(item));
      // A countable item spends one; the last one leaves the pack.
      _state = withCount(_state, item, _state.count(item) - 1);
      _applyEffects(use.effects, events);
      if (fightNode != null &&
          use.combatCost == CombatCost.round &&
          ending == null) {
        final healthBefore = _health;
        _strikes(fightNode, events);
        // It costs the round: it counts as one, and a strike as a wound.
        _afterRound(fightNode, CombatOutcome.ongoing, healthBefore, events);
      }
    });
    // Using an item spends it; "ItemUsed" already says so.
    return events..removeWhere((e) => e is ItemLost && e.item == item);
  }

  /// Runs away from the fight, to the page the story names.
  List<GameEvent> flee() {
    final fightNode = combat;
    final target = fightNode?.flee;
    if (target == null) throw StateError('cannot flee');
    _requireNoOffer();
    return _run((events) {
      // Running costs the round (schema 8): the enemies strike first. It is
      // no wound for `wounded`, nor a round for `rounds`: the player left.
      if (fightNode!.fleeCost == CombatCost.round) _strikes(fightNode, events);
      if (ending == null) _enter(target, events);
    });
  }

  /// The enemies strike while the player does something else (B5): the
  /// current enemy, or every one still standing in a fight against several.
  void _strikes(Combat fightNode, List<GameEvent> events) {
    final strikers = fightNode.simultaneous
        ? [
            for (var i = 0; i < fightNode.enemies.length; i++)
              if (_state.combat!.enemyHealth[i] > 0) i,
          ]
        : [_state.combat!.enemy];
    for (final i in strikers) {
      if (ending != null) break;
      final strike = enemyStrike(
        rules: rules,
        combat: fightNode,
        state: _state,
        random: random,
        enemyIndex: i,
      );
      _state = strike.state;
      events.add(CombatStrike(strike));
    }
  }

  void _requireNoFightOrEnd() {
    if (ending != null) throw StateError('the game has ended');
    if (node.combat != null) throw StateError('there is a fight to finish');
    _requireNoOffer();
  }

  void _requireNoOffer() {
    if (offer != null) throw StateError('there is an offer to resolve first');
  }

  /// Decides the first pending offer: [take] it (if the pack is full, name an
  /// item to leave behind in [replacing]), or leave it where it is.
  List<GameEvent> resolveOffer({required bool take, String? replacing}) {
    final item = offer ?? (throw StateError('there is no offer to resolve'));
    final swap = take && offerNeedsRoom;
    if (swap &&
        (replacing == null ||
            !_state.inventory.contains(replacing) ||
            isContainer(replacing))) {
      throw StateError('the pack is full: choose a carried item to leave');
    }
    return _run((events) {
      final count = _state.offered(item);
      _state = _state.copyWith(
        offers: _state.offers.skip(1).toList(),
        offerCounts: {..._state.offerCounts}..remove(item),
      );
      // Leaving a carried item behind leaves all of it.
      if (swap) _state = withCount(_state, replacing!, 0);
      if (take) {
        _add(item, count, events);
      } else {
        events.add(OfferDeclined(item));
      }
      _enforceCapacity(events);
    });
  }

  /// Applies [effects] in order. `give` follows the story's pickup rule: it
  /// adds the item, refuses it if the pack is full, or turns it into an offer.
  void _applyEffects(Iterable<Effect> effects, List<GameEvent> events) {
    for (final effect in effects) {
      if (_dead) break;
      if (effect is GiveItem) {
        _give(effect.item, effect.amount, events);
      } else if (effect is Achieve) {
        events.add(AchievementEarned(effect.achievement));
      } else {
        _state = applyEffect(effect, _state);
      }
      _enforceCapacity(events);
    }
  }

  /// Gives [count] of [item] by the story's pickup rule (B4).
  void _give(String item, int count, List<GameEvent> events) {
    final countable = _stack(item) != null;
    if (_state.offers.contains(item)) {
      // A further give while it is on offer adds to the offer.
      if (countable) _offer(item, _state.offered(item) + count);
      return;
    }
    if (!countable && _state.inventory.contains(item)) return;
    if (rules.inventory.pickup == PickupMode.choose) {
      // What fits without a new slot is added; past the cap nothing can be;
      // anything else is offered.
      if (countable && count <= min(_slotRoom(item), _capLeft(item))) {
        _state = withCount(_state, item, _state.count(item) + count);
      } else if (countable && _capLeft(item) == 0) {
        events.add(ItemRefused(item, count));
      } else {
        _offer(item, countable ? count : 1);
      }
      return;
    }
    _add(item, countable ? count : 1, events);
  }

  /// Adds as many of [count] as fit; the player is told how many were left.
  void _add(String item, int count, List<GameEvent> events) {
    final added = min(count, _room(item));
    if (added > 0) {
      _state = withCount(
        _state,
        item,
        _stack(item) == null ? 1 : _state.count(item) + added,
      );
    }
    if (count > added) events.add(ItemRefused(item, count - added));
  }

  void _offer(String item, int count) {
    final counts = {..._state.offerCounts}..remove(item);
    if (count != 1) counts[item] = count;
    _state = _state.copyWith(
      offers: _state.offers.contains(item)
          ? _state.offers
          : [..._state.offers, item],
      offerCounts: counts,
    );
  }

  /// After a container left the pack, drops the most recently picked up items
  /// that no longer fit; of a countable item, only the units that do not fit.
  void _enforceCapacity(List<GameEvent> events) {
    while (capacity != null && slotsUsed > capacity!) {
      final lost = _state.inventory.lastWhere((i) => !isContainer(i));
      final had = _state.count(lost);
      final others = slotsUsed - _slots(lost, had);
      final stack = _stack(lost);
      final kept = stack == null
          ? 0
          : min(had, max(0, capacity! - others) * stack);
      _state = withCount(_state, lost, kept);
      events.add(ItemOverflow(lost, had - kept));
    }
  }

  /// Runs [action], then adds the item/stat changes and the ending, if any.
  List<GameEvent> _run(void Function(List<GameEvent> events) action) {
    final before = _state;
    final events = <GameEvent>[];
    action(events);
    // Offers do not outlive the game (B4).
    if (ending != null && _state.offers.isNotEmpty) {
      _state = _state.copyWith(offers: const [], offerCounts: const {});
    }
    final overflowed = {
      for (final e in events)
        if (e is ItemOverflow) e.item,
    };
    events.addAll(
      _changes(before, _state).where(
        // Overflow already says why the item went.
        (e) => switch (e) {
          ItemLost(:final item) ||
          ItemCountChanged(:final item) => !overflowed.contains(item),
          _ => true,
        },
      ),
    );
    if (ending case final ending?) events.add(Ended(ending));
    return events;
  }

  void _enter(String id, List<GameEvent> events) {
    final next = story.nodes[id] ?? (throw StateError('unknown node "$id"'));
    final first = !_state.visited.contains(id);
    _state = _state.copyWith(
      node: id,
      visited: {..._state.visited, id},
      visits: {..._state.visits, id: _state.visitsTo(id) + 1},
    );
    if (!next.once || first) _applyEffects(next.effects, events);
    if (next.music case final music?) {
      final file = music == stopMusic ? null : music;
      if (file != _state.music) {
        _state = _state.copyWith(music: file, stopMusic: file == null);
        events.add(MusicChanged(file));
      }
    }
    if (next.sound case final sound?) events.add(SoundPlayed(sound));
    _state = _state.withCombat(
      next.combat == null || next.draft ? null : startCombat(next.combat!),
    );
    events.add(NodeEntered(id));
  }

  static List<GameEvent> _changes(GameState before, GameState after) => [
    for (final item in after.inventory.difference(before.inventory))
      ItemGained(item, after.count(item)),
    for (final item in before.inventory.difference(after.inventory))
      ItemLost(item),
    for (final item in after.inventory.intersection(before.inventory))
      if (before.count(item) != after.count(item))
        ItemCountChanged(item, before.count(item), after.count(item)),
    for (final MapEntry(:key, :value) in after.stats.entries)
      if (before.stats[key]?.value != value.value)
        StatChanged(key, before.stats[key]?.value ?? 0, value.value),
    for (final entry in after.journal)
      if (!before.journal.contains(entry)) JournalUnlocked(entry),
  ];
}

/// Whether a saved [state] still fits [story] (spec B14, "Updates and
/// saves"): every node, item, stat and journal entry it names exists, and a
/// fight under way still matches the fight on its page. A save that does not
/// fit must be dropped, never played: it could point at a page or an enemy
/// that is gone.
bool stateFits(GameState state, Story story, Rules rules) {
  bool node(String id) => story.nodes.containsKey(id);
  bool item(String id) => story.items.containsKey(id);
  final current = story.nodes[state.node];
  if (current == null) return false;
  final stats = {for (final s in rules.stats) s.id};
  if (!state.stats.keys.toSet().containsAll(stats) ||
      !stats.containsAll(state.stats.keys)) {
    return false;
  }
  // Each stat within its floor and ceiling, and the floor the story's.
  for (final rule in rules.stats) {
    final s = state.stats[rule.id]!;
    if (s.min != rule.min ||
        s.value < s.min ||
        (s.max != null && s.value > s.max!)) {
      return false;
    }
  }
  if (!state.inventory.every(item) || !state.offers.every(item)) return false;
  // Counts only for countable items held or offered, and at least 1 each.
  bool counted(Map<String, int> counts, Iterable<String> where) =>
      counts.entries.every(
        (e) =>
            e.value >= 1 &&
            where.contains(e.key) &&
            story.items[e.key]?.stack != null &&
            e.value <= (story.items[e.key]!.max ?? e.value),
      );
  if (!counted(state.counts, state.inventory) ||
      !counted(state.offerCounts, state.offers)) {
    return false;
  }
  if (rules.inventory.capacity case final base?) {
    var room = base;
    var used = 0;
    for (final id in state.inventory) {
      final it = story.items[id]!;
      room += it.capacity ?? 0;
      final stack = it.stack;
      if (it.capacity == null) {
        used += stack == null ? 1 : (state.count(id) + stack - 1) ~/ stack;
      }
    }
    if (used > room) return false;
  }
  if (!state.visited.every(node) ||
      !state.visits.keys.every(node) ||
      !state.visits.values.every((n) => n >= 1)) {
    return false;
  }
  if (!state.journal.every(story.journal.containsKey)) return false;
  for (final taken in state.taken) {
    final hash = taken.lastIndexOf('#');
    final choices = story.nodes[taken.substring(0, hash < 0 ? 0 : hash)];
    final index = int.tryParse(taken.substring(hash + 1));
    if (choices == null ||
        index == null ||
        index < 0 ||
        index >= choices.choices.length) {
      return false;
    }
  }
  if (state.combat case final fight?) {
    final enemies = current.combat?.enemies;
    bool enemy(int i) => i >= 0 && i < (enemies?.length ?? 0);
    if (enemies == null ||
        fight.round < 0 ||
        fight.enemyHealth.length != enemies.length ||
        !enemy(fight.enemy)) {
      return false;
    }
    for (var i = 0; i < enemies.length; i++) {
      final health = fight.enemyHealth[i];
      if (health < 0 || health > enemies[i].health) return false;
    }
    if (fight.luck case final luck?
        when !enemy(luck.enemy) || luck.dealt < 0 || luck.taken < 0) {
      return false;
    }
  }
  return true;
}
