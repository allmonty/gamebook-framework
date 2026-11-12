# Step 15: A versions page on the site (docs + site)

Last step, after 14 so `llms.txt` exists.

## Owner's decision (2026-11-12, after step 10g)
There is one version now. The page lists **version 1 and its features**, and **explains versioning**: what `"schema"` is for, that versions only add, that an engine rejects a version it does not know, and how a later version will appear here.

## Problem
An author writes `"schema": 1` in every story without being told why, and nothing on the site says what version 1 holds, or what will happen when a version 2 comes. That is only in `spec/CHANGELOG.md`: a terse table for engine writers, in English, on GitHub. The Portuguese reader has nothing.

## Change
A page "Versions" in both languages:
- **What a version is**, in the tutorial's plain words: every story says which version of the format it is written for in `"schema"`; versions only add, so a story keeps working in every later version once its `schema` says so; an app rejects a version it does not know rather than half-playing it; new versions will be listed here, newest first, with what each lets an author do.
- **Version 1**, under a heading in a fixed form the test can find (for example `## Version 1`): what an author can do with it, as a short list grouped like the tutorial (pages and choices, items, stats and the hero, dice, combat, a living world, checking and publishing), each feature linking to the chapter section that teaches it.

- Content: `site/content/en/versions.md` and `site/content/pt/versions.md`, written by hand.
- It is **not** a tutorial chapter: `SiteBuilder` (`site/lib/src/content/site_builder.dart`) lists every `content/<lang>/*.md` as a chapter with previous and next links, so build this file as its own page (`<lang>/versions.html`, its own template in `site/templates/`, or the chapter template without the pager) and keep it out of the chapter list. Reuse `renderChapter` for the Markdown.
- Navigation: a "Versions" link in the footer and on the tutorial index, strings in `site/strings/{en,pt}.json`.
- `spec/CHANGELOG.md` stays the exact record for engine writers. Add one line at its top pointing to the site page for authors, and one on the page pointing back.
- `llms.txt` (step 14): add the page.

## Keeping it true
A hand-written page goes stale. Tests in `site/test/` (VM, next to `chapter_test.dart`):
- both language files have a heading for **every** version in the engine's `supportedSchemas`, and none for a version that does not exist;
- both languages have the same headings in the same order;
- every link to a chapter resolves to a file that is built.

So version 2 fails the site's tests until the page says what is new, in both languages.

Then make it part of the routine:
- `AGENTS.md`, "Changing the format": add the versions page to the list of what a new version touches.
- `CONTRIBUTING.md`, "Spec changes": the same, next to the CHANGELOG line.

## Done when
`<lang>/versions.html` is built in English and Portuguese, explaining versioning and listing version 1's features, each linking to its chapter; removing the version 1 section from either file, or adding a version to the engine without a section, fails a test; checks green.

## Handoff notes
(fill in)
