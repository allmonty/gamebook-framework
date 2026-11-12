# Step 18: Cookbook

## Scope
Recipes: locked chest, wandering merchant, hidden passage, poison trap, boss fight; each with its example.

## Files
site/content/{en,pt}/cookbook.md, site/examples/cookbook/

## Tests
same

## Done when
same

## Handoff notes
- `content/{en,pt}/cookbook.md` (sorts after the numbered chapters, so it is last in the contents) with five recipes in `examples/cookbook/`: `locked-chest` (key or check, once-only reward), `wandering-merchant` (buy/sell, `{gold}`), `hidden-passage` (`hideIfLocked` with `any` of a stat or visits), `poison-trap` (flag-driven twin choices with `hideIfLocked` for damage over time, an antidote that clears the flag), `boss-fight` (two phases, simultaneous with armor, a mercy choice, flee to death).
- Each recipe links the chapters that explain its pieces.
