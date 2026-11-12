# Step 02: Health at 0 is final (fix)

## Problem
Spec B4 says health at 0 is death "wherever that happens", but the engine only looks at health once the whole action is done. Confirmed: at Stamina 2, a choice with `stamina -5` leading to a page with `stamina +4` leaves the hero alive at 4. The same happens with `[-5, +4]` in one effect list.

## Rule to write (owner's decision)
**Once the health stat is 0, no further effect applies**, for the rest of that action and of the game. Everything else goes on as written so the result is the same in every engine:
- a check or table on the choice still rolls (it decides the target), but its `effects` do not apply;
- the target page is still entered (visited, visit counted, music and sound as usual), but its `effects` do not apply;
- the game then ends in death (B10 step 5).

The existing case `conformance/cases/play/death-at-zero-health.json` (dies on a choice effect, ends on page `b`) must stay valid unchanged.

## Files
- `spec/framework.md`: B4 (the `health` bullet), B9 ("Effects in a list apply in order" gets the exception), B10 step 5.
- `spec/CHANGELOG.md`: "Clarified without a version change".
- `engines/dart/lib/engine.dart`: a private `_dead` getter (`rules.health` stat at 0) and a guard at the top of the loop in `_applyEffects` and in `_applyCreation`. Nothing else: every effect goes through those two.
- `engines/dart/test/engine_test.dart`: failing-first tests.
- Cases in `conformance/cases/play/`: `death-is-final.json` (choice effect kills, target page would heal: death, Stamina 0, node is the target), `death-stops-effect-list.json` (`[-5, +4]` in one list), and one where the dying choice has a check: its dice are still consumed (the runner fails on unused dice).
- `spec/llm-kit.md`: regenerate.

## Done when
The three cases pass, the old death case passes unchanged, checks green.

## Handoff notes
- As planned: `_dead` in `engine.dart` (also used by `ending`) and a `break` at the top of the loops in `_applyEffects` and `_applyCreation`. `achieve` is an effect too, so it is also skipped after death.
- Tests: two engine tests (choice kills then the page would heal; `[-5, +4, set]` in one list) and one creation test (a pick at -20 then +5). All three fail without the fix. The creation one needs `Quantity.value(...)`, not a bare int, in `StatChange`.
- Cases: `death-is-final.json`, `death-stops-effect-list.json`, `death-check-still-rolls.json` (2d6 consumed, pass target entered). `death-at-zero-health.json` unchanged and still passes. The conformance README's coverage line mentions it.
- Done on the branch `step-02-death-is-final` from `main`.
