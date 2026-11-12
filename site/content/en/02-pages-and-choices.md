# Pages and choices

A gamebook is a web of pages joined by choices. This chapter is about drawing that web: how to write a page, how choices lead on, how the story ends, and how to keep a door shut until the reader has earned it.

## Branches and endings

```gamebook
examples/02-pages-and-choices/two-doors
```

Play it twice: once through each door. Then open **Edit JSON** and look at how it is built:

- **Four pages** in `nodes`: `hall`, `red`, `blue` and `roof`. The names are yours to choose; use letters, digits, `-` and `_`. Readers never see them.
- **Two ways to end.** `"ending": "death"` on `red`, `"ending": "victory"` on `roof`. A story may have as many endings of each kind as you like.
- **Going back is just another choice.** `blue` offers "Go back to the hall", which points `to` the `hall` page. Loops are fine.

A page must have exactly one way forward: a list of `choices`, an `ending`, or a fight. A page with none of them is an error, because the reader would be stuck.

### Paragraphs

Inside `text`, write `\n\n` (backslash, n, twice) to start a new paragraph. The hall page uses it. Line breaks you type in the file itself are not allowed inside quotes in JSON.

### Pictures

A page can show an image above its text:

```json
"hall": { "text": "...", "image": "images/hall.webp", "choices": [ ... ] }
```

The path is relative to the story's folder, so `images/hall.webp` sits next to `story.en.json`. `.webp`, `.png` and `.jpg` all work. The command-line validator tells you if the file is missing. (The examples on this site have no pictures, to keep them short.)

## Choices that wait

Some choices should only work once the reader has done something. Give the choice an `if` with a **condition**:

```gamebook
examples/02-pages-and-choices/the-terminal
```

Here the vault door is **locked** until you have read the terminal. `{ "visited": "terminal" }` is true once the reader has been on the `terminal` page.

A locked choice is shown greyed out, with the reason under it. By default the app writes the reason from the condition ("Needs: ..."); with `lockedText` you write it yourself, which reads better for page visits and secrets: "Locked. Maybe the terminal knows the code."

The third choice, the maintenance hatch, has `"hideIfLocked": true`: until its condition holds, the reader does not even see it. Use it for secrets; use greyed-out choices when you want the reader to know something is possible.

### Try it

1. Change the hatch's `hideIfLocked` to `false`. Now the secret is visible but locked.
2. Delete the `lockedText` line of the vault door (and the comma before it) and see the reason the app writes on its own.
3. Point a choice `to` a page that does not exist, like `"to": "nowhere"`. The checker names the exact choice: that is how you will find typos in long books.

## What you learned

| Field | On | Meaning |
|---|---|---|
| `text` | page, choice | What the reader sees. `\n\n` starts a paragraph. |
| `image` | page | A picture above the text. |
| `choices` | page | The buttons. |
| `to` | choice | The page the choice leads to. |
| `ending` | page | `"victory"` or `"death"`: the game is over. |
| `if` | choice | A condition; while it is false the choice is locked. |
| `lockedText` | choice | Your words for why it is locked. |
| `hideIfLocked` | choice | Hide it completely while locked. |

`visited` is the first of many conditions. Next, the reader starts carrying things.
