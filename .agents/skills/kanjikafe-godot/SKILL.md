---
name: kanjikafe-godot
description: KanjiKafe project conventions, Godot 4.4.1 GDScript standards, Japanese learning edutainment game
type: prompt
whenToUse: When writing, reviewing, or debugging GDScript code in the podcast_player Godot project
disableModelInvocation: false
---

# Agent Instructions — KanjiKafe

We are making a pixel-art, educaction game about learning Japanese.  The game will feature a variety of mini-games and activities that will help players learn Japanese in a fun and engaging way.  The game will be designed to focus on learning Kanji, and will include activities such as flashcards, quizzes, and mini-games that will help players learn the meanings and readings of Kanji characters, as well as learning other vocabulary.

---

## Coding Standards

- Target **Godot 4.4.1 GDScript** syntax exclusively.
- **Tabs** for indentation. Never spaces.
- Prefix every script with `extends`. Add `class_name` only where another script needs the type.
- `snake_case` for methods/variables, `PascalCase` for classes and node names.
- Wrap exported properties in `@export var` and onready lookups in `@onready var`.
- Godot does **not** support `?:` ternary syntax. Use `if/else`.
- GDScript does **not** support multi-line boolean expressions with `and`/`or` split across lines. Use single-line `if` or nested `if` blocks.
- The whole app is `main.tscn` + `main.gd` today. Split into scenes only when `main.gd` passes ~400 lines; single responsibility per scene after that.

---

## API Verification Guardrail

Before calling any method, signal, or property from another script, **always verify its exact signature** (name, argument count, argument types, return type) by reading the source file.

**class_name scope errors in editors:** When the GDScript Language Server reports "Could not find type X in current scope" for class_name types that are correctly declared, this is typically an LSP indexing issue — not a code error. Restart the GDScript language server or reopen the Godot editor. Do not refactor code to work around IDE-only scope errors.


---

## State & Data Rules

- `user://state.json` is the only state file. Schema changes must include a migration step for existing files (check keys, fill defaults on load).
- Episode identity is the RSS `<guid>`; fall back to enclosure URL only when guid is missing.
- Feed parsing handles `<item>`, `<title>`, `<enclosure url=...>`, `<pubDate>`, `<guid>`. Malformed items (no enclosure URL) are skipped, never fatal.
- Downloads: `user://downloads/<episode-guid>.mp3` (extension from enclosure URL). Check partial downloads (.part suffix) and resume or redownload.

---

## Documentation Standards

- Use Godot doc comments `##` for any function header you want editors/IDE to surface.
- Keep the top line the function signature (as a doc title): e.g. `## _on_feed_received()` then `##` blank line, then description lines.
- Keep dev TODOs as `# TODO:` lines so they're searchable.

---

## Tool Usage

- File read/write via the available file tools — use them for all code changes.
- Search via grep/glob equivalents, not manual directory traversal.
- Shell for PowerShell: running the Godot editor binary headless or launching scenes.
- Godot executable path (for reference): `C:\Users\danie\OneDrive\Documents\GODOT\Godot_v4.4.1-stable_win64.exe`
- **Never** run `taskkill` on Godot or mpv processes mid-write. Close via the app or OS APIs.

---

## Response Mode

- Keep sentences short and simple.
- No filler, no hype, no soft asks, no emojis, no conversational transitions. End when the content ends.
- Speak to the top of technical ability. Do not tone-match. Do not pad.
- Ask a question only when ambiguity would degrade the answer.
- Thinking partner, not a mirror. Tackle wrong premises first; correct with evidence before engaging further.
- Distinguish opinion from fact. Flag assumptions as assumptions.
- Agree when agreement is warranted. Do not manufacture a counterpoint to perform balance.
- No flattery.

---

## Project Context

- **Project Root**: [`c:\Users\danie\Documents\PoddyPodcaster`](C:\Users\danie\OneDrive\knajikafe) (adjust if moved)
- **Main Scene**: `title_scree.tscn` (root Control, UI built dynamically in `_build_ui()`)
- **Main Script**: `title_scree.gd` — feed fetch, episode list, playback, bookmarks, state
- **State**: `user://state.json`; **Config**: `user://config.json` (feed_url)
- **Reference**: gpodder/gpodder (Python) for RSS edge cases; mpv manual for player flags
