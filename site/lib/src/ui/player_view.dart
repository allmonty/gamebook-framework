import 'package:web/web.dart';

import '../play/play_session.dart';
import '../play/views.dart';
import 'audio.dart';
import 'combat_panel.dart';
import 'creation_panel.dart';
import 'dom.dart';
import 'log_panel.dart';
import 'pack_panel.dart';
import 'wording.dart';

/// Draws a [PlaySession] into [host] and redraws after every action.
class PlayerView {
  PlayerView(
    this.host,
    this.session,
    this.m, {
    this.mediaBase = '',
    AudioOutput? audio,
  }) : _audio = audio ?? AudioOutput(mediaBase) {
    host.classList.add('gb-player');
    render();
  }

  final HTMLElement host;
  final PlaySession session;
  final Messages m;

  /// The folder the story's picture and sound paths are relative to, ending
  /// in `/` (empty: the page's own folder).
  final String mediaBase;

  /// Shared by the views a lab makes one after another, so a new game takes
  /// over the music of the one before instead of playing over it.
  final AudioOutput _audio;

  void render() {
    if (session.creation case final draft?) {
      _audio.stop();
      host.replaceChildren(
        CreationPanel(
          draft,
          m,
          onChange: _redrawKeepingFocus,
          onBegin: () => _act(session.beginAdventure),
        ).element,
      );
      return;
    }
    final view = session.view;
    // A redraw makes new, closed panels: reopen the ones the reader had open.
    const pack = '.gb-pack:not(.gb-journal)';
    const journal = '.gb-journal';
    final open = [
      for (final panel in [pack, journal])
        if (host.querySelector('$panel[open]') != null) panel,
    ];
    host.replaceChildren(
      el(
        'div',
        children: [
          _hud(view.stats),
          // An empty, unlimited pack says nothing worth the space.
          if (view.pack.items.isNotEmpty || view.pack.capacity != null)
            PackPanel(
              view.pack,
              m,
              onUse: (id) => _act(() => session.useItem(id)),
            ).element,
          if (view.journal.isNotEmpty || view.achievements.isNotEmpty)
            journalPanel(view, m),
          if (view.log.isNotEmpty) logPanel(view.log, m),
          _page(view),
          if (view.ending != null) _ending(view.ending!),
          if (view.offer != null)
            OfferPanel(
              view.offer!,
              m,
              onTake: ({String? replacing}) =>
                  _act(() => session.takeOffer(replacing: replacing)),
              onLeave: () => _act(session.leaveOffer),
            ).element,
          if (view.combat != null)
            CombatPanel(
              view.combat!,
              m,
              onFight: ({int? target}) =>
                  _act(() => session.fight(target: target)),
              onLuck: () => _act(session.testLuck),
              onFlee: () => _act(session.flee),
            ).element,
          if (view.choices.isNotEmpty) _choices(view.choices),
          _controls(view),
        ],
      ),
    );
    for (final panel in open) {
      host.querySelector(panel)?.setAttribute('open', '');
    }
    _audio.play(view.audio);
  }

  /// Redraws character creation. The button just pressed is replaced by a
  /// new one, so focus goes to that one instead of being lost.
  void _redrawKeepingFocus() {
    final key = document.activeElement?.getAttribute('data-key');
    render();
    if (key != null) {
      (host.querySelector('[data-key="$key"]') as HTMLElement?)?.focus();
    }
  }

  HTMLElement _controls(PageView view) => el(
    'div',
    cls: 'gb-controls',
    children: [
      if (view.hasAudio)
        onClick(
          el(
            'button',
            cls: 'btn btn-ghost',
            text: m('player.mute'),
            attrs: {'aria-pressed': '${_audio.muted}'},
          ),
          () {
            _audio.muted = !_audio.muted;
            render();
          },
        ),
      if (view.canUndo)
        onClick(
          el('button', cls: 'btn btn-ghost', text: m('player.undo')),
          () => _act(session.undo),
        ),
      if (view.ending == null)
        onClick(
          el('button', cls: 'btn btn-ghost', text: m('player.restartNow')),
          () => _act(session.restart),
        ),
    ],
  );

  /// Runs a use case, redraws and moves focus to the new page.
  void _act(void Function() action) {
    action();
    render();
    (host.querySelector('.gb-page') as HTMLElement?)?.focus();
  }

  HTMLElement _hud(List<StatPill> stats) => el(
    'ul',
    cls: 'gb-hud',
    attrs: {'aria-label': m('player.stats')},
    children: [for (final s in stats) _pill(s)],
  );

  HTMLElement _pill(StatPill s) => el(
    'li',
    cls: 'gb-pill${s.low ? ' low' : ''}',
    children: [
      el('span', cls: 'label', text: s.label),
      el(
        'strong',
        text: s.max != null && s.max != s.value
            ? '${s.value}/${s.max}'
            : '${s.value}',
      ),
      if (s.bonus != 0)
        el(
          'span',
          cls: 'gb-bonus',
          text: s.bonus > 0 ? '+${s.bonus}' : '${s.bonus}',
        ),
    ],
  );

  HTMLElement _page(PageView view) => el(
    'article',
    cls: 'gb-page card',
    attrs: {'tabindex': '-1', 'aria-live': 'polite'},
    children: [
      if (view.heading != null) el('h3', cls: 'gb-title', text: view.heading),
      if (view.image != null)
        el(
          'img',
          attrs: {'src': '$mediaBase${view.image}', 'alt': view.imageAlt ?? ''},
        ),
      for (final p in view.paragraphs) el('p', text: p),
    ],
  );

  HTMLElement _ending(Ending ending) {
    final restart = onClick(
      el('button', cls: 'btn', text: m('player.restart')),
      () => _act(session.restart),
    );
    return el(
      'div',
      cls: 'gb-ending ${ending.name}',
      children: [
        el('p', cls: 'label', text: m('player.ending.${ending.name}')),
        restart,
      ],
    );
  }

  HTMLElement _choices(List<ChoiceItem> choices) => el(
    'div',
    cls: 'gb-choices',
    children: [
      el('p', cls: 'label gb-choices-label', text: m('player.choices')),
      el(
        'ol',
        children: [
          for (var i = 0; i < choices.length; i++)
            el('li', children: [_choiceButton(choices[i], i)]),
        ],
      ),
    ],
  );

  HTMLElement _choiceButton(ChoiceItem c, int position) {
    final button = el(
      'button',
      cls: 'gb-choice ${c.kind.name}${c.locked ? ' locked' : ''}',
      children: [
        el('span', cls: 'gb-index', text: choiceIndex(position)),
        el('span', cls: 'gb-text', text: c.text),
        if (c.locked)
          el('span', cls: 'gb-needs label', text: lockedReason(c, m)),
      ],
    );
    if (c.locked) {
      button.setAttribute('aria-disabled', 'true');
    } else {
      onClick(button, () => _act(() => session.choose(c.index)));
    }
    return button;
  }
}
