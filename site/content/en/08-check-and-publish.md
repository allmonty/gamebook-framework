# Check and publish

A real gamebook has hundreds of pages. Somewhere a choice points at a page you renamed, an item is needed but never given, a flag is checked but never set. This chapter shows how the framework finds those mistakes for you, how to organise a long book, how to translate it and how to share it.

## The checker you have been using

Every example in this tutorial runs the same validator the command-line tools use. It reports two kinds of problems:

- **Errors** make a story unplayable: a choice to a page that does not exist, a missing field, a typo in a field name, bad dice. The story will not run until they are fixed.
- **Warnings** point at what is probably a mistake in a story that still plays. Each has a code:

| Code | When |
|---|---|
| `unreachable` | no path leads to the page from the start |
| `no-victory` | no victory ending can be reached |
| `required-never-given` | a choice needs an item nothing gives |
| `taken-never-given` / `usable-never-given` | an item is taken or usable, but never given |
| `flag-never-set` / `flag-never-checked` | a flag is checked but never set, or set but never checked |
| `journal-never-unlocked` / `never-earned` | a journal entry or achievement nothing unlocks |
| `return-without-call` | a page has a `return` but can be reached with no page to return to |
| `capacity-without-pack` | a container in a story whose pack has no limit |
| `draft` | a page is still marked as a draft |

Every message names the place in the file, like `nodes.door.choices[1].to`: the `door` page, its second choice (counting from 0), the `to` field.

### Try it

Use the example below. In Edit JSON:

1. Add a page nobody links to: `"attic": { "text": "Dust.", "ending": "death" },`. You get an `unreachable` warning.
2. Add `"if": { "flag": "brave" }` to a choice. You get `flag-never-set`.
3. Rename the `road` page to `path` but not the choice that leads to it. That is an error, and the game stops until it is fixed.

## Organising a long book

Some fields are for authors only. None of them changes how the story plays, except `showTitles`:

```gamebook
examples/08-check-and-publish/tidy-book
```

| Field | Where | Meaning |
|---|---|---|
| `title` | page | a short name for the page, shown by tools and, with `showTitles`, to readers as the page heading |
| `showTitles` | top level | `true` shows page titles to readers |
| `note` | page | a note to yourself; readers never see it |
| `chapters` | top level | `{ "act1": { "title": "Act 1: The village" } }`, in reading order |
| `chapter` | page | which chapter the page belongs to |
| `draft` | page | `true` marks an unfinished page: it may have no text and no way out yet, and it shows a warning until you finish it |

## The command-line tools

When your story lives in files, the reference engine's tools check and inspect it. They need [Dart](https://dart.dev/get-dart) installed and a copy of this repository; run them from `engines/dart`:

```
dart run gamebook_engine:validate_story path/to/my-game --strict
dart run gamebook_engine:story_graph path/to/story.en.json --mermaid
dart run gamebook_engine:simulate_story path/to/story.en.json --games 2000
```

- **validate_story** checks every `story.<lang>.json` in a folder, and compares translations. `--strict` fails on warnings too. `--llm` words the problems as a message to paste back to an AI assistant that wrote the story.
- **story_graph** prints the story as a map: Graphviz DOT by default, or Mermaid, which GitHub and many editors draw for you.
- **simulate_story** plays the story thousands of times at random and reports dead ends, loops and endings nobody reaches.

## Translations

Each language is its own file, side by side: `story.en.json`, `story.pt.json`. They share the same `id`, and must have the same page ids, items, stats, flags and chapters, the same number of choices on each page in the same order, and the same number of text parts. Only the words change. The validator compares every translation with the first language and warns about any difference (`translation-missing`, `translation-choices`...). Every example on this site exists in English and Portuguese, checked this way.

Remember to translate stat labels in `rules.stats` when you use a preset (chapter 4).

## Sharing your game

- **A `.gamebook` package** is a zip of the game folder: the story files and the `images/` and `audio/` they use. Make one with `dart run gamebook_engine:pack_game path/to/my-game`; players that support packages import that single file.
- **From Twine**: `dart run gamebook_engine:import_twine story.twee out-folder` converts a Twine story (`.twee` or published `.html`) and reports what it could not convert.
- **With an AI assistant**: [the LLM kit](../../llm-kit.md) (`spec/llm-kit.md` in the repository) is one file that teaches a chatbot the format. Give it to the assistant with your request; then run the validator with `--llm` and paste its answer back until the story is clean.
- **On any platform**: the format is plain data, so engines can exist in any language. The [conformance suite](https://github.com/allmonty/gamebook-framework/tree/main/conformance) holds test cases that make sure every engine plays every story the same way.

## Where to go next

- The [cookbook](cookbook.md) has ready-made recipes: a locked chest, a merchant, a hidden passage, a poison trap, a boss fight.
- The [full specification](https://github.com/allmonty/gamebook-framework/blob/main/spec/framework.md) lists every field precisely.
- The [playground](../play.html) is ready for your first real story.
