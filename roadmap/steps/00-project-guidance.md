# Step 00: Project guidance

## Scope
AGENTS.md, CLAUDE.md, this roadmap, ADRs 0001-0003; ignore `temp-theme/`.

## Files
AGENTS.md, CLAUDE.md, roadmap/, docs/adr/, .gitignore

## Tests
none (docs only); engine checks still green

## Done when
Another AI can open AGENTS.md and know what to do next.

## Handoff notes
Branch `site` was made from `origin/main` (engine supports schema 1-7) with the README features commit cherry-picked. The owner's design export is in `temp-theme/` (ignored by git): read `stitch_cyberpunk_fantasy_gamebook_platform/arcane_cyberpunk_codex/DESIGN.md` and the `*/screen.png` files in step 01 and copy the decisions into `site/README.md`. The app's look is documented in `../gamebook/docs/design-system.md` (sibling repo).
