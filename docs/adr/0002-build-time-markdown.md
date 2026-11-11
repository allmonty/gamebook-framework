# 0002. Render the tutorial from Markdown at build time

Date: 2026-11-11. Status: accepted.

## Context
The tutorial is long prose in two languages, written by people who may not code, with playable examples inside.

## Decision
Chapters are Markdown in `site/content/{en,pt}/`. `tool/build.dart` renders them with `package:markdown` into static HTML. A fenced block with the language `gamebook` names an example (`examples/<chapter>/<name>`); the build replaces it with an embed holding that example's JSON for the page's language.

## Why
- Static HTML loads fast, is indexed and needs no JavaScript to read.
- Markdown is readable on GitHub and easy to edit for writers.
- Examples stay real files, so tests validate every one of them and their translations; nothing is copy-pasted into prose.

## Consequences
Previewing needs a build (`dart run tool/build.dart`), which takes seconds.
