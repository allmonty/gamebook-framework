# Step 14: A front door for people and AIs (docs + site)

It links what steps 11 to 13 made. Step 15 follows it. May take two commits (A: repo docs; B: what the site serves).

## Problem
Someone arriving cold, a person or an AI assistant asked "make me a gamebook with this", has to work out from a long README which of three different jobs they are doing and where each starts. `AGENTS.md` only covers changing this repository. The JSON Schema's `$id` is the bare file name, so there is no address to cite. The kit for chatbots is only reachable as a file in the repo.

## Commit A: the repo
- `README.md`, right after the opening example, a section "Start here" with three doors, each three or four lines and one command:
  1. **Write a game**: copy a starter (`starters/`), follow the tutorial, check with `validate_story`. With a chatbot: give it `spec/llm-kit.md`.
  2. **Put games in your app**: the Dart engine (`engines/dart/README.md`), the dependency snippet, the five-line play loop that README already has.
  3. **Write an engine in another language**: Part B of the spec, `spec/presets/`, the conformance suite, `engines/README.md`.
  Move nothing else; the long feature tour stays below.
- `AGENTS.md`, "Start here" table: the row "Write or change a story for someone" already points at `spec/llm-kit.md`; add `starters/` to it. (Step 15 is the last step; whoever finishes it should also replace the "Know what to do next" row and the "Plan protocol" pointer to `temp-plan/` (the folder is about to be deleted) with a line saying there is no open plan.)
- `llms.txt` at the repository root, in the usual shape (one H1, a one-paragraph summary in a blockquote, then H2 sections of `- [title](address): one line`): the kit, the spec, the schema, the presets, the changelog, the conformance README, the starters, the tutorial chapters, the engine README. Use the addresses the site will serve where it serves the file, GitHub addresses otherwise. It is a convention, not a standard every tool reads; it costs one small file.
- `spec/story.schema.json`: `$id` becomes the absolute address the site serves it at (below). `tools/check_schema.py` loads the file from disk, so nothing else changes; run it to be sure.
- A test that keeps this honest (in `site/test/`, next to `site_builder_test.dart`): every relative link in `README.md`, `AGENTS.md` and `llms.txt` points at a file that exists.

## Commit B: the site
The site is built by `site/lib/src/content/site_builder.dart` (it already copies `css` and `assets`) and deployed to GitHub Pages at `https://allmonty.github.io/gamebook-framework/`.
- The build also writes, at the site root: `llms.txt`, `llm-kit.md` (from `spec/`), `schema/story.schema.json`, `presets/*.json`. So each has a stable public address, and stories can use `"$schema": "https://allmonty.github.io/gamebook-framework/schema/story.schema.json"`.
- Update the `$schema` line in the tutorial (`site/content/{en,pt}/01-getting-started.md`) and in the starters to that address.
- Tutorial chapter 8 (`08-check-and-publish.md`, both languages) already mentions the kit as a file in the repo: link the served copy.
- `site/test/site_builder_test.dart`: the build output holds the four kinds of file.

The addresses only work once the owner enables Pages (see "Waiting on the owner" in the plan's README). Do not enable it yourself.

## Done when
From the README's first screen a reader can reach a starter, the tutorial, the kit, the engine and the conformance suite in one click each; the built site holds `llms.txt`, the kit, the schema and the presets; the link test is green.

## Handoff notes
(fill in)
