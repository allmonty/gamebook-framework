# Starter games

Complete game folders to copy and make your own, each in English and Portuguese. Each one is a folder laid out as the spec says ([B1](../spec/framework.md)): one `story.<lang>.json` per language, plus `images/` and `audio/` if you add them. Every story starts with `"$schema"`, so an editor that knows JSON Schema checks it as you type.

| Folder | What it is |
|---|---|
| [blank/](blank/) | The smallest valid game: the Fighting Fantasy preset, three pages, one ending. Start here for a story of your own. |
| [fighting-fantasy/](fighting-fantasy/) | *The Salt Mine*: the classic shape. A fight, a Luck test, Provisions you eat from your pack (a counted item), a door that needs a key, and all three endings: victory, death and defeat. |
| [custom-rules/](custom-rules/) | *The Archive at Night*: **no preset**. The story defines its own stats (Nerve and Wits), which one is health, and how fights work, then uses them in a check and a fight. Rules are data. |

Copy a folder, rename it (for example `games/my-story/`), change the `id` in every language to the same new slug, and write.

## Check it, see it, test it, pack it
Run these from `engines/dart` (after `dart pub get`):

```
dart run gamebook_engine:validate_story ../../starters/fighting-fantasy --strict          # errors and warnings, translations compared
dart run gamebook_engine:story_graph ../../starters/fighting-fantasy/story.en.json --mermaid   # the map of pages (or Graphviz DOT without --mermaid)
dart run gamebook_engine:simulate_story ../../starters/fighting-fantasy/story.en.json    # 1000 random games: no stuck or endless ones
dart run gamebook_engine:pack_game ../../starters/fighting-fantasy salt-mine.gamebook     # one file for the app (B14)
```

To write with a chatbot instead, give it [spec/llm-kit.md](../spec/llm-kit.md) and one of these stories as a model. The engine's tests check that every starter stays valid, plays without getting stuck, and packs.
