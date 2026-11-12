import 'package:web/web.dart';

import '../play/views.dart';
import 'dom.dart';
import 'wording.dart';

/// The fight: enemies with health bars, then attack, luck and flee buttons.
class CombatPanel {
  CombatPanel(
    this.combat,
    this.m, {
    required this.onFight,
    required this.onLuck,
    required this.onFlee,
  });

  final CombatView combat;
  final Messages m;
  final void Function({int? target}) onFight;
  final void Function() onLuck;
  final void Function() onFlee;

  HTMLElement get element => el(
    'div',
    cls: 'gb-combat',
    children: [
      el('p', cls: 'label gb-combat-label', text: m('player.enemies')),
      el('ul', children: [for (final e in combat.enemies) _enemy(e)]),
      el('div', cls: 'gb-actions', children: _actions()),
    ],
  );

  HTMLElement _enemy(EnemyView e) => el(
    'li',
    cls: 'gb-enemy${e.alive ? '' : ' dead'}${e.current ? ' current' : ''}',
    children: [
      el('strong', text: e.name),
      if (e.armor > 0)
        el('span', cls: 'label', text: m('player.armor', {'armor': e.armor})),
      el(
        'span',
        cls: 'gb-health',
        attrs: {
          'role': 'meter',
          'aria-valuemin': '0',
          'aria-valuemax': '${e.maxHealth}',
          'aria-valuenow': '${e.health}',
          'aria-label': e.name,
          'style': '--hp: ${e.maxHealth == 0 ? 0 : e.health / e.maxHealth}',
        },
      ),
      el('span', cls: 'label gb-hp', text: '${e.health}/${e.maxHealth}'),
    ],
  );

  List<HTMLElement> _actions() => [
    ..._attacks(),
    if (combat.canTestLuck)
      onClick(
        el('button', cls: 'btn btn-amber', text: m('player.luck')),
        onLuck,
      ),
    if (combat.canFlee)
      onClick(
        el(
          'button',
          cls: 'btn btn-danger',
          text: m(combat.fleeCostsRound ? 'player.fleeRound' : 'player.flee'),
        ),
        onFlee,
      ),
  ];

  /// One Attack button, or one per living enemy when the player picks.
  List<HTMLElement> _attacks() {
    if (!combat.pickTarget) {
      return [
        onClick(el('button', cls: 'btn', text: m('player.fight')), onFight),
      ];
    }
    return [
      for (final e in combat.enemies)
        if (e.alive)
          onClick(
            el(
              'button',
              cls: 'btn',
              text: m('player.attack', {'enemy': e.name}),
            ),
            () => onFight(target: e.index),
          ),
    ];
  }
}
