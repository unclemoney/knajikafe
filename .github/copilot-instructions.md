# Copilot Instructions
Dearest Copilot,

This project is game made with the Godot Engine, and it uses GitHub Copilot to assist with coding. Below are the instructions and guidelines for using Copilot effectively in this project.

We are making a pixel-art, educaction game about learning Japanese.  The game will feature a variety of mini-games and activities that will help players learn Japanese in a fun and engaging way.  The game will be designed to focus on learning Kanji, and will include activities such as flashcards, quizzes, and mini-games that will help players learn the meanings and readings of Kanji characters, as well as learning other vocabulary.

Testing will be done by creating simple test scenes that can be run in the editor.  These test scenes will be used to verify that the game logic is working as expected, and to ensure that the game is fun to play.


## Coding Standards
- Always target Godot 4.4 GDScript syntax.
- Use tabs for indentation—never spaces.
- Prefix every script with its extends and class_name.
- Follow snake_case for methods/vars, PascalCase for classes/nodes.
- Wrap exported properties in @export var and onready lookups in @onready var.
- Never emit inline parsing hacks—break declarations into separate var + assignment.
- Provide detailed steps for setting up complex scenes or systems in the Godot editor, when applicable.
- Godot does not support ternary operator syntax with the question mark ?: use if/else statements instead.
- GDScript doesn't support multi-line boolean expressions with and/or operators split across lines.  Use single line if statements or nested if statements instead.
- Review the code base to ensure consitency with existing variables, methods, and class names, and to follow proper syntax to ensure we do not introduce any parsing errors.
- Remember to add activation code for new features in game_controller.gd.
- Do not add class_name to scripts that are only used as Autoloads.
- Document all new features in the README.md file, including setup instructions and usage examples.
- Godot installation folder: "C:\Users\danie\OneDrive\Documents\GODOT\Godot_v4.4.1-stable_win64.exe".
- Update the README.md file to reflect any new features or changes made to the project structure.
- Autoload scripts should not have class_name declarations.
- When applicable be sure to use the godot-tools MCP server tools.

## Vocabulary Data Guardrail

Vocabulary word data is stored as **JSON files** (`Resources/Vocabulary/n5_vocab.json`, `n4_vocab.json`), NOT as `.tres` resources. This is a deliberate, permanent architectural decision, not a shortcut.

**Root cause of previous bugs:** Godot 4.4 re-saves `.tres` resource files on project open, silently stripping all `PackedStringArray` field values back to `[]`. This destroyed `english_meanings`, `categories`, and `example_sentences` on every VocabWord sub-resource, causing `???`, `""`, and `---` to appear throughout all mini-games.

**Rules to follow at all times:**
- **Never** suggest storing vocab word data (or any data with array-of-string fields) in `.tres` sub-resources.
- **Never** add a `PackedStringArray` or `Array[String]` field to a Resource that is saved as a `.tres` sub-resource — Godot will strip it.
- The single source of truth for vocabulary is **`Tools/gen_vocab.py`**. To add or update words, edit that file and re-run `python Tools/gen_vocab.py`.
- JSON files must be **UTF-8 without BOM**. `gen_vocab.py` already handles this. Do not add BOM or change the encoding.
- After regenerating vocab JSON, always verify with: `python -c "import json; d=json.load(open('Resources/Vocabulary/n5_vocab.json',encoding='utf-8')); print(d[0]['id'], d[0]['english_meanings'])"`
- `VocabDatabase` loads vocab at runtime via `FileAccess` + `JSON.parse_string()` and creates `VocabWord` instances in GDScript. Do not change it to use `ResourceLoader`.
- Kanji data (no `PackedStringArray` fields) may continue to use `.tres` safely.

## API Verification Guardrail
Before calling any method, signal, or property from another script, **always verify its exact signature** (name, argument count, argument types, return type) by reading the source file.  Common mistakes this prevents:
- Calling a method with the wrong number of arguments (e.g. `select_channel(channel)` when the method takes 0 args).
- Calling a method that doesn't exist (e.g. `PlayerEconomy.reset()` when the actual method is `reset_to_starting_money()`).
- Using the wrong property name or assuming a property exists without checking.

**class_name scope errors in VS Code:** When the GDScript Language Server reports "Could not find type X in current scope" for class_name types that are correctly declared, this is typically an LSP indexing issue—not a code error.  Godot's own `global_script_class_cache.cfg` (in `.godot/`) is the source of truth for registered class_names.  To resolve: restart the GDScript language server, or close and reopen the Godot editor to force a re-import.  Do not refactor code to work around IDE-only scope errors when the class_name declarations are valid.

## Documentation Standards
- Use Godot doc comments ## for any function header or documentation you want editors/IDE to surface.
- Keep the top line the function signature (as a doc title): e.g. ## _on_game_start() then ## blank line, then description lines.
- Put parameter descriptions only when the function's behavior depends on non-obvious args. Use _arg for unused signal params to avoid lint warnings.
- Use short “Notes” or “Side-effects” sections when the function interacts with other systems (UI, signals, economy, scene tree).
- Keep single responsibility per function; if a function needs long doc blocks (>8 lines), consider splitting it.
- For lifecycle functions (_ready, _process, _on_tree_exiting) state side-effects clearly (what they connect, what they start).
- For public API functions (used by other scripts), document the contract: inputs, outputs, error modes, and expected object types.
- Keep dev TODOs as # TODO: or ## TODO: lines so they’re searchable; prefer issue links for long tasks.


## Scene & Node Organization
- Single responsibility: each scene owns exactly one domain (UI, gameplay logic, effects).
- If at all possible, you should design scenes to have no dependencies.
- Reusable scenes should be self-contained and not rely on external nodes.
- Root Logic Node: keep your GameController at the scene root.
- Typed Paths: export NodePaths for everything you need from another scene, assign them in the inspector, and guard with get_node_or_null() in _ready().
- Avoid Global State when possible and use node trees and signals.

## Command Examples
- When suggesting search commands on Windows, do not use `grep`. 
Instead, use PowerShell's `Select-String` cmdlet. 
- Run a manual test: & "C:\Users\danie\OneDrive\Documents\GODOT\Godot_v4.4.1-stable_win64.exe" --path "c:\Users\danie\Documents\kanjikafe" Tests/MainTest.tscn
- NEVER run taskkill commands to close Godot.  This can corrupt the project files.