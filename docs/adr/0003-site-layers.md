# 0003. Layer the site: application, presentation, content

Date: 2026-11-11. Status: accepted.

## Context
The site has three kinds of code: playing and editing stories, drawing them in the DOM, and building pages. Mixing them would make the play logic testable only in a browser.

## Decision
`site/lib/src/play/` (use cases + immutable view models, pure Dart), `site/lib/src/ui/` (thin DOM renderers), `site/lib/src/content/` (build-time content). Entry points only wire. Dependencies point inward; `test/layers_test.dart` enforces it by scanning imports. The rules table is in `AGENTS.md`.

## Why
Fast VM tests cover the logic; the browser code stays small enough to smoke-test; the build script never pulls in DOM code.

## Consequences
A little more ceremony (view models between engine and DOM). Interfaces are added only for a second implementation or a test seam, not upfront.
