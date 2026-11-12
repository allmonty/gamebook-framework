# Step 15: A versions page on the site (docs + site)

Last step, after 07 to 10 so it covers schema 8, and after 14 so `llms.txt` exists.

## Owner's decision (2026-11-12, after step 10g)
There is one version now. The page lists **version 1 and its features**, and **explains versioning**: what `"schema"` is for, that versions only add, that an engine rejects a version it does not know, and how a later version will appear here. Where the rest of this step assumes several versions, follow this instead.

## Problem
An author has to write `"schema": N` in every story and needs to know which number a feature needs. Today that is only in `spec/CHANGELOG.md`: a terse table for engine writers, in English, on GitHub. The site never shows it, the Portuguese reader has nothing, and no page says "this is new".

## Change
A page "Versions" in both languages, one section per schema version, newest first. For each version: what an author can now do, in the tutorial's plain words, each feature linking to the chapter section that teaches it; and one line saying a story from an older version still works once its `schema` says the new number (versions only add).

- Content: `site/content/en/versions.md` and `site/content/pt/versions.md`, written by hand. One heading per version, in a fixed form the test can find (for example `## Schema 8`).
- It is **not** a tutorial chapter: `SiteBuilder` (`site/lib/src/content/site_builder.dart`) lists every `content/<lang>/*.md` as a chapter with previous and next links, so build this file as its own page (`<lang>/versions.html`, its own template in `site/templates/`, or the chapter template without the pager) and keep it out of the chapter list. Reuse `renderChapter` for the Markdown.
- Navigation: a "Versions" link in the footer and on the tutorial index, strings in `site/strings/{en,pt}.json`. On the home page, a short line "New in schema 8" linking to it, if it fits the layout without a new section.
- `spec/CHANGELOG.md` stays the exact record for engine writers (which fields, which spec sections). Add one line at its top pointing to the site page for authors, and one on the page pointing back.
- `llms.txt` (step 14): add the page.

## Keeping it true
The reason to do this properly is that a hand-written page goes stale. Tests in `site/test/` (VM, next to `chapter_test.dart`):
- both language files have a heading for **every** version in the engine's `supportedSchemas`, and none for a version that does not exist;
- both languages have the same headings in the same order;
- every link to a chapter resolves to a file that is built.

So the next schema bump fails the site's tests until the page says what is new, in both languages.

Then make it part of the routine:
- `AGENTS.md`, "Changing the format": add the versions page to the list of what a new version touches.
- `CONTRIBUTING.md`, "Spec changes": the same, next to the CHANGELOG line.

## Done when
`<lang>/versions.html` is built in English and Portuguese with schema 1 to 8, each feature linking to its chapter; removing a version's section from either file fails a test; checks green.

## Handoff notes
(fill in)
