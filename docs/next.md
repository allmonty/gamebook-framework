# What's next

The plan that built version 1 of the format is finished (its steps are in the git history up to the commit that deleted `temp-plan/`). An audit of the whole repository followed it, and its fixes are merged; the audit itself is in the git history (`docs/audit-2026-11-12.md`, deleted once carried out). This file holds what is left: the owner's to-do list, and ideas for later.

## Owner's to-do
Outward-facing, so only the owner does these. Tick them off here as they are done.

- [ ] **Try the site with the keyboard only**, and with a screen reader if one is at hand. The audit's fixes for these were checked by tests and screenshots, never by a person: every button shows where focus is, Esc then Tab leaves the story editor, a fight's rolls are spoken, the header does not cover the page on a phone.
- [ ] **Play the five newer starters through once** on the site's Starters page (*The Ash Road*, *The Clockmaker's Will*, *Market Day at Three Bridges*, *The Sunken Chapel*, *The Lighthouse Year*). They validate and survive random play, but nobody has read them as a reader does.
- [ ] **Check what Twine's editor does with a broken link**, then fix the comparison.
  - In Twine, link to a passage that does not exist and look at the story map. If it marks the link, the home page's "Checked before players see it" for Twine is "Partly", not "No": change `home.compare.twine3` in `site/strings/en.json` ("Partly: the editor marks broken links") and `pt.json` ("Em parte: o editor marca links quebrados"), and the Twine row of section 4 in `spec/comparison.md`.
- [ ] **Read Harlowe's license** in a browser (its repository refuses automated requests): <https://foss.heptapod.net/games/harlowe>. Write it in the Twine entry and the table of `spec/comparison.md`, and take it off section 7 ("Not verified").
- [ ] **Check the Fighting Fantasy rules in a book.** Every rule in `spec/comparison.md` section 3 comes from fan restatements. With a book in hand (the rules section at the front; *City of Thieves* for luck in a fight), confirm the stats, the combat round, Testing your Luck, escaping and Provisions, cite the book, and take the line off section 7.
- [ ] **Tag a release of version 1**, so stories, engines and articles can cite a fixed version.
  - Pick a name: the format version and the engine version differ (`format-v1` for the format, the pubspec `version` for the engine), or one tag such as `v1.0.0` for both.
  - `git tag -a <name> -m "Gamebook Framework, format version 1"` on `main`, `git push origin <name>`, then a GitHub release with short notes: what version 1 holds (link `spec/CHANGELOG.md` and the site's versions page), the starters, the kit.
  - Optional: serve the schema at a versioned address too (for example `schema/1/story.schema.json`), so a story can pin it even after version 2 exists.
- [ ] **Publish the Dart engine on pub.dev** (`engines/dart`, package `gamebook_engine`).
  - Check that the name `gamebook_engine` is free on pub.dev.
  - Add the files pub.dev needs in `engines/dart/`: a `LICENSE` (MIT) and a `CHANGELOG.md` for the package.
  - Remove `publish_to: none` from `pubspec.yaml`, and set `version` (now `0.5.0`) to the first public one.
  - The `llm_kit` executable reads `../../spec/` from the repo, so it cannot work from an installed package: take it out of `executables` (it can still run as `dart run bin/llm_kit.dart` in the repo).
  - `dart pub publish --dry-run`, fix what it reports, then `dart pub publish`.
  - Then change the README's "Put games in your app" door and the engine README to the pub.dev dependency (`gamebook_engine: ^<version>`).
- [ ] **Submit the JSON Schema to SchemaStore**, so editors check story files without a `"$schema"` line.
  - A pull request to [SchemaStore/schemastore](https://github.com/SchemaStore/schemastore) adding an entry to `src/api/json/catalog.json`: name "Gamebook Framework story", the schema address `https://allmonty.github.io/gamebook-framework/schema/story.schema.json`, and a `fileMatch` for story files (`story.*.json`; check it does not clash with other entries).
  - Follow their contributing guide (they may ask for test files: the starters work).

## Ideas for version 2
Candidates found while building version 1 (`spec/comparison.md` section 8 has the evidence). Each needs the owner's yes and a short example story before it is specified (`CONTRIBUTING.md`), and comes with a new `schema` version.

1. **Limits per kind of item**: Lone Wolf carries at most 2 weapons next to an 8-item backpack.
2. **Rules that count fight rounds**, not only pages (the owner's request): "the hex lasts 2 rounds", "poison bites each round". Rules on every page run on pages only.
3. **New check kinds**: advantage and disadvantage, dice pools.
4. **Conditional effects** (an effect that applies only if a condition holds) and **text emphasis**.

Tools, not format changes, which need no new version:

5. **Export to a printable book** of numbered, shuffled sections.
6. **The engine as a tool server (MCP) for AI assistants**: the assistant tells the story, the engine owns the dice and the state.

7. **Opening a `.gamebook` in the site's playground**, with the package's own pictures and sounds (`readPackage` already runs in a browser). Open question: whether a full player belongs on this site at all, or only in an app.

Never read closely, by the audit or since: the conformance cases one by one, and the prose of the site's example stories. Tests run every case and validate every example, so the risk is in the wording, not in whether they work.

Left out on purpose: a second engine in another language. The conformance suite is ready for one; it is a project of its own.
