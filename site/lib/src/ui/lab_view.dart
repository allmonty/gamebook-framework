import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../play/edit_session.dart';
import 'dom.dart';
import 'player_view.dart';
import 'wording.dart';

/// A story you can play and edit: Play and Edit tabs over one
/// [EditSession]. Every edit is checked after a short pause; when the text
/// has no errors a new game starts with it.
class LabView {
  LabView(
    this.host,
    this.edit,
    this.m, {
    this.canOpenFiles = false,
    this.pause = const Duration(milliseconds: 400),
  }) {
    host.classList.add('gb-lab');
    setChildren(host, [_tabs, _playPane, _editPane]);
    _textarea.value = edit.source;
    _refresh();
    _show(play: true);
  }

  final HTMLElement host;
  final EditSession edit;
  final Messages m;

  /// The playground also offers opening a story file from disk.
  final bool canOpenFiles;

  /// How long typing must stop before the text is checked again.
  final Duration pause;

  Timer? _debounce;
  late final _playTab = _tab(m('player.tab.play'), () => _show(play: true));
  late final _editTab = _tab(m('player.tab.edit'), () => _show(play: false));
  late final _tabs = el(
    'div',
    cls: 'gb-tabs',
    attrs: {'role': 'tablist'},
    children: [_playTab, _editTab],
  );
  late final _playPane = el('div', cls: 'gb-pane', attrs: {'role': 'tabpanel'});
  late final _issues = el(
    'ul',
    cls: 'gb-issues',
    attrs: {'aria-live': 'polite'},
  );
  late final _textarea = _editor();
  late final _editPane = el(
    'div',
    cls: 'gb-pane gb-edit',
    attrs: {'role': 'tabpanel'},
    children: [
      _textarea,
      _issues,
      el(
        'div',
        cls: 'gb-actions',
        children: [
          onClick(
            el('button', cls: 'btn btn-ghost', text: m('player.reset')),
            () {
              edit.reset();
              _textarea.value = edit.source;
              _refresh();
            },
          ),
          onClick(
            el('button', cls: 'btn btn-ghost', text: m('player.download')),
            _download,
          ),
          if (canOpenFiles) _openFile(),
        ],
      ),
    ],
  );

  HTMLElement _tab(String label, void Function() select) => onClick(
    el('button', cls: 'gb-tab label', text: label, attrs: {'role': 'tab'}),
    select,
  );

  void _show({required bool play}) {
    _playTab.setAttribute('aria-selected', '$play');
    _editTab.setAttribute('aria-selected', '${!play}');
    _playPane.hidden = (!play).toJS;
    _editPane.hidden = play.toJS;
  }

  HTMLTextAreaElement _editor() {
    final area = el(
      'textarea',
      attrs: {
        'spellcheck': 'false',
        'autocapitalize': 'off',
        'aria-label': m('player.tab.edit'),
      },
    ) as HTMLTextAreaElement;
    area
      ..addEventListener(
        'input',
        ((Event _) {
          _debounce?.cancel();
          _debounce = Timer(pause, () {
            edit.update(area.value);
            _refresh();
          });
        }).toJS,
      )
      ..addEventListener(
        'keydown',
        ((KeyboardEvent e) => _indent(e, area)).toJS,
      );
    return area;
  }

  /// Tab inserts two spaces instead of leaving the editor. Shift+Tab and
  /// Escape-then-Tab still move focus, so keyboard users are not trapped.
  static void _indent(KeyboardEvent e, HTMLTextAreaElement area) {
    if (e.key != 'Tab' || e.shiftKey) return;
    e.preventDefault();
    final start = area.selectionStart;
    area.setRangeText('  ', start, area.selectionEnd, 'end');
    area.dispatchEvent(Event('input'));
  }

  /// Redraws the issues and the game after the text changed.
  void _refresh() {
    setChildren(_issues, [
      if (edit.issues.isEmpty)
        el('li', cls: 'label ok', text: m('player.issues.ok'))
      else
        for (final issue in edit.issues)
          el(
            'li',
            cls: issue.error ? 'error' : 'warning',
            children: [
              el(
                'span',
                cls: 'label',
                text: m(
                  issue.error ? 'player.issue.error' : 'player.issue.warning',
                ),
              ),
              if (issue.code != null)
                el('span', cls: 'label code', text: issue.code),
              if (issue.where.isNotEmpty) el('code', text: issue.where),
              el('span', text: issue.message),
            ],
          ),
    ]);
    final game = edit.play;
    if (game == null) {
      _playPane.replaceChildren(
        el('p', cls: 'gb-cannot card', text: m('player.cannotPlay')),
      );
    } else {
      final host = el('div');
      _playPane.replaceChildren(host);
      PlayerView(host, game, m);
    }
  }

  void _download() {
    final blob = Blob(
      [edit.source.toJS].toJS,
      BlobPropertyBag(type: 'application/json'),
    );
    final url = URL.createObjectURL(blob);
    (el(
      'a',
      attrs: {'href': url, 'download': 'story.json'},
    ) as HTMLAnchorElement).click();
    URL.revokeObjectURL(url);
  }

  HTMLElement _openFile() {
    final input = el(
      'input',
      cls: 'gb-file',
      attrs: {'type': 'file', 'accept': '.json,application/json'},
    ) as HTMLInputElement;
    input.addEventListener(
      'change',
      ((Event _) {
        final file = input.files?.item(0);
        if (file == null) return;
        unawaited(
          file.text().toDart.then((text) {
            _textarea.value = text.toDart;
            edit.update(text.toDart);
            _refresh();
            _show(play: false);
          }),
        );
      }).toJS,
    );
    return el(
      'label',
      cls: 'btn btn-ghost',
      children: [
        el('span', text: m('player.open')),
        input,
      ],
    );
  }
}
