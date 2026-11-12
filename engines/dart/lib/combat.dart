import 'dart:math';

import 'dice.dart';
import 'rules.dart';
import 'state.dart';
import 'story.dart';

enum CombatOutcome { ongoing, won, lost }

/// What happened in one round. See spec/framework.md B11.
class RoundResult {
  const RoundResult({
    required this.enemy,
    required this.playerAttack,
    required this.playerTotal,
    this.playerTarget,
    this.enemyAttack,
    this.enemyTotal,
    this.enemyTarget,
    this.ratio,
    required this.damageToEnemy,
    required this.damageToPlayer,
    required this.outcome,
    required this.state,
  });

  final Enemy enemy;
  final DiceRoll playerAttack;
  final int playerTotal;

  /// The combat ratio (`table` mode only): the player's attack stat minus the
  /// enemy's attack.
  final int? ratio;

  /// What the player had to reach (`vs-defense` only).
  final int? playerTarget;

  /// Null when the enemy died before it could attack.
  final DiceRoll? enemyAttack;
  final int? enemyTotal;
  final int? enemyTarget;
  final int damageToEnemy;
  final int damageToPlayer;
  final CombatOutcome outcome;

  /// The state after the round, with the fight updated (not ended: the engine
  /// decides what to do with [outcome]).
  final GameState state;
}

/// An enemy attack while the player does something else (using an item that
/// costs the round). See spec/framework.md B5.
class StrikeResult {
  const StrikeResult({
    required this.enemy,
    this.enemyAttack,
    this.enemyTotal,
    this.enemyTarget,
    required this.damageToPlayer,
    required this.outcome,
    required this.state,
  });

  final Enemy enemy;

  /// Null in `opposed` mode: the enemy wins the round without a contest.
  final DiceRoll? enemyAttack;
  final int? enemyTotal;
  final int? enemyTarget;
  final int damageToPlayer;

  /// [CombatOutcome.lost] if the player's health reached 0, else ongoing.
  final CombatOutcome outcome;
  final GameState state;
}

Dice _enemyDamage(Enemy enemy, CombatRules rules) =>
    enemy.damage == null ? rules.damage : Dice.parse(enemy.damage!);

/// Whether the fight is resolved by the results table of the rules.
bool _usesTable(CombatRules cr, Combat combat) =>
    cr.mode == CombatMode.table || combat.duel;

/// The row of the results table for [ratio] (the last takes the rest).
ResultsRow _tableRow(CombatRules cr, int ratio) => cr.table.firstWhere(
  (row) => row.upTo != null && ratio <= row.upTo!,
  orElse: () => cr.table.last,
);

/// A wound dealt to [enemy], less its armor (never below 0).
int _wound(int damage, Enemy enemy) => max(0, damage - enemy.armor);

/// An enemy of the fight in [state] (the current one unless [enemyIndex]
/// says otherwise, as in a simultaneous fight) strikes while the player forfeits
/// the round: in `opposed` mode it simply wins the round, in `vs-defense` mode
/// it makes its normal attack roll against the player's defense.
StrikeResult enemyStrike({
  required Rules rules,
  required Combat combat,
  required GameState state,
  required Random random,
  int? enemyIndex,
}) {
  final fight = state.combat!;
  final enemy = combat.enemies[enemyIndex ?? fight.enemy];
  final cr = rules.combat!;
  final damage = _enemyDamage(enemy, cr);
  var dealt = 0;
  DiceRoll? attack;
  int? total;
  int? target;
  if (_usesTable(cr, combat)) {
    // Only the player's loss counts; the enemy's loss is not applied.
    final ratio = state.stat(cr.attackStat) - enemy.attack;
    dealt = _tableRow(cr, ratio).results[cr.tableRoll!.roll(random).total].$2;
  } else {
    switch (cr.mode) {
      case CombatMode.opposed:
        dealt = damage.roll(random).total;
      case CombatMode.vsDefense:
        attack = cr.attackRoll.roll(random);
        total = attack.total + enemy.attack;
        target = cr.defenseBase! + state.stat(cr.defenseStat!);
        if (total >= target) dealt = damage.roll(random).total;
      case CombatMode.table:
        throw StateError('unreachable: table mode uses the table');
    }
  }
  final health = state.stats[rules.health]!.adjusted(-dealt);
  return StrikeResult(
    enemy: enemy,
    enemyAttack: attack,
    enemyTotal: total,
    enemyTarget: target,
    damageToPlayer: dealt,
    outcome: health.value == 0 ? CombatOutcome.lost : CombatOutcome.ongoing,
    state: state
        .copyWith(stats: {...state.stats, rules.health: health})
        .withCombat(
          CombatState(fight.enemy, fight.enemyHealth, null, fight.round),
        ),
  );
}

/// The state at the start of [combat]: first enemy, everyone at full health.
CombatState startCombat(Combat combat) =>
    CombatState(0, [for (final e in combat.enemies) e.health]);

/// Plays one round of the fight in [state] (which must have `combat`) against
/// the current enemy. The player attacks first.
RoundResult fightRound({
  required Rules rules,
  required Combat combat,
  required GameState state,
  required Random random,
}) {
  final fight = state.combat!;
  final enemy = combat.enemies[fight.enemy];
  final cr = rules.combat!;
  final enemyDamage = _enemyDamage(enemy, cr);
  // In `table` mode, and in a fight marked `duel`, the roll alone picks the
  // result from the table.
  final useTable = _usesTable(cr, combat);

  final playerAttack = (useTable ? cr.tableRoll! : cr.attackRoll).roll(random);
  final playerTotal = useTable
      ? playerAttack.total
      : playerAttack.total + state.stat(cr.attackStat);

  var damageToEnemy = 0;
  var damageToPlayer = 0;
  DiceRoll? enemyAttack;
  int? enemyTotal;
  int? playerTarget;
  int? enemyTarget;
  int? ratio;

  if (useTable) {
    ratio = state.stat(cr.attackStat) - enemy.attack;
    final (enemyLoss, playerLoss) = _tableRow(
      cr,
      ratio,
    ).results[playerAttack.total];
    damageToEnemy = _wound(enemyLoss, enemy);
    damageToPlayer = playerLoss;
  } else {
    switch (cr.mode) {
      case CombatMode.table:
        throw StateError('unreachable: table mode uses the table');
      case CombatMode.opposed:
        enemyAttack = cr.attackRoll.roll(random);
        enemyTotal = enemyAttack.total + enemy.attack;
        if (playerTotal > enemyTotal) {
          damageToEnemy = _wound(cr.damage.roll(random).total, enemy);
        } else if (enemyTotal > playerTotal) {
          damageToPlayer = enemyDamage.roll(random).total;
        }
      case CombatMode.vsDefense:
        playerTarget =
            enemy.defense ??
            (throw StateError('enemy "${enemy.name}" needs a defense'));
        if (playerTotal >= playerTarget) {
          damageToEnemy = _wound(cr.damage.roll(random).total, enemy);
        }
        if (fight.enemyHealth[fight.enemy] - damageToEnemy > 0) {
          enemyAttack = cr.attackRoll.roll(random);
          enemyTotal = enemyAttack.total + enemy.attack;
          enemyTarget = cr.defenseBase! + state.stat(cr.defenseStat!);
          if (enemyTotal >= enemyTarget) {
            damageToPlayer = enemyDamage.roll(random).total;
          }
        }
    }
  }

  final health = [...fight.enemyHealth];
  health[fight.enemy] = max(0, health[fight.enemy] - damageToEnemy);
  final playerHealth = state.stats[rules.health]!.adjusted(-damageToPlayer);
  final enemyDead = health[fight.enemy] == 0;
  final lastEnemy = fight.enemy == combat.enemies.length - 1;

  final outcome = playerHealth.value == 0
      ? CombatOutcome.lost
      : enemyDead && lastEnemy
      ? CombatOutcome.won
      : CombatOutcome.ongoing;
  // Luck can only change wounds of a fight that goes on, and a wound dealt to
  // an enemy that has just died would have to bring it back.
  final luck =
      cr.luck != null &&
          !useTable &&
          outcome == CombatOutcome.ongoing &&
          !enemyDead &&
          (damageToEnemy > 0 || damageToPlayer > 0)
      ? LuckChance(
          enemy: fight.enemy,
          dealt: damageToEnemy,
          taken: damageToPlayer,
        )
      : null;

  return RoundResult(
    enemy: enemy,
    playerAttack: playerAttack,
    playerTotal: playerTotal,
    playerTarget: playerTarget,
    enemyAttack: enemyAttack,
    enemyTotal: enemyTotal,
    enemyTarget: enemyTarget,
    ratio: ratio,
    damageToEnemy: damageToEnemy,
    damageToPlayer: damageToPlayer,
    outcome: outcome,
    state: state
        .copyWith(stats: {...state.stats, rules.health: playerHealth})
        .withCombat(
          CombatState(
            enemyDead && !lastEnemy ? fight.enemy + 1 : fight.enemy,
            health,
            luck,
            fight.round,
          ),
        ),
  );
}

/// One enemy's side of a round against several enemies at once.
class GroupAttack {
  const GroupAttack({
    required this.enemy,
    required this.roll,
    required this.total,
    this.target,
    required this.damageToPlayer,
  });

  final Enemy enemy;
  final DiceRoll roll;
  final int total;

  /// What the enemy had to reach (`vs-defense` only).
  final int? target;
  final int damageToPlayer;
}

/// What happened in one round of a simultaneous fight: the player attacked
/// [target] and every enemy still standing attacked the player.
class GroupRoundResult {
  const GroupRoundResult({
    required this.target,
    required this.playerAttack,
    required this.playerTotal,
    this.playerTarget,
    required this.damageToEnemy,
    required this.attacks,
    required this.outcome,
    required this.state,
  });

  final Enemy target;
  final DiceRoll playerAttack;
  final int playerTotal;

  /// What the player had to reach (`vs-defense` only).
  final int? playerTarget;
  final int damageToEnemy;

  /// The enemies that attacked, in story order (a target that died in
  /// `vs-defense` mode does not).
  final List<GroupAttack> attacks;
  final CombatOutcome outcome;
  final GameState state;

  int get damageToPlayer => attacks.fold(0, (sum, a) => sum + a.damageToPlayer);
}

/// Plays one round of the simultaneous fight in [state]: the player attacks
/// the enemy at index [target] and every living enemy attacks the player.
/// See spec/framework.md B11.
GroupRoundResult groupRound({
  required Rules rules,
  required Combat combat,
  required GameState state,
  required Random random,
  required int target,
}) {
  final fight = state.combat!;
  final cr = rules.combat!;
  if (combat.duel) {
    throw StateError('a results table cannot be used against a group');
  }
  final focus = combat.enemies[target];
  if (fight.enemyHealth[target] == 0) {
    throw StateError('"${focus.name}" is already dead');
  }

  final playerAttack = cr.attackRoll.roll(random);
  final playerTotal = playerAttack.total + state.stat(cr.attackStat);
  final health = [...fight.enemyHealth];
  var damageToEnemy = 0;
  int? playerTarget;
  final attacks = <GroupAttack>[];

  void strike(int i) {
    final enemy = combat.enemies[i];
    final roll = cr.attackRoll.roll(random);
    final total = roll.total + enemy.attack;
    var dealt = 0;
    int? needed;
    switch (cr.mode) {
      case CombatMode.opposed:
        // Against the target a higher player total wounds the enemy instead.
        if (total > playerTotal) {
          dealt = _enemyDamage(enemy, cr).roll(random).total;
        } else if (i == target && playerTotal > total) {
          damageToEnemy = _wound(cr.damage.roll(random).total, enemy);
        }
      case CombatMode.vsDefense:
        needed = cr.defenseBase! + state.stat(cr.defenseStat!);
        if (total >= needed) dealt = _enemyDamage(enemy, cr).roll(random).total;
      case CombatMode.table:
        throw StateError('a results table cannot be used against a group');
    }
    attacks.add(
      GroupAttack(
        enemy: enemy,
        roll: roll,
        total: total,
        target: needed,
        damageToPlayer: dealt,
      ),
    );
  }

  switch (cr.mode) {
    case CombatMode.table:
      throw StateError('a results table cannot be used against a group');
    case CombatMode.opposed:
      for (var i = 0; i < combat.enemies.length; i++) {
        if (health[i] > 0) strike(i);
      }
    case CombatMode.vsDefense:
      playerTarget =
          focus.defense ??
          (throw StateError('enemy "${focus.name}" needs a defense'));
      if (playerTotal >= playerTarget) {
        damageToEnemy = _wound(cr.damage.roll(random).total, focus);
      }
      health[target] = max(0, health[target] - damageToEnemy);
      for (var i = 0; i < combat.enemies.length; i++) {
        if (health[i] > 0) strike(i);
      }
  }
  health[target] = max(0, fight.enemyHealth[target] - damageToEnemy);

  final taken = attacks.fold(0, (sum, a) => sum + a.damageToPlayer);
  final playerHealth = state.stats[rules.health]!.adjusted(-taken);
  final allDead = health.every((h) => h == 0);
  final outcome = playerHealth.value == 0
      ? CombatOutcome.lost
      : allDead
      ? CombatOutcome.won
      : CombatOutcome.ongoing;
  final luck =
      cr.luck != null &&
          outcome == CombatOutcome.ongoing &&
          health[target] > 0 &&
          (damageToEnemy > 0 || taken > 0)
      ? LuckChance(enemy: target, dealt: damageToEnemy, taken: taken)
      : null;

  return GroupRoundResult(
    target: focus,
    playerAttack: playerAttack,
    playerTotal: playerTotal,
    playerTarget: playerTarget,
    damageToEnemy: damageToEnemy,
    attacks: attacks,
    outcome: outcome,
    state: state
        .copyWith(stats: {...state.stats, rules.health: playerHealth})
        .withCombat(CombatState(fight.enemy, health, luck, fight.round)),
  );
}

/// A test of luck in a fight. See spec/framework.md B11.
class LuckResult {
  const LuckResult({
    required this.enemy,
    required this.roll,
    required this.target,
    required this.lucky,
    required this.enemyLoss,
    required this.playerLoss,
    required this.outcome,
    required this.state,
  });

  /// The enemy whose wound may have changed.
  final Enemy enemy;
  final DiceRoll roll;

  /// The luck stat when the dice were rolled: [roll] at or below it is lucky.
  final int target;
  final bool lucky;

  /// How many more points of health the enemy lost (negative: it got some
  /// back).
  final int enemyLoss;

  /// How many more points of health the player lost (negative: some back).
  final int playerLoss;
  final CombatOutcome outcome;
  final GameState state;
}

/// The player spends a point of luck on the wounds of the last round, which
/// must have left [CombatState.luck] open.
LuckResult testFightLuck({
  required Rules rules,
  required Combat combat,
  required GameState state,
  required Random random,
}) {
  final fight = state.combat!;
  final chance = fight.luck ?? (throw StateError('luck cannot be tested now'));
  final luck = rules.combat!.luck!;
  final enemy = combat.enemies[chance.enemy];

  final roll = luck.roll.roll(random);
  final target = state.stat(luck.stat);
  final lucky = roll.total <= target;
  final change = lucky ? luck.lucky : luck.unlucky;

  final health = [...fight.enemyHealth];
  var enemyLoss = 0;
  if (chance.dealt > 0) {
    final before = health[chance.enemy];
    final wound = max(0, chance.dealt + change.dealt);
    health[chance.enemy] = (before + chance.dealt - wound).clamp(
      0,
      enemy.health,
    );
    enemyLoss = before - health[chance.enemy];
  }
  var playerHealth = state.stats[rules.health]!;
  final playerBefore = playerHealth.value;
  if (chance.taken > 0) {
    final wound = max(0, chance.taken + change.taken);
    playerHealth = playerHealth.adjusted(chance.taken - wound);
  }

  final dead = health[chance.enemy] == 0;
  // Fights against several at once are won when all are down; in a row, when
  // the last one is.
  final lastEnemy = combat.simultaneous
      ? health.every((h) => h == 0)
      : chance.enemy == combat.enemies.length - 1;
  final outcome = playerHealth.value == 0
      ? CombatOutcome.lost
      : dead && lastEnemy
      ? CombatOutcome.won
      : CombatOutcome.ongoing;

  return LuckResult(
    enemy: enemy,
    roll: roll,
    target: target,
    lucky: lucky,
    enemyLoss: enemyLoss,
    playerLoss: playerBefore - playerHealth.value,
    outcome: outcome,
    state: state
        .copyWith(
          stats: {
            ...state.stats,
            rules.health: playerHealth,
            luck.stat: state.stats[luck.stat]!.adjusted(-1),
          },
        )
        .withCombat(
          CombatState(
            dead && !lastEnemy ? chance.enemy + 1 : fight.enemy,
            health,
            null,
            fight.round,
          ),
        ),
  );
}
