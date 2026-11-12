# Step 12: Tutorial 3: Items

## Scope
give/take/takeAll, `has`, usable items, bonuses, pack limit, offers and swaps, containers.

## Files
site/content, site/examples/03-*

## Tests
same

## Done when
same

## Handoff notes
- Chapter 3 with five examples in `examples/03-items/`: `locked-door` (declare, give, has, take), `healing-potion` (use, when, ceiling; schema 2), `rune-blade` (bonus and a `stat` condition with `gte`; schema 5), `full-pack` (capacity, `pickup: choose`, swap, container; schema 3), `the-thief` (auto pickup refusing an item, `takeAll`; schema 3).
- Stat effects (`add`) and `gte/lte/eq` are introduced briefly here; chapter 4 must explain stats properly (labels, presets, `set`, `limit`, quantities) without repeating the item parts.
- `once` is promised for chapter 7 (the key can be picked up again).
