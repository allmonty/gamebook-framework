# Step 03: Player: items, use, offers, containers

## Scope
Pack view (items, descriptions, bonuses, capacity `n/m`), use item (page and fight), offers (take, leave, swap when full), containers, takeAll.

## Files
site/lib/src/play/, site/lib/src/ui/

## Tests
VM tests for each action and view; smoke test uses an item.

## Done when
Conformance item/offer stories play correctly in the browser.

## Handoff notes
- `PlaySession.useItem`, `takeOffer({replacing})`, `leaveOffer`; `PageView.pack` (`PackView`: items, used/capacity, `full`) and `PageView.offer` (`OfferView`: item, `swapFrom` when full, `more`).
- While an offer is pending the session returns no choices (the engine would refuse them).
- UI: `ui/pack_panel.dart` holds `PackPanel` (a `<details>` list with Use buttons) and `OfferPanel` (Take / Leave / "Leave X" swap buttons). Item cards show bonuses and container room.
- `takeAll` and refused items need no UI of their own; step 04's event log will say what was lost or refused.
- Using an item in a fight works through the same `useItem`; step 04 must show the Use button inside the combat panel too (the pack panel already lists usable items, `usable` reflects fight vs page).
