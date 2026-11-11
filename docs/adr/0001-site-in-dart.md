# 0001. Build the website in Dart, without Flutter web or a framework

Date: 2026-11-11. Status: accepted.

## Context
The site must sell the framework and let visitors play and edit stories in the browser with the real rules. The reference engine is pure Dart (`engines/dart`).

## Decision
A plain Dart package, `site/`, that depends on `gamebook_engine` by path. Interactive parts use `package:web` and are compiled once with `dart compile js`. Pages are static HTML produced by a small build script.

## Why
- The browser runs the reference engine itself: no JS port that can drift from the spec, and the CI test that validates the examples is the same code that plays them.
- Flutter web was rejected: a multi-megabyte download and canvas-drawn text hurt first load, search engines and screen readers, which matter most on a selling page.
- Jaspr (a Dart web framework) was rejected: it brings a framework and code generation for a few static pages and one interactive widget.

## Consequences
We own a small build script and DOM code. If the site grows many interactive pages, revisit Jaspr.
