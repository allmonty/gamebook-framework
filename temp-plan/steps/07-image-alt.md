# Step 07: Schema 8 and image alt text (feature)

## Problem
The format cannot describe a picture, so the site player renders every page image with `alt=""` (`site/lib/src/ui/player_view.dart` line 138) and a screen-reader user gets nothing.

## Part 1: open schema 8
- `supportedSchemas` in `engines/dart/lib/story.dart`.
- `spec/framework.md`: the "Schema versions" paragraph at the top of Part B and the `schema` row of B3.
- `spec/CHANGELOG.md`: a row for version 8 (later steps add to it).
- `spec/story.schema.json`: allow `8`.
- `engines/README.md` (versions 1-8), `engines/dart/README.md`, the "Status" section of `README.md`.
- `conformance/cases/invalid/needs-newer-schema.json` uses a version the engine does not know: make sure it is still above 8.

## Part 2: the fields (schema 8)
| Field | Where | Notes |
|---|---|---|
| `imageAlt` | node, item | optional non-empty string: what the picture shows, for players who cannot see it. Per language. Only allowed next to `image` (parse error otherwise). |
| `coverAlt` | top level | the same for `cover`. |

A player that shows the image gives this text to assistive technology; without it the image is treated as decoration. Translations may differ freely (it is text).

## Files
- Spec: B3 table, B5, B6 node table; a sentence in Part A.
- `engines/dart/lib/story.dart`: three model fields and their parsing; the gate (in `schema_gate.dart` after step 06).
- `engines/dart/test/story_test.dart`: parses; rejected without the image; rejected below schema 8.
- Cases: `conformance/cases/invalid/image-alt-needs-schema-8.json`, `invalid/image-alt-without-image.json`. No play case: it is presentation; add it to "Not covered" in `conformance/README.md`.
- Site: `imageAlt` on the page view model in `site/lib/src/play/views.dart`, filled in `play_session.dart` (next to `image:`, line 121), used by `player_view.dart` instead of `''`. A VM test in `site/test/play_session_test.dart`.
- Tutorial: a short section "Describe your pictures" in `site/content/en/02-pages-and-choices.md` and the `pt` twin, with the JSON shown inline. No example story: no image files ship with the examples (known shortcut in `roadmap/README.md`).
- `README.md` feature list; `spec/llm-kit.md` regenerated.

## Done when
A schema 8 story with `imageAlt` plays and the site passes it to the `<img>`; older engines' rule holds (schema 7 story using it is rejected); checks green.

## Handoff notes
(fill in)
