# KanjiKafe ☕🐱

A pixel-art educational game set in a Japanese Cat Cafe where players learn Kanji and Japanese vocabulary through fun mini-games. Built with Godot Engine 4.4.

## Overview

KanjiKafe puts you inside a cozy cat cafe staffed by animated cat companions who help you learn Japanese. Walk up to different stations in the cafe to play mini-games that quiz you on vocabulary and kanji. An SM-2 spaced repetition system tracks what you know and schedules reviews for maximum retention. Earn XP, level up, unlock new cats, and decorate your cafe as you progress.

**Target Audience:** Beginner and early-intermediate Japanese learners.

## Features

### Activities (9 total)
| Game | Description | Station |
|------|-------------|---------|
| **Multiple Choice Quiz** | Pick the correct English meaning from 4 cards | Menu Board |
| **Flashcard Review** | Flip cards, self-rate with SM-2 quality ratings | Counter |
| **Kanji Matching** | Memory card game — match kanji to meanings | Table |
| **Typing Input** | Type readings using on-screen Hiragana/Katakana keyboard | Register |
| **Listening Lab** | Transcribe spoken vocabulary with kana or romaji; assisted attempts record Reading | Register |
| **Fill in the Blank** | Complete Japanese sentences with the correct word | Bookshelf |
| **Cat Cafe Orders** | Listen to Japanese orders and choose picture items | Kitchen |
| **Reading Shelf** | Read short N5/N4 passages and answer comprehension questions | Bookshelf |
| **Kanji Workshop** | Practice tracked N5/N4 kanji meanings, readings, and components | Table |

The **Study Notebook** is a non-scored Bookshelf reference with Japanese/romaji/English search, level/topic/study-state filters, examples, progress details, and pronunciation playback. Browsing never changes SRS cards or café rewards.

### Learning Content
- **N5 curriculum:** 800 vocabulary words with examples, 100 kanji, and 30 reading passages
- **N4 curriculum:** 700 vocabulary words with examples, 200 kanji, and 30 reading passages
- **Synthetic Japanese audio:** 1,500 word pronunciations and 20 café orders using Microsoft Haruka
- Organized by JLPT level and topic categories (food, greetings, cafe, verbs, etc.)
- New-card sessions can target N5, N4, or Mixed; due cards from every introduced level remain reviewable
- Topic selection, 0–10 new cards per session (zero means due-only), and Relaxed/Standard/Challenge presentation modes
- Difficulty changes distractors and the Orders timer only; it does not change SRS quality, XP, Beans, or assisted-attempt classification

These are curated JLPT-aligned study sets, not official or exhaustive JLPT coverage. Vocabulary, kanji, passages, and audio have explicit `draft_pending_human_review`, `needs_correction`, or `human_reviewed` states. The N4 set includes marked N3-source bridge characters (`source_level: 3`) as curriculum extensions; this is not a claim that they are official N4-only characters. Qualified Japanese content and pronunciation review is required before final v0.8 release labeling.

### Spaced Repetition (SM-2)
- Anki-style SM-2 algorithm tracks ease factor, interval, and repetitions per word
- Cards scheduled for review based on performance quality (0–5 scale)
- Due cards sorted by priority: overdue first, hardest first
- Persistent across sessions via per-profile save data

### Learning Progress
- Separate Meaning, Reading, Context, Listening, and Kanji Form evidence with attempts and success rates
- Independent tracked kanji cards; text-assisted orders/reading never count as Listening/Context
- New, Learning, Familiar, and Retained vocabulary stages derived from SM-2 outcomes
- N5, N4, and Mixed coverage, retention, topic breakdowns, and encountered-kanji exposure are reported separately
- Needs Practice and recent-session summaries use local evidence; no online analytics
- Legacy reviews retain their SM-2 values but are not relabeled as skill-specific evidence

### Progression System
- **XP & Levels** — earn XP per correct answer, with 15 level tiers
- **Daily Streaks** — consecutive day tracking with bonus XP multiplier
- **Achievements** — 26 badges for learning and café milestones
- **Cafe Decorations** — 16 visual customizations for the hub scene
- **Cat Collection** — 6 unique cats unlocked through progress

### Cat Companions
- Each cat has a unique name, personality, and specialty mini-game
- Cats react to correct/wrong answers with animations
- Mascot cat guides new players through onboarding
- Collectible cats unlocked at level/achievement milestones

### Configurable Display
- Toggle independently: Kanji, Furigana, Romaji, English
- Per-profile settings that persist across sessions
- Independent BGM, SFX, and Speech volume controls
- Configurable words-per-session count, curriculum level/topic, new-card limit, and difficulty

## Technical Details

### Engine & Platform
- **Engine:** Godot 4.4.1 (GDScript)
- **Base Resolution:** 640×360 (16:9, 3× scale to 1920×1080)
- **Renderer:** Forward Plus
- **Texture Filter:** Nearest (pixel-art crisp)
- **Platform:** Windows desktop (initially)

### Architecture

#### Autoload Singletons
| Singleton | Responsibility |
|-----------|---------------|
| `GameController` | Scene transitions (fade), current profile, game state, date utilities |
| `AudioManager` | BGM crossfade, SFX pool (8 channels), volume control |
| `SaveManager` | Profile CRUD, SRS data persistence, file I/O to `user://profiles/` |
| `SRSEngine` | SM-2 algorithm, card scheduling, due queue management |
| `VocabDatabase` | Loads/queries vocabulary (JSON) and kanji (Resource) data |

#### Custom Resource Types
| Resource | Purpose |
|----------|---------|
| `VocabWord` | Japanese word with kanji, readings, meanings, categories, examples |
| `KanjiEntry` | Single kanji character with readings, meanings, stroke count, radical |
| `PlayerProfile` | Player identity, XP, level, streaks, unlocks, settings dictionary |
| `SRSCard` | SM-2 tracking data per vocabulary word (ease, interval, reps, dates) |
| `CatCharacter` | Cat identity, personality, sprite, specialty game, dialogue lines |
| `AchievementDef` | Achievement definition with unlock condition and display data |
| `VocabList` | Container resource holding an array of VocabWord entries |
| `KanjiList` | Container resource holding an array of KanjiEntry entries |

#### Font
- **PixelMplus** — Japanese pixel font with full JIS Level 1 & 2 kanji coverage
- Sizes: 10px (small UI), 12px regular and bold (body text, headings)
- License: M+ FONT LICENSE (free for any use)
- Source: https://github.com/itouhiro/PixelMplus

### Project Structure
```
res://
├── Autoloads/                    # Singleton scripts (no class_name)
│   ├── game_controller.gd
│   ├── audio_manager.gd          # Procedural SFX + BGM (cafe/quiz/results)
│   ├── save_manager.gd
│   ├── srs_engine.gd
│   ├── vocab_database.gd
│   └── achievement_manager.gd    # Achievement tracking + unlock notifications
├── Scenes/
│   ├── TitleScreen/              # Animated logo, start button
│   │   ├── title_screen.tscn
│   │   └── title_screen.gd
│   ├── ProfileSelect/            # Profile management (create/load/delete)
│   │   ├── profile_select.tscn
│   │   └── profile_select.gd
│   ├── CafeHub/                  # Side-view cafe with clickable stations
│   │   ├── cafe_hub.tscn
│   │   ├── cafe_hub.gd
│   │   └── Cats/                 # Animated cat character system
│   │       ├── cafe_cat.tscn     # CafeCat CharacterBody2D scene
│   │       ├── cafe_cat.gd       # Physics, movement, animation, speech bubble
│   │       ├── cat_state_machine.gd  # FSM with 12 states, weighted transitions
│   │       └── cat_sprite_loader.gd  # Runtime SpriteFrames from sprite sheets
│   ├── MiniGames/
│   │   ├── mini_game_base.gd     # Abstract base class for all mini-games
│   │   ├── MultipleChoice/       # 4-answer quiz with SRS integration
│   │   │   ├── multiple_choice.tscn
│   │   │   └── multiple_choice.gd
│   │   ├── FlashcardReview/      # Flip cards, self-rate with SM-2
│   │   │   ├── flashcard_review.tscn
│   │   │   └── flashcard_review.gd
│   │   ├── KanjiMatching/        # Memory card matching (4×3 grid)
│   │   │   ├── kanji_matching.tscn
│   │   │   └── kanji_matching.gd
│   │   ├── FillInBlank/          # Sentence completion with 4 choices
│   │   │   ├── fill_in_blank.tscn
│   │   │   └── fill_in_blank.gd
│   │   ├── TypingInput/          # Type reading from English prompt
│   │   │   ├── typing_input.tscn
│   │   │   └── typing_input.gd
│   │   ├── CafeOrders/           # Timed cafe ordering game
│   │   └── ListeningLab/         # Audio-first vocabulary dictation
│   ├── StudyNotebook/            # Non-scored searchable curriculum reference
│   ├── Results/                  # Post-quiz summary with XP and accuracy
│   │   ├── results_screen.tscn
│   │   └── results_screen.gd
│   ├── Settings/                 # Display toggles, volume sliders
│   │   ├── settings.tscn
│   │   └── settings.gd
│   ├── Components/
│   │   ├── VocabDisplay/         # Reusable word display component
│   │   │   ├── vocab_display.tscn
│   │   │   └── vocab_display.gd
│   │   ├── LevelUpNotification/  # Animated level-up toast overlay
│   │   │   └── level_up_notification.gd
│   │   ├── AchievementPopup/     # Queue-based achievement popup
│   │   │   └── achievement_popup.gd
│   │   ├── KanaKeyboard/         # On-screen hiragana keyboard
│   │   └── JapaneseAnswerNormalizer/ # Shared kana/romaji answer normalization
│   ├── Tutorial/                 # First-time onboarding (Mochi guide)
│   │   ├── tutorial.tscn
│   │   └── tutorial.gd
│   └── Stats/                    # Progress overview, cat collection
├── Resources/
│   ├── vocab_word.gd             # VocabWord Resource class
│   ├── kanji_entry.gd            # KanjiEntry Resource class
│   ├── player_profile.gd         # PlayerProfile Resource class
│   ├── srs_card.gd               # SRSCard Resource class
│   ├── cat_character.gd          # CatCharacter Resource class
│   ├── achievement_def.gd        # AchievementDef Resource class
│   ├── vocab_list.gd             # VocabList container Resource class
│   ├── kanji_list.gd             # KanjiList container Resource class
│   ├── Vocabulary/
│   │   ├── n5_vocab.json         # 800 N5 vocabulary words (JSON)
│   │   ├── n4_vocab.json         # 700 N4 vocabulary words (JSON)
│   │   └── cafe_menu.json        # 20 illustrated café orders
│   ├── Kanji/
│   │   ├── n5_kanji.json         # 100 N5 kanji entries (JSON)
│   │   └── n4_kanji.json         # 200 N4 kanji/bridge entries (JSON)
│   ├── Reading/                  # 30 N5 + 30 N4 passages (JSON)
│   └── Audio/                    # 1,520-entry Japanese audio manifest
│   ├── Cats/                     # Per-cat .tres definitions
│   │   └── mochi.tres            # Mascot cat companion
│   └── Achievements/             # Achievement .tres definitions
├── Art/
│   ├── UI/                       # Buttons, panels, icons
│   ├── Cats/                     # Cat sprite sheets
│   ├── CafeHub/                  # Cafe background and props
│   ├── MiniGames/                # Game-specific art
│   └── Fonts/                    # PixelMplus TTF files + license
├── Audio/
│   ├── BGM/                      # Background music tracks
│   └── SFX/                      # Sound effects
├── Themes/
│   └── main_theme.tres           # Global Godot Theme resource
├── Tests/                        # Test scenes for verification
└── addons/
	├── TweenFX/                  # Juicy tween animation library
	└── gdai-mcp-plugin-godot/    # MCP integration for AI dev
```

### Save Data Layout
```
user://profiles/
├── player_name/
│   ├── profile.tres              # PlayerProfile resource
│   ├── srs_data.json             # Schema v3 vocabulary/kanji cards and sessions
│   └── srs_data_v1_backup.json   # Original legacy data, created during migration
└── another_player/
	├── profile.tres
	└── srs_data.json
```

Learning data uses `schema_version: 3` with `cards`, `kanji_cards`, and a maximum of 100 `sessions`. Legacy v1 arrays and v2 envelopes migrate automatically only after their original contents are backed up. Malformed or unsupported data blocks learning-data writes rather than being replaced by an empty deck.

## Setup

### Prerequisites
- **Godot Engine 4.4.1** — [Download](https://godotengine.org/download)
- Windows 10/11 (primary development platform)

### Getting Started
1. Clone this repository
2. Open the project in Godot 4.4.1
3. Ensure the following plugins are enabled in Project → Project Settings → Plugins:
   - TweenFX
   - GDAI MCP Plugin (optional, for AI-assisted development)
4. Run the project (F5) — it will launch the Title Screen

### Running Tests
Test scenes are located in `Tests/`. Run content validation and the headless suites from the project root:
```
python Tools/validate_content.py
python Tools/test_review_pipeline.py
godot --headless --path . res://Tests/data_layer_test.tscn -- --run-all
godot --headless --path . res://Tests/progress_metrics_test.tscn
godot --headless --path . res://Tests/v05_activities_test.tscn
godot --headless --path . res://Tests/v08_activities_test.tscn
godot --headless --path . res://Tests/cafe_progress_test.tscn
godot --headless --path . res://Tests/cat_state_machine_test.tscn
```
Replace `godot` with the installed Godot 4.4.1 executable path when it is not on `PATH`.

## Development Roadmap

### Phase 0: Project Foundation ✅
- [x] Configure project.godot (window size, stretch mode, pixel filtering)
- [x] Create folder structure (25 directories)
- [x] Define 6 core Resource classes (VocabWord, KanjiEntry, PlayerProfile, SRSCard, CatCharacter, AchievementDef)
- [x] Create 5 Autoload singletons with full implementations (GameController, AudioManager, SaveManager, SRSEngine, VocabDatabase)
- [x] Source and integrate CJK pixel font (PixelMplus — 10px, 12px regular, 12px bold)
- [x] Write comprehensive README.md

### Phase 1: Data Layer ✅
- [x] Create VocabList and KanjiList container Resource classes for typed .tres loading
- [x] Implement VocabDatabase loading from .tres files with query methods
- [x] Create initial 50-word N5 vocabulary set (greetings, food/drink, numbers, cafe, verbs, adjectives)
- [x] Implement SM-2 SRSEngine with review scheduling
- [x] Implement SaveManager with multi-profile support
- [x] Create data layer test scene (`Tests/data_layer_test.tscn`) to verify load/save/review cycle

### Phase 2: MVP Core Loop ✅
- [x] Title Screen scene (animated logo with fade-in, start button)
- [x] Profile Select scene (create/load/delete profiles, confirmation dialog)
- [x] Basic Cafe Hub scene (placeholder side-view, player info, 1 clickable quiz station, cat mascot)
- [x] Multiple Choice Quiz mini-game (4-answer grid, correct/wrong feedback, SRS reporting, XP calc)
- [x] Results Screen (accuracy %, XP earned, level-up detection, performance-based titles)
- [x] Scene transition flow (Title → Profile → Cafe → Quiz → Results → Cafe)
- [x] First cat mascot: Mochi (`Resources/Cats/mochi.tres`) with personality and dialogue lines
- [x] Fixed `VocabWord.get_display_text()` to handle katakana-only words
- [x] Added `session_data` dict to GameController for inter-scene data passing

### Phase 3: Progression & Settings ✅
- [x] XP & Level system (earn XP, level-up notifications with overlay, XP bar)
- [x] Streak system (consecutive days, bonus XP multiplier up to 1.5× over 30 days)
- [x] Settings scene (display toggles, volume sliders, words-per-session, live preview)
- [x] VocabDisplay reusable component (configurable Kanji/Furigana/Romaji/English)
- [x] AudioManager procedural SFX (correct/wrong/click/level-up placeholder tones)
- [x] Level-up notification overlay (animated toast via GameController)
- [x] Streak display in Cafe Hub and Results Screen

### Phase 4: Remaining Mini-Games ✅
- [x] Mini-game base framework (MiniGameBase class with shared session setup/finish/XP logic)
- [x] Refactored Multiple Choice to extend MiniGameBase
- [x] Flashcard Review (card flip, self-rate Again/Hard/Good/Easy → SM-2 quality)
- [x] Kanji Matching (4×3 memory card grid, match kanji to English meanings)
- [x] Fill in the Blank (sentence completion with 4 word choices, fallback format)
- [x] Typing Input (type hiragana/romaji reading from English prompt, skip option)
- [x] Cat Cafe Orders (timed ordering game — cat orders in Japanese, pick correct item)
- [x] All 7 stations wired in Cafe Hub (Quiz, Flashcards, Matching, Fill Blank, Typing, Orders, Settings)

### Phase 5: Interactive Cafe Hub ✅
- [x] Cafe background art (side-view interior with layered ColorRect wall, window, shelves, counter, floor)
- [x] Clickable stations for all 6 mini-games + settings
- [x] Cat characters — 6 cats with unique personalities, specialty games, and dialogue lines:
  - **Mochi** (default, MultipleChoice) — warm calico cafe owner
  - **Sushi** (Lv.3, KanjiMatching) — playful tuxedo, memory expert
  - **Matcha** (Lv.5, FlashcardReview) — serene green-eyed, patient study guide
  - **Sakura** (Lv.7, FillInBlank) — graceful reader, sentence puzzle lover
  - **Kinako** (Lv.10, TypingInput) — speedy orange tabby, typing champion
  - **Azuki** (Lv.12, CafeOrders) — chubby kitchen cat, food vocabulary master
- [x] Cat unlock system (level-based: auto-check on hub load, silhouettes for locked cats)
- [x] Cat collection screen (`Scenes/CatCollection/`) — browse all cats, view personality & dialogue
- [x] Cafe decoration system — 8 decorations across 5 slot types (wall, counter, table, window, floor)
- [x] Decoration shop screen (`Scenes/DecorationShop/`) — equip/unequip decorations per slot
- [x] Stats/Progress screen (`Scenes/Stats/`) — player overview, streak, review stats, cat & decoration counts
- [x] Navigation buttons (📊 Stats, 🐱 Cats, 🎨 Decorations) added to cafe hub top bar

### Phase 6: Polish & Content
- [x] Background music (lofi cafe ambiance, quiz upbeat, results gentle — all procedural)
- [x] Sound effects (correct/wrong, card flip, meows, achievement fanfare, streak — all procedural)
- [x] Achievement system (18 achievements with popup notifications, AchievementManager autoload)
- [x] Expand vocabulary to full N5 (120 words) + N4 (100 words)
- [x] On-screen kana keyboard polish (dakuten, handakuten, small kana toggles)
- [x] Scene transition and animation polish (TweenFX pop-in, shake, hop, tada, fade across all scenes)
- [x] Tutorial/onboarding flow (Mochi cat 10-step introduction, guided cafe tour)

### Phase 7: Animated Cat Characters
- [x] CafeCat CharacterBody2D with gravity, walk speed, directional movement
- [x] CatStateMachine FSM with 12 states: STANDING, IDLE, WALKING, SITTING (transition), SITTING_IDLE, LAYING_DOWN (transition), LAYING_DOWN_IDLE, WALKING_TO_JUMP, JUMPING, PLAYING, EATING, SLEEPING
- [x] Transition states (SITTING, LAYING_DOWN) play one animation loop then auto-advance to idle variant
- [x] Smart jump-to-furniture: cat walks to nearest platform (counter/shelf), then jumps up and forward to land on top
- [x] CatSpriteLoader builds SpriteFrames at runtime from per-cat sprite sheets (CAT_N_State.png)
- [x] Per-state animation FPS and loop settings (transition anims don't loop)
- [x] Weighted random state transitions with configurable durations
- [x] Speech bubble on click with random dialogue from CatCharacter data
- [x] Test scene (`Tests/cat_state_machine_test.tscn`) with state force buttons for each state

### Phase 8: Visual Foundation ✅
- [x] Pixel-art cafe, navigation icons, shared PixelMplus theme, and legible Japanese font
- [x] Eight textured decorations with save-compatible placement data
- [x] Furniture-aligned cat surfaces and repaired achievement resources/popups

### Phase 9: Learning Progress & N5 Content ✅
- [x] Versioned, backed-up learning-data migration and bounded session history
- [x] Meaning, Reading, and Context evidence with normalized mini-game reporting
- [x] Evidence-based Stats and Results, N5 curriculum filtering, and Needs Practice
- [x] 120 N5 examples and 100 JSON-based N5 kanji entries

### Café Progression
- Completed sessions award Coffee Beans for correct answers and session completion
- Three automatic daily goals: reviewed items, rotating skill focus, and activity variety
- Decoration ownership is separate from equipped state; purchases use level requirements plus Beans
- Cat bonds unlock dialogue at 10, 25, and 50 without affecting learning outcomes
- File-backed BGM/SFX with procedural fallback, true crossfades, and independent Speech volume

### Phase 10: Differentiated Activities & Listening ✅
- [x] Audio-first Café Orders with picture answers, replay, timer pausing, and assist classification
- [x] Reading Shelf with 30 passages and tracked Kanji Workshop with independent kanji SRS
- [x] Listening and Kanji Form evidence, schema-v3 migration, and station mode pickers
- [x] Cached word pronunciation, compact typing keyboard, and semantic distractors

### Phase 11: Café Progression & Rewards ✅
- [x] Coffee Beans, daily goals, purchase/equip separation, and eight new decorations
- [x] Bounded cat bonds and threshold dialogue with no gameplay-stat bonuses
- [x] File-backed audio with crossfade and independent BGM/SFX/Speech settings
- [x] Café-focused achievements and comprehensive reward/purchase tests

### Phase 12: Expanded N5/N4 Curriculum — Draft
- [x] 800 N5 and 700 N4 vocabulary entries with examples
- [x] 100 N5 and 200 N4 kanji entries, including marked bridge characters
- [x] 1,500 synthetic pronunciations, 20 café orders, and 30 N4 passages
- [x] Topic/level selection, due-only sessions, difficulty modes, and N5/N4/Mixed Stats
- [ ] Qualified Japanese content and pronunciation review
- [ ] Final v0.7 release labeling after review findings are resolved

### Phase 13: Trusted Content & Active Recall — Draft
- [x] Reviewer-owned vocabulary, kanji, reading, and audio workbooks with correction persistence
- [x] Listening Lab audio dictation with assisted evidence separation and shared answer normalization
- [x] Searchable Study Notebook with study-state filters, examples, progress, and pronunciation
- [x] Draft and strict reviewed-release validation
- [ ] Qualified approval of all v0.7/v0.8 content and pronunciation
- [ ] Final v0.8 release labeling after review findings are resolved

## Curriculum Sources and Licenses

The import uses [OpenJLPT](https://github.com/evanclan/OpenJLPT), [Bluskyo/JLPT_Vocabulary](https://github.com/Bluskyo/JLPT_Vocabulary), [elzup/jlpt-word-list](https://github.com/elzup/jlpt-word-list), and [AnchorI/jlpt-kanji-dictionary](https://github.com/AnchorI/jlpt-kanji-dictionary). Dictionary data comes from [JMdict/KANJIDIC2 by the EDRDG](https://www.edrdg.org/), with example sentences sourced through the imported data from [Tatoeba](https://tatoeba.org/). Review each linked source's license before redistribution. Imported source snapshots are under `Tools/content/source/`.

## Japanese Audio Workflow

Run `powershell -ExecutionPolicy Bypass -File Tools/gen_japanese_audio.ps1` on Windows with Microsoft Haruka and FFmpeg installed. The script generates 1,500 word clips and 20 café order clips, writes `Resources/Audio/japanese_audio_manifest.json`, and reuses clips whose source-text hash is unchanged. `Tools/gen_n5_audio.ps1` remains a compatibility wrapper. Audio is synthetic and has not received qualified pronunciation review; replace it with reviewed recordings when available. Reading passages are generated with `python Tools/gen_reading.py` and `python Tools/gen_n4_reading.py`. Run `python Tools/validate_content.py` after any content, menu, art, or audio change.

## Qualified Content Review Workflow

Review workbooks live in `Tools/content/review/` and cover all 1,500 vocabulary entries, 300 kanji, 60 passages, and 1,520 audio clips. They are local UTF-8 CSV files suitable for spreadsheet editing; no hosted service is required.

1. Run `python Tools/export_review_workbook.py` to create or refresh workbooks. Existing corrections and approvals are preserved. A changed audio source hash resets that clip to draft.
2. A qualified reviewer edits content fields and sets `review_status` to `human_reviewed` only after checking the row. Approval requires `reviewer` and `reviewed_at` (`YYYY-MM-DD`). Use `needs_correction` for unresolved findings.
3. Run `python Tools/apply_content_review.py`. Approved corrections and review metadata are applied by stable IDs. Draft/rejected rows do not overwrite generated content with unapproved edits.
4. Regenerate speech if reviewed readings or order text changed, then apply review metadata again:
   ```
   powershell -ExecutionPolicy Bypass -File Tools/gen_japanese_audio.ps1
   python Tools/apply_content_review.py
   ```
5. Run normal validation during development and strict validation for release:
   ```
   python Tools/validate_content.py
   python Tools/validate_content.py --require-reviewed
   python Tools/test_review_pipeline.py
   ```

After rerunning source importers/generators, rerun `apply_content_review.py` to restore approved corrections. Strict validation fails while any draft or rejected row remains. Automated generation and validation do not constitute qualified review.

## File-backed Audio

`AudioManager` loads `Audio/BGM/cafe.ogg`, `study.ogg`, and `results.ogg`, plus `correct.ogg`, `wrong.ogg`, `click.ogg`, `level_up.ogg`, `card_flip.ogg`, `achievement.ogg`, `streak.ogg`, and `cat_interact.ogg` under `Audio/SFX/`. Procedural audio remains the fallback for missing files. These media paths can be replaced by licensed recordings without code changes.

## Learning Content Data Best Practices

### Why JSON — Not .tres — For Vocabulary and Kanji

Godot 4.4 **automatically re-saves `.tres` resource files** when the project is opened in the editor. During this resave, the engine resets any `PackedStringArray` field that holds non-default data back to `[]` (the empty default). This silently destroys `english_meanings`, `categories`, and `example_sentences` on every `VocabWord` sub-resource, causing mini-games to display `???`, `""`, or `---` instead of actual content.

This issue was reproduced multiple times: `gen_vocab.py` would write valid `.tres` files, Godot would open the project, and within seconds all `PackedStringArray` values were gone. The `.tres` format is therefore **not safe for any vocabulary data that uses array-type fields**.

Vocabulary and kanji data are stored as **JSON files** in `Resources/Vocabulary/` and `Resources/Kanji/`. Godot does not import, resave, or modify `.json` files. `VocabDatabase` reads them at runtime and instantiates typed `VocabWord` and `KanjiEntry` objects. `KanjiEntry` also uses `PackedStringArray` fields, so it has the same `.tres` stripping risk.

### Vocabulary Update Workflow

Follow this exact workflow any time vocabulary words are added or changed:

1. **Update the source importer or manual supplements** — `Tools/import_openjlpt.py` builds the authoritative `Tools/content/*_words.py` modules. Preserve original IDs and draft-review markers; do not hand-edit generated JSON.
2. **Run the importer and generator** from the project root:
   ```
   python Tools/import_openjlpt.py
   python Tools/gen_vocab.py
   ```
   This writes `Resources/Vocabulary/n5_vocab.json` and `Resources/Vocabulary/n4_vocab.json`. The importer is idempotent and retains the original first 120 N5 and 100 N4 records.
3. **Verify the output** — check that `english_meanings` is populated in the first few entries:
   ```powershell
   python -c "import json; d=json.load(open('Resources/Vocabulary/n5_vocab.json',encoding='utf-8')); print(d[0]['id'], d[0]['english_meanings'])"
   ```
   Expected output: `n5_001 ['hello', 'good afternoon']`
4. **Do not open the JSON files in the Godot editor's built-in text editor** — it is safe, but unnecessary. Godot does not need to import them.
5. **Do not convert vocab back to `.tres`** — this will reintroduce the stripping bug.

### VocabWord Fields Reference

Each JSON entry must contain these keys (all strings unless noted):

| Key | Type | Example |
|-----|------|---------|
| `id` | string | `"n5_001"` |
| `kanji` | string | `"今日は"` (empty string if none) |
| `hiragana` | string | `"こんにちは"` |
| `katakana` | string | `"コンニチハ"` (empty string if none) |
| `romaji` | string | `"konnichiwa"` |
| `english_meanings` | array of strings | `["hello", "good afternoon"]` |
| `jlpt_level` | integer | `5` |
| `categories` | array of strings | `["greetings"]` |
| `example_sentences` | array of strings | `"Japanese|English"`; required for every word |
| `part_of_speech` | string | `"expression"` |
| `review_status` | string | Draft, needs-correction, or human-reviewed state from the review layer |
| `source_pos` | array of strings | Source dictionary part-of-speech tags, when available |

### JSON Encoding Rules

- The JSON files **must be UTF-8 without BOM**. `gen_vocab.py` uses `json.dump(..., ensure_ascii=False)` and opens files with `encoding='utf-8'`. Do not change this.
- **Never add a BOM** (`\xef\xbb\xbf`) to the JSON files — GDScript's `JSON.parse_string()` does not strip BOM and will fail to parse the file, silently loading zero words.
- If characters appear as `???` or boxes in-game after a vocab update, first check that the JSON files are valid UTF-8 (no BOM, no double-encoding) before investigating anywhere else.
- Kanji and hiragana are stored as literal Unicode characters in the JSON (e.g. `"今日は"`), not as escape sequences. This is intentional and correct.

### What NOT To Do

- **Do not store vocab data in `.tres` files** — Godot will strip `PackedStringArray` values.
- **Do not store vocab data in `.gd` constant arrays in VocabDatabase** — this bloats the autoload and is harder to maintain.
- **Do not add `@export var` arrays of VocabWord to any `.tres` sub_resource** — same stripping bug applies to any `PackedStringArray` or `Array[String]` field in a sub_resource exported to `.tres`.
- **Do not regenerate vocab by duplicating JSON entries by hand** — always use `gen_vocab.py` as the single source of truth.

### Kanji Update Workflow

Edit the authored N5 data in `Tools/gen_kanji.py` or the N4 importer in `Tools/import_openjlpt.py`, then run the importer as needed followed by `python Tools/gen_kanji.py`. The generator validates exactly 100 N5 and 200 N4 characters. N4 excludes N5 duplicates and marks bridge entries with `source_level: 3`; all N4 entries remain drafts pending human review. Do not hand-edit the JSON or convert these entries to `.tres`.

### Learning Stage Definitions

- **New:** no reviews.
- **Learning:** introduced but below the Familiar/Retained thresholds, including a recent lapse.
- **Familiar:** at least two SM-2 repetitions, a six-day interval, and 60% overall success.
- **Retained:** at least three SM-2 repetitions, a fourteen-day interval, and 80% overall success.

These are vocabulary-retention estimates, not certification or general Japanese proficiency. Kanji encountered measures exposure in introduced vocabulary, not kanji mastery.

---

## Coding Standards

- **Godot 4.4** GDScript syntax
- **Tabs** for indentation (never spaces)
- **snake_case** for methods/variables, **PascalCase** for classes/nodes
- `@export var` for inspector properties, `@onready var` for node references
- `##` doc comments for function headers and public API
- Autoload scripts do **not** have `class_name` declarations
- Always verify method signatures before cross-script calls

## License

TBD
