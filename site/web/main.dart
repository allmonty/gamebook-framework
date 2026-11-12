// Browser entry point: wiring only. Turns every example embed on the page
// into a lab (play + edit).
import 'dart:convert';
import 'dart:math';

import 'package:gamebook_site/src/play/edit_session.dart';
import 'package:gamebook_site/src/ui/dom.dart';
import 'package:gamebook_site/src/ui/lab_view.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:web/web.dart';

void main() {
  final messages = Messages(
    (jsonDecode(
      document.getElementById('gb-strings')?.textContent ?? '{}',
    ) as Map<String, Object?>).cast<String, String>(),
  );
  final embeds = document.querySelectorAll('.gb-embed');
  for (var i = 0; i < embeds.length; i++) {
    _mount(embeds.item(i)! as HTMLElement, messages);
  }
}

void _mount(HTMLElement embed, Messages messages) {
  final source = embed.querySelector('script[type="application/json"]');
  final host = el('div');
  embed.append(host);
  LabView(
    host,
    EditSession(_pretty(source?.textContent ?? ''), Random()),
    messages,
    canOpenFiles: embed.closest('.playground') != null,
    mediaBase: _exampleFolder(embed),
  );
}

/// An embedded example's media sit next to its story file (the build copies
/// them there): `examples/02-pages-and-choices/two-doors` gives
/// `<root>examples/02-pages-and-choices/`.
String _exampleFolder(HTMLElement embed) {
  final path = embed.getAttribute('data-example') ?? '';
  final slash = path.lastIndexOf('/');
  if (slash < 0) return '';
  return '${document.body?.getAttribute('data-root') ?? ''}'
      '${path.substring(0, slash + 1)}';
}

/// The build ships examples on one line; writers read them indented.
String _pretty(String json) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(json));
  } on FormatException {
    return json;
  }
}
