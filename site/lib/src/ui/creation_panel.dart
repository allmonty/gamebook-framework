import 'dart:js_interop';

import 'package:web/web.dart';

import '../play/hero_draft.dart';
import '../play/views.dart';
import 'dom.dart';
import 'wording.dart';

/// Character creation: stats with Roll again, the hero's name, pick groups
/// and Begin. [onChange] redraws; typing the name does not, to keep focus.
class CreationPanel {
  CreationPanel(
    this.draft,
    this.m, {
    required this.onChange,
    required this.onBegin,
  });

  final HeroDraft draft;
  final Messages m;
  final void Function() onChange;
  final void Function() onBegin;

  HTMLElement get element {
    final view = draft.view;
    final begin = onClick(
      el('button', cls: 'btn', text: m('player.begin')),
      onBegin,
    );
    _enable(begin, view.ready);
    return el(
      'div',
      cls: 'gb-creation card',
      children: [
        el('h3', cls: 'gb-title', text: m('player.create')),
        el(
          'ul',
          cls: 'gb-hud',
          children: [
            for (final s in view.stats)
              el(
                'li',
                cls: 'gb-pill',
                children: [
                  el('span', cls: 'label', text: s.label),
                  el('strong', text: '${s.value}'),
                ],
              ),
          ],
        ),
        if (view.rerollsLeft > 0)
          onClick(
            el(
              'button',
              cls: 'btn btn-ghost',
              text: m('player.reroll', {'count': view.rerollsLeft}),
            ),
            () {
              draft.reroll();
              onChange();
            },
          ),
        if (view.asksName) _name(view, begin),
        for (final group in view.groups) _group(group),
        begin,
      ],
    );
  }

  HTMLElement _name(CreationView view, HTMLElement begin) {
    final input = el(
      'input',
      attrs: {
        'type': 'text',
        'autocomplete': 'off',
        'maxlength': '${HeroDraft.maxNameLength}',
      },
    ) as HTMLInputElement..value = view.name;
    input.addEventListener(
      'input',
      ((Event _) {
        draft.name = input.value;
        _enable(begin, draft.ready);
      }).toJS,
    );
    return el(
      'label',
      cls: 'gb-field',
      children: [
        el('span', cls: 'label', text: m('player.name')),
        input,
      ],
    );
  }

  HTMLElement _group(PickGroupView group) => el(
    'fieldset',
    cls: 'gb-picks',
    children: [
      el(
        'legend',
        cls: 'label',
        text: m('player.pick', {
          'title': group.title,
          'picked': group.picked,
          'count': group.count,
        }),
      ),
      for (final option in group.options)
        onClick(
          el(
            'button',
            cls: 'gb-choice${option.picked ? ' picked' : ''}',
            attrs: {'aria-pressed': '${option.picked}'},
            children: [
              el('span', cls: 'gb-index', text: option.picked ? '[x]' : '[ ]'),
              el('span', cls: 'gb-text', text: option.label),
              if (option.description != null)
                el('span', cls: 'gb-needs', text: option.description),
            ],
          ),
          () {
            draft.toggle(group.id, option.id);
            onChange();
          },
        ),
    ],
  );

  static void _enable(HTMLElement button, bool enabled) =>
      (button as HTMLButtonElement).disabled = !enabled;
}
