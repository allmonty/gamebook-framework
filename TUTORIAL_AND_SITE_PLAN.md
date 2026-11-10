# Plan & Proposal: Gamebook Framework Tutorial & Website

> **Status:** Proposal / Draft for future implementation  
> **Branch:** `readme-features-overview`

---

## 1. Executive Summary

This proposal outlines two major developer and creator experience initiatives for the Gamebook Framework:

1. **A Non-Technical Writer's Tutorial (`tutorial/`)**:
   - Two complete, parallel tracks in **English** (`tutorial/en/`) and **Portuguese** (`tutorial/pt/`).
   - Aimed at writers, game designers, and tabletop GMs with zero programming background.
   - Progressively builds a complete mini-adventure (*"Escape from Goblin Keep"*) across 8 bite-sized chapters.
   - Accompanied by verified, runnable example JSON files for every stage (`tutorial/examples/`).
   - Includes a *Writer's Cookbook* of copy-paste patterns for common interactive tropes (traps, merchants, secret doors, boss fights).

2. **The Framework Website & Showcase (`site/`)**:
   - A modern, high-converting landing / "selling" page that explains why the framework exists and how it compares to Twine, Ink, and ChoiceScript.
   - An interactive, in-browser gamebook simulator running stories live so visitors can immediately play and test mechanics directly on the page.
   - Rich, web-based documentation and interactive tutorials with an instant language switch (EN / PT-BR).

---

## 2. The Tutorial Structure (`tutorial/`)

### Proposed Directory Layout

```text
tutorial/
├── README.md                            # Hub linking to EN and PT versions
├── en/                                  # English Track
│   ├── 01-getting-started.md            # What you need & JSON in 2 minutes
│   ├── 02-your-first-branching-story.md # Pages, choices, and multiple endings
│   ├── 03-backpack-and-keys.md          # Items, locked doors, and usable potions
│   ├── 04-stats-and-dice-checks.md      # Presets (Fighting Fantasy), dice rolls, pass/fail
│   ├── 05-sword-and-shield-combat.md    # Setting up fights, enemies, and fleeing
│   ├── 06-a-living-world.md             # One-time clues, visit counts, flags, live text
│   ├── 07-checking-and-mapping.md       # Running the validator and story graph tool
│   ├── 08-audio-journal-and-polish.md   # Looping music, sfx, and journal entries
│   └── cookbook.md                      # Copy-paste recipes for common tropes
├── pt/                                  # Portuguese Track
│   ├── 01-primeiros-passos.md
│   ├── 02-sua-primeira-historia.md
│   ├── 03-mochila-e-chaves.md
│   ├── 04-atributos-e-dados.md
│   ├── 05-espada-e-escudo-combate.md
│   ├── 06-um-mundo-vivo.md
│   ├── 07-validacao-e-mapas.md
│   ├── 08-audio-diario-e-polimento.md
│   └── livro-de-receitas.md
└── examples/                            # Validated runnable story files
    ├── step-01-basic-story.en.json
    ├── step-01-basic-story.pt.json
    ├── step-02-locked-door.en.json
    ├── step-02-locked-door.pt.json
    ├── step-03-dice-check.en.json
    ├── step-03-dice-check.pt.json
    ├── step-04-combat.en.json
    ├── step-04-combat.pt.json
    ├── step-05-living-world.en.json
    ├── step-05-living-world.pt.json
    ├── complete-goblin-keep.en.json
    └── complete-goblin-keep.pt.json
```

### Chapter Breakdown & Learning Path

| # | Chapter Topic | What the Writer Learns | Story Progression |
|---|---|---|---|
| **01** | **Getting Started** | Text editors, file placement, and the 4 rules of JSON without technical jargon. | Setting up `story.en.json`. |
| **02** | **Your First Story** | Nodes (pages), choices (`to`), victory and death endings. | Starting cell, hall choice, pit trap death, exit ladder win. |
| **03** | **Backpack & Keys** | Defining items, `give`, `take`, locking choices with `if: { has }`, usable healing potions. | Finding an iron key to unlock the iron portcullis. |
| **04** | **Stats & Dice Checks** | Using `"preset": "fighting-fantasy"`, 2d6 skill checks, pass/fail routes, random outcome tables. | Jumping across a crumbling floor or slipping down. |
| **05** | **Combat** | Creating combat nodes, enemy stats, opposed rolls, win destination, and fleeing. | Fighting the Goblin Guard; escaping back to the hallway. |
| **06** | **A Living World** | Once-only choices (`once: true`), visit counters, story flags, and live numbers in text (`{gold}`). | Searching a chest once; greeting an NPC differently on visit 2. |
| **07** | **Checking & Mapping** | Running the CLI validator to catch typos and broken links; viewing visual story graphs. | Verifying the adventure is bug-free before release. |
| **08** | **Audio & Polish** | Background music (`music`), sound effects (`sound`), journal entries, hero naming. | Adding dungeon ambiance and an explorer clue log. |

### The Writer's Cookbook (`cookbook.md` / `livro-de-receitas.md`)
Quick copy-paste snippets for common interactive tropes:
1. **The Locked Chest**: Can only be searched once; requires a key or a lockpicking check.
2. **The Wandering Merchant**: Checks if you have enough gold, deducts coins, and gives gear.
3. **The Hidden Passage**: Only visible or passable if a stat is high enough, or on a second visit.
4. **Poison Gas Trap**: Continual damage on failed agility check.
5. **Multi-Stage Boss Battle**: Battle followed by narrative choice or fleeing.

---

## 3. The Framework Website (`site/`)

### Objectives
1. **Showcase & "Sell" the Framework**: Clearly articulate the advantages for writers and developers over alternatives.
2. **Playable Live Demo**: An embedded interactive phone simulator directly on the web page where anyone can test play a story without installing anything.
3. **Rich Online Documentation**: A modern, readable documentation hub with responsive typography, code copy buttons, and bilingual toggling.

### Proposed Architecture

```text
site/
├── index.html                           # Landing / Selling Page (bilingual)
├── tutorial.html                        # Web reader for the tutorial & docs
├── css/
│   ├── style.css                        # Modern typography, responsive layout, dark/light theme
│   └── player.css                       # Phone simulator styles
├── js/
│   ├── main.js                          # Language switcher (EN/PT) & UI interactions
│   └── mini-engine.js                   # Lightweight in-browser story engine for demo play
└── assets/                              # Screenshots, icons, demo art
```

### Key Sections of the Landing Page
- **Hero Banner**:
  - Catchy headline: *"Write Gamebooks. Play Anywhere."*
  - Interactive phone mockup on the right running a live playable sample (*The Rusty Door* or *Goblin Keep*).
  - Primary CTA: *Read the Writer's Guide* | Secondary CTA: *View on GitHub*.
- **The Value Proposition (Why Gamebook Framework?)**:
  - **Twine**: Twine outputs HTML files rather than structured game data, making it hard to build native mobile/desktop apps or integrate custom RPG mechanics.
  - **ChoiceScript**: Restrictive commercial licensing, custom programming syntax.
  - **Ink**: Requires scripting logic inside story text; Gamebook Framework treats rules, stats, and checks as pure, clean, inspectable data.
- **Interactive Feature Highlights**:
  - Tabbed cards showcasing inventory, combat, audio/journal, and static analysis tooling.
- **Zero-Dependency Static Design**:
  - Pure HTML5, modern CSS, and lightweight vanilla JS.
  - Ready for GitHub Pages, Netlify, or Vercel with zero build step required.

---

## 4. Next Steps for Implementation

When ready to implement:
1. Create `tutorial/examples/` and write the progressive JSON stories in EN and PT.
2. Author markdown files in `tutorial/en/` and `tutorial/pt/`.
3. Validate all example stories using `engines/dart/bin/validate_story.dart`.
4. Build `site/index.html` and `site/js/mini-engine.js` with the interactive live demo.
