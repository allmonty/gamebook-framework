# Getting started

A gamebook is a story the reader plays: read a page, pick what to do, turn to the page your choice leads to. With the Gamebook Framework the whole book lives in **one text file**. You write the pages and the rules; any player app reads the file and runs the adventure.

You do not need to program. You need a text editor, about ten minutes, and the four rules below.

## Try it first

Below is a complete gamebook. It is two pages long. Press a choice to play it.

```gamebook
examples/01-getting-started/hello-world
```

Now open the **Edit JSON** tab. That text *is* the gamebook. Change the words after `"title":`, wait a moment, and go back to **Play**: your change is already in the game. Every example in this tutorial works the same way, so experiment freely; **Reset** brings the original back.

## JSON in four rules

The file is written in JSON, a common way to write data that both people and programs can read. You only need four rules:

1. **Text goes in double quotes**: `"Walk through the gate"`. Straight quotes `"`, not curly ones.
2. **Curly braces `{ }` hold named fields**, written `"name": value`. **Square brackets `[ ]` hold lists.**
3. **Commas go between items**, never after the last one.
4. **Numbers and `true` / `false` have no quotes**: `"schema": 1`, `"once": true`.

If you break a rule, the checker under the editor tells you where. Try it: delete a comma in the example and read the message. Then press Reset.

## What is in the file

Every story has the same few fields at the top:

| Field | What it is |
|---|---|
| `schema` | Which version of the format the story uses. Start with `1`; later chapters say when a feature needs a higher number. |
| `id` | A short name for the story, in lowercase letters, digits and dashes: `hello-world`. |
| `lang` | The language of this file: `en`, `pt`... |
| `title` | The title readers see. |
| `rules` | The game rules. `"preset": "fighting-fantasy"` gives you the classic Skill, Stamina and Luck. Chapter 4 explains rules in detail. |
| `start` | The id of the first page. |
| `nodes` | The pages. Each page has an id (`gate`, `city`) and its content. |

A page (a *node*) has `text`, and then exactly one way forward:

- `choices`: a list of buttons, each with the `text` to show and the page it goes `to`;
- an `ending`: `"victory"` or `"death"`;
- or a fight (chapter 6).

### Exercise

Add a third page. In the Edit JSON tab, change the `city` page so it offers a choice instead of ending:

```json
"city": {
  "text": "Lights, noise and a thousand stories.",
  "choices": [ { "text": "Find an inn", "to": "inn" } ]
},
"inn": { "text": "A warm bed. Yours starts tomorrow.", "ending": "victory" }
```

Mind the comma between `city` and `inn`. If the checker complains, read where it points.

## Writing on your own computer

When your story outgrows a page, write it in a file:

1. Install a code editor such as [Visual Studio Code](https://code.visualstudio.com/) (free). It colors JSON and shows mistakes as you type.
2. Make a folder for your game and save the story in it as `story.en.json` (`story.pt.json` for Portuguese, and so on).
3. Add this line right after the opening `{` to get suggestions and checks for every field while you type:
   ```json
   "$schema": "https://allmonty.github.io/gamebook-framework/schema/story.schema.json",
   ```
4. To play it, open the [playground](../play.html), press **Open file** and pick your story.

Next you will give the reader real decisions: several choices, dead ends, and more than one way to finish.
