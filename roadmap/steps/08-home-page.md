# Step 08: Home page

## Scope
Hero with phone mockup running the showcase, showcase section with Edit toggle, Rules-are-data, feature grid linking to chapters, comparison table (from spec/comparison.md, honest wording), tooling, footer. EN + PT strings.

## Files
site/templates/index.html, site/strings/{en,pt}.json, site/css/site.css

## Tests
strings test: every key exists in both languages and every `{{key}}` in templates resolves.

## Done when
Manual pass at 390px and 1280px.

## Handoff notes
- `templates/index.html`: hero with the showcase in a phone frame, showcase tags, "Rules are data" with the Rusty Door lab, nine capability cards (labelled with their spec sections), the comparison table (wording follows `spec/comparison.md`, including the trade-off), eight tooling cards, closing call to action. All text in `strings/{en,pt}.json` under `home.*`.
- The calls to action point at the playground. When the tutorial exists (step 10), add a "Writer's tutorial" button to the hero and the closing band, and link each capability card to its chapter.
- Phone check: a DevTools-protocol script emulating 390px reports no page overflow (the comparison table scrolls inside `.table-wrap` on purpose). Headless Chrome windows cannot be narrower than 500px, so plain `--window-size` screenshots are misleading.
- On phones the header nav wraps under the brand; acceptable for now.
