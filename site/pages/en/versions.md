# Format versions

Every story says which version of the format it is written for, near the top of the file: `"schema": 1`. This page says what that number means and what each version lets you write.

## How versions work

- **Versions only add.** A later version brings new things you can write. Nothing that works in one version stops working in a later one: a story only has to say the newer number to use the new things.
- **Say the version you use.** A story that uses something a version added must say that version (or a later one) in `"schema"`. The checker tells you when the number is too low, and which line needs it.
- **An app plays only what it knows.** An app that does not know a story's version refuses it with a message, instead of playing it half right. Update the app to play the newer story.
- **New versions appear here**, newest first, with what they let you write and where the tutorial teaches it. Engine writers find the exact record in the [changelog](https://github.com/allmonty/gamebook-framework/blob/main/spec/CHANGELOG.md).

## Version 1

The first version, with everything the tutorial teaches. Write `"schema": 1`.

- **Pages and choices** ([chapter 2](tutorial/02-pages-and-choices.html)): pages joined by choices; victory, defeat and death endings; pictures, with descriptions for readers who cannot see them; choices locked by a condition, with your own reason; a page that sends the reader back where they came from.
- **Items** ([chapter 3](tutorial/03-items.html)): keys and locked doors; items the reader can use, in a story or in a fight; items that make the hero better; a pack with limited room, containers and offers; thieves and floods; things that come in numbers, with a cap.
- **Stats and the hero** ([chapter 4](tutorial/04-stats-and-hero.html)): rule presets or your own stats; ceilings, limits and stats that go below zero; prices that point at other stats; bonuses that depend on a condition; creating the hero with a name and picks.
- **Dice** ([chapter 5](tutorial/05-dice.html)): dice checks, Testing your Luck, random outcome tables.
- **Combat** ([chapter 6](tutorial/06-combat.html)): opposed fights and the d20 way; several enemies at once, armor and luck; results tables and duels; fights that end early; running that costs a round.
- **A living world** ([chapter 7](tutorial/07-living-world.html)): once-only choices and pages; flags and visits; text that changes, and numbers in text; the journal and achievements; music and sound; undo; rules on every page, for healing, poison and curses that wear off.
- **Check and publish** ([chapter 8](tutorial/08-check-and-publish.html)): page titles, notes, chapters and drafts; the checker; translations; one file to share a game.
