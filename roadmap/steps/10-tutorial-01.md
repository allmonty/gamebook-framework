# Step 10: Tutorial 1: Getting started

## Scope
What a story file is, JSON in four rules, required fields, using the playground. EN + PT.

## Files
site/content/{en,pt}/01-*.md, site/examples/01-*/

## Tests
examples test covers the new files; every gamebook block resolves.

## Done when
Chapter builds and its examples play.

## Handoff notes
- Tutorial machinery: `content/chapter.dart` (`renderChapter`: title from the first `# `, `gamebook` blocks to embeds, `.md` links to `.html`). `SiteBuilder` writes `<lang>/tutorial/<slug>.html` for every `content/<lang>/*.md` (sorted by file name) with a sticky contents list and previous/next links, plus `tutorial/index.html`. Templates: `templates/tutorial.html`, `templates/tutorial-index.html`. Chapter HTML is inserted as a value, so `{{` in a chapter stays literal.
- Chapter files use the same name in every language (`01-getting-started.md` in `en/` and `pt/`); a test checks both languages have the same chapters.
- Header nav has Tutorial; the home hero and closing band start the tutorial.
- Chapter 1 teaches: what a story file is, the Play/Edit tabs, JSON in four rules, the top-level fields, a page's three ways forward, an exercise adding a page, and writing locally with VS Code and `$schema`.
- Every Portuguese example overrides the preset stat labels (`rules.stats.<id>.label`); keep doing it.
- Link to a chapter only once it exists; the pager already points forward.
- Prose styles are scoped to direct children of `.prose` so they do not restyle the embedded player.
