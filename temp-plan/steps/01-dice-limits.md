# Step 01: Limit dice size (fix)

## Problem
Dice notation has no upper limit. `Dice.parse('4000000000d6')` succeeds, the story validates, and rolling it loops four billion times: the engine hangs. Stories arrive from outside in `.gamebook` packages (spec B14), so this is a trust boundary.

## Rule to write (spec B8)
At most **100** dice, at most **1000** faces, and a modifier or a plain integer of at most **6 digits**. Anything larger is invalid notation.

## Files
- `spec/framework.md` B8: add the limits.
- `spec/CHANGELOG.md`: a sentence under "Clarified without a version change".
- `spec/story.schema.json`: the dice `pattern` (near line 156) with bounded digit counts.
- `engines/dart/lib/dice.dart`: bound the digit counts in `_pattern` and reject `count > 100` or `faces > 1000` in `Dice.parse`. It is the only entry point; `validate.dart` `_dice` and `Rules.resolve` already turn its `FormatException` into an error with the JSON path.
- `engines/dart/test/dice_test.dart`: the failing-first test.
- `conformance/cases/invalid/dice-too-many.json` (model: `bad-dice.json`).
- `spec/llm-kit.md`: regenerate.

## Done when
`101d6`, `1d1001` and `4000000000d6` are rejected at their JSON path; `100d1000+999999` still parses; checks green.

## Handoff notes
(fill in)
