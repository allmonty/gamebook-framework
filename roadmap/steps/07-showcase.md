# Step 07: Showcase story: Escape from the Rune Vault

## Scope
~15-20 page cyberpunk-fantasy gamebook in EN and PT using the top features (see 00-site-plan.md, Home page item 2).

## Files
site/examples/showcase/rune-vault.{en,pt}.json

## Tests
examples test (strict validation, EN/PT twins match per the validator's translation check); a seeded, scripted playthrough reaches victory and another reaches death.

## Done when
Validated and playable.

## Handoff notes
- `site/examples/showcase/rune-vault.{en,pt}.json`, 15 pages, schema 7. Shows: hero name, a kit pick (shiv / stim / charm), FF preset with a 4th stat (Credits, `limit`), Portuguese stat labels, pack of 2 with `pickup: choose`, a bonus item (charm, rune blade), a usable stim (free in fights), a locked choice that needs the shiv, a skill check, Test your Luck with its luck cost, a 1d6 outcome table (death / credits / blade), a once-only search and a once-only shaft, revisit text (`visits`), a flag with conditional text, `{credits}` and `{name}`, two journal entries, two achievements (one hidden), a two-enemy fight with armor, flee and luck in fights, undo 3, victory and death.
- No music: the CLI validator fails on missing media and embeds have no media folder yet. If audio is wanted later, ship files under `examples/<chapter>/audio/`, copy them in the build and resolve paths against the example's folder.
- `test/examples_test.dart` checks every file under `examples/`: parses, rules resolve, `validateStory` reports nothing (not even warnings), EN and PT exist and `compareTranslations` finds no difference. `test/showcase_test.dart` plays a scripted victory and a death undone.
- The CLI validator only scans folders for `story.<lang>.json`; for site examples pass the files (`validate_story site/examples/*/*.json --strict`). The schema check: `python3 tools/check_schema.py site/examples/*/*.json`.
