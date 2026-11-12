import 'json_reader.dart';
import 'quantity.dart';
import 'state.dart';

/// A change to the game state. See spec/framework.md B9.
sealed class Effect {
  const Effect();

  factory Effect.fromJson(Object? json, String path) {
    final obj = JsonObject(json, path);
    const kinds = [
      'give',
      'take',
      'stat',
      'set',
      'clear',
      'takeAll',
      'journal',
      'achieve',
    ];
    // With `stat` present, `add` or `set` is a stat effect (schema 5 added
    // `set` and quantities); `set` alone is a flag.
    if (obj.has('stat')) return _statChange(obj);
    final present = kinds.where(obj.has).toList();
    if (present.length != 1) {
      throw StoryFormatException(
        path,
        'an effect needs exactly one of ${kinds.join(', ')}',
      );
    }
    final kind = present.single;
    if (kind == 'takeAll') {
      if (!obj.optBool('takeAll')) {
        throw obj.error('takeAll', 'must be true');
      }
      obj.finish();
      return const TakeAll();
    }
    final id = checkId(obj.string(kind), obj.childPath(kind));
    final Effect effect = switch (kind) {
      'give' => GiveItem(id),
      'take' => TakeItem(id),
      'set' => SetFlag(id),
      'clear' => ClearFlag(id),
      'journal' => UnlockEntry(id),
      'achieve' => Achieve(id),
      _ => throw StateError('unreachable'),
    };
    obj.finish();
    return effect;
  }

  static StatChange _statChange(JsonObject obj) {
    final hasAdd = obj.has('add');
    final hasSet = obj.has('set');
    if (hasAdd == hasSet) {
      throw StoryFormatException(
        obj.path,
        'a stat effect needs exactly one of add or set',
      );
    }
    final key = hasAdd ? 'add' : 'set';
    final change = StatChange(
      checkId(obj.string('stat'), obj.childPath('stat')),
      Quantity.fromJson(obj.raw(key), obj.childPath(key)),
      replace: hasSet,
    );
    obj.finish();
    return change;
  }
}

class GiveItem extends Effect {
  const GiveItem(this.item);
  final String item;
}

class TakeItem extends Effect {
  const TakeItem(this.item);
  final String item;
}

/// Adds to a stat, or sets it (`replace`), clamped to its limits.
class StatChange extends Effect {
  const StatChange(this.stat, this.amount, {this.replace = false});
  final String stat;

  /// A number, or another stat's value (schema 5).
  final Quantity amount;

  /// True for `set`: the stat becomes [amount] instead of changing by it.
  final bool replace;
}

/// Removes every item from the pack (a theft, a flood).
class TakeAll extends Effect {
  const TakeAll();
}

class SetFlag extends Effect {
  const SetFlag(this.flag);
  final String flag;
}

/// Unlocks a journal entry (schema 5); a second unlock does nothing.
class UnlockEntry extends Effect {
  const UnlockEntry(this.entry);
  final String entry;
}

/// Earns an achievement (schema 7). It changes nothing in the game: the
/// engine reports it, and the app keeps it for the player.
class Achieve extends Effect {
  const Achieve(this.achievement);
  final String achievement;
}

class ClearFlag extends Effect {
  const ClearFlag(this.flag);
  final String flag;
}

/// [state] after [effect]. A stat the state does not have is left alone.
GameState applyEffect(Effect effect, GameState state) => switch (effect) {
  GiveItem(:final item) => state.copyWith(
    inventory: {...state.inventory, item},
  ),
  TakeItem(:final item) => state.copyWith(
    inventory: {...state.inventory}..remove(item),
  ),
  TakeAll() => state.copyWith(inventory: const {}),
  SetFlag(:final flag) => state.copyWith(flags: {...state.flags, flag}),
  ClearFlag(:final flag) => state.copyWith(
    flags: {...state.flags}..remove(flag),
  ),
  Achieve() => state,
  UnlockEntry(:final entry) =>
    state.journal.contains(entry)
        ? state
        : state.copyWith(journal: [...state.journal, entry]),
  StatChange(:final stat, :final amount, :final replace) =>
    state.stats.containsKey(stat)
        ? state.copyWith(
            stats: {
              ...state.stats,
              stat: replace
                  ? state.stats[stat]!.clampedTo(amount.resolve(state))
                  : state.stats[stat]!.adjusted(amount.resolve(state)),
            },
          )
        : state,
};
