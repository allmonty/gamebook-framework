# Step 07b: A picture in an example (site)

Added 2026-11-11 at the owner's request, after step 07.

## Problem
No example ships an image or audio file (`site/README.md`, "Known shortcuts"), so:
- the tutorial's "Describe your pictures" section (step 07) can only show JSON, not a picture with its description;
- the player's image support, `imageAlt` included, is never exercised on a real page in the browser.

## Change
- **One picture**, original, for the `hall` page of `site/examples/02-pages-and-choices/two-doors`: a dark hall with two doors, in simple shapes. Small (a few KB), `.webp` or `.png`: the format plays only `.webp`, `.png` and `.jpg` (B14), so no SVG.
- **Made by a script kept next to it** (for example `site/tool/draw_hall.dart` or a short Python script), so anyone can regenerate or change the picture and where it came from is plain. No AI-generated art: its origin and licence would be unclear in a repo meant to be cited. Prefer a dependency already in the repo; don't add one for this.
- **Both example files** (`.en.json`, `.pt.json`) get `"schema": 8`, `"image"` and an `"imageAlt"` in their own language.
- **The build** (`site/lib/src/content/site_builder.dart`) copies media found under `site/examples/` into the output. The player resolves an example's image path against the example's folder, both in tutorial embeds (`embed.dart`, `web/main.dart`) and when an example opens in the playground.
- **Tests:** a build test that the file is copied; a browser test that the embedded example shows the `<img>` with the right `src` and `alt`. `examples_test.dart` keeps passing (it validates without a media root).
- **Docs:** remove the image half of the shortcut in `site/README.md` (audio stays); in chapter 2 replace "(The examples on this site have no pictures, to keep them short.)" in both languages.

## Checks
The usual ones for `site/`, plus `simulate_story` on the changed example and the schema check on `site/examples/`.

## Done when
The `two-doors` example shows its picture in the tutorial and in the playground, with its description as alt text, in both languages; checks green.

## Handoff notes
- The picture is `site/examples/02-pages-and-choices/images/hall.png` (480x270, 4 KB), drawn by `draw_hall.dart` next to it. The script uses no package, only `dart:io` (its compression) and its own PNG writer; run it from `site/` to redraw. PNG, not WebP: Dart has no WebP encoder without a package. The script checks its CRC-32 against the known IEND value before writing.
- `two-doors.en.json` and `.pt.json` are schema 8, with `image` and an `imageAlt` in each language. `validate_story --strict` finds the file; `simulate_story` reports nothing stuck.
- Build: `SiteBuilder` copies files under `examples/` whose type is a game media type, using the engine's list, which became public as `mediaTypes` in `package.dart`. JSON and the script are not copied.
- Player: `PlayerView` and `AudioOutput` take a `mediaBase` put in front of picture and sound paths; `LabView` passes it on. `web/main.dart` builds it from the page's `data-root` (now on `<body>` in `layout.html`) and the embed's `data-example` folder. Sounds use it too, so an example that ships audio works the same way.
- The playground has no "open an example" feature: it embeds `rusty-door` or opens a local file. So the tutorial and home embeds are the only places that need the folder; a local file keeps paths relative to the page.
- Tests: the build copies the picture and only media; a browser test checks that the lab's `<img>` has the folder-prefixed `src` and the `alt`. Checked by hand in headless Chrome: the picture shows in chapter 2's embed.
- Docs: chapter 2 in both languages points to the example's picture and matches its description; `site/README.md` keeps only the audio half of the shortcut.
- Done on the branch `step-07b-example-picture` from `main`.
