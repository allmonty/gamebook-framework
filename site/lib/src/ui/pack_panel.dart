import 'package:web/web.dart';

import '../play/views.dart';
import 'dom.dart';
import 'wording.dart';

/// The pack: a folding list of carried items, with Use buttons.
class PackPanel {
  PackPanel(this.pack, this.m, {required this.onUse});

  final PackView pack;
  final Messages m;
  final void Function(String id) onUse;

  HTMLElement get element => el(
    'details',
    cls: 'gb-pack',
    children: [
      el(
        'summary',
        cls: 'label',
        text: pack.capacity == null
            ? m('player.pack', {'count': pack.items.length})
            : m('player.packOf', {
                'used': pack.used,
                'capacity': pack.capacity!,
              }),
      ),
      if (pack.items.isEmpty)
        el('p', cls: 'gb-empty', text: m('player.empty'))
      else
        el('ul', children: [for (final item in pack.items) _row(item)]),
    ],
  );

  HTMLElement _row(PackItem item) => el(
    'li',
    cls: 'gb-item',
    children: [
      itemCard(item, m),
      if (item.usable)
        onClick(
          el('button', cls: 'btn btn-ghost', text: m('player.use')),
          () => onUse(item.id),
        ),
    ],
  );
}

/// An item found: take it, leave it, or swap something out when full.
class OfferPanel {
  OfferPanel(this.offer, this.m, {required this.onTake, required this.onLeave});

  final OfferView offer;
  final Messages m;
  final void Function({String? replacing}) onTake;
  final void Function() onLeave;

  HTMLElement get element => el(
    'div',
    cls: 'gb-offer card',
    attrs: {'role': 'group', 'aria-label': m('player.offer')},
    children: [
      el('p', cls: 'label', text: m('player.offer')),
      itemCard(offer.item, m),
      if (offer.needsSwap) el('p', text: m('player.full')),
      el(
        'div',
        cls: 'gb-actions',
        children: [
          if (offer.needsSwap)
            for (final carried in offer.swapFrom)
              onClick(
                el(
                  'button',
                  cls: 'btn',
                  text: m('player.swap', {'name': carried.name}),
                ),
                () => onTake(replacing: carried.id),
              )
          else
            onClick(el('button', cls: 'btn', text: m('player.take')), onTake),
          onClick(
            el('button', cls: 'btn btn-ghost', text: m('player.leave')),
            onLeave,
          ),
        ],
      ),
      if (offer.more > 0)
        el(
          'p',
          cls: 'label',
          text: m('player.moreOffers', {'count': offer.more}),
        ),
    ],
  );
}

/// Name, description and what the item changes.
HTMLElement itemCard(PackItem item, Messages m) => el(
  'div',
  children: [
    el('strong', text: item.name),
    for (final (label, amount) in item.bonus)
      el(
        'span',
        cls: 'gb-bonus',
        text: ' ${amount > 0 ? '+' : ''}$amount $label',
      ),
    if (item.room != null)
      el(
        'span',
        cls: 'gb-bonus',
        text: ' ${m('player.room', {'count': item.room!})}',
      ),
    if (item.description != null) el('p', text: item.description),
  ],
);
