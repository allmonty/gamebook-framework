import 'dart:js_interop';

import 'package:web/web.dart';

/// Creates an element with optional classes, text, attributes and children.
/// Text always goes through `textContent`, so story text is never HTML.
HTMLElement el(
  String tag, {
  String? cls,
  String? text,
  Map<String, String> attrs = const {},
  List<Node> children = const [],
}) {
  final element = document.createElement(tag) as HTMLElement;
  if (cls != null) element.className = cls;
  if (text != null) element.textContent = text;
  for (final MapEntry(:key, :value) in attrs.entries) {
    element.setAttribute(key, value);
  }
  for (final child in children) {
    element.append(child);
  }
  return element;
}

/// Calls [action] when [element] is clicked; returns [element] for chaining.
HTMLElement onClick(HTMLElement element, void Function() action) {
  element.addEventListener('click', ((Event _) => action()).toJS);
  return element;
}

/// Replaces the children of [element] with [children].
void setChildren(HTMLElement element, List<Node> children) {
  element.textContent = '';
  for (final child in children) {
    element.append(child);
  }
}
