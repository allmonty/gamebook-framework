# Step 01: Scaffold the site package

## Scope
`site/` Dart package with the layer folders (`lib/src/{play,ui,content}`), strict lints copied from the engine, `tool/build.dart` (template rendering, Markdown with `gamebook` blocks swapped for embeds, copy css/assets, compile `web/main.dart` to JS), base layout (header with EN/PT switch, footer), `css/site.css` with the design tokens, an empty home page, logo, `site/README.md` (build, preview, design tokens and signature pieces from the Stitch export, how to add an example or a chapter).

## Files
site/pubspec.yaml, site/analysis_options.yaml, site/lib/src/content/*, site/tool/build.dart, site/templates/layout.html, site/css/site.css, site/assets/logo.jpeg, site/web/main.dart, site/README.md

## Tests
content tests: a template renders with strings; a `gamebook` block becomes an embed with the example JSON; a missing example is an error naming the file. `layers_test.dart` scans imports.

## Done when
`dart run tool/build.dart` writes build/en/index.html and build/pt/index.html; checks green.

## Handoff notes
- `SiteBuilder` (`lib/src/content/site_builder.dart`) builds `build/index.html` (language picker), `build/<lang>/index.html`, and copies `css/` and `assets/`. Add pages in `_buildLanguage`; give each page a template in `templates/` and its text in `strings/*.json`.
- Embeds: `embedExamples(markdown, lookup)` is written and tested but not wired yet; step 10 wires chapters (render with `package:markdown`, `ExtensionSet.gitHubWeb`, after `embedExamples`).
- The layout loads `js/main.dart.js` (deferred); `web/main.dart` is empty until step 02.
- `pubspec.lock` is ignored repo-wide (root `.gitignore`), as for the engine.
- Logo is the app icon resized to 256px.
