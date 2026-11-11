# Step 02: Player: pages, choices, stats, endings

## Scope
`PlaySession` (start with injected Random, rolled stats, choose) and view models (`PageView`, `ChoiceView` with unmet reasons, `HudView`, ending). DOM renderers for page text, choices (`[01] //` chamfered bars; locked ones greyed with their reason), HUD pills, ending card with restart.

## Files
site/lib/src/play/, site/lib/src/ui/, site/web/main.dart

## Tests
VM tests on PlaySession with conformance-style stories and seeded/scripted Random; one browser smoke test (`dart test -p chrome`) that renders a story and clicks a choice.

## Done when
A tiny story plays to an ending in the browser.

## Handoff notes
_(fill in when done: what was built, shortcuts taken, anything the next step must know)_
