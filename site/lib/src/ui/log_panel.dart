import 'package:web/web.dart';

import '../play/views.dart';
import 'dom.dart';
import 'wording.dart';

/// What the last action did, one telemetry line each.
HTMLElement logPanel(List<LogLine> log, Messages m) => el(
  'ul',
  cls: 'gb-log',
  children: [
    for (final line in log)
      el('li', cls: 'label ${line.tone.name}', text: logText(line, m)),
  ],
);

/// The journal and achievements, folded away.
HTMLElement journalPanel(PageView view, Messages m) => el(
  'details',
  cls: 'gb-pack gb-journal',
  children: [
    el(
      'summary',
      cls: 'label',
      text: m('player.journal', {'count': view.journal.length}),
    ),
    el(
      'ul',
      children: [
        for (final entry in view.journal)
          el(
            'li',
            cls: 'gb-item',
            children: [
              el(
                'div',
                children: [
                  el('strong', text: entry.title),
                  el('p', text: entry.text),
                ],
              ),
            ],
          ),
        for (final title in view.achievements)
          el(
            'li',
            cls: 'gb-item gb-achievement',
            children: [el('strong', text: '★ $title')],
          ),
      ],
    ),
  ],
);
