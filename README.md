# KanjiKafe ☕🐱

A pixel-art educational game set in a Japanese Cat Cafe where players learn Kanji and Japanese vocabulary through fun mini-games. Built with Godot Engine 4.4.

## Overview

KanjiKafe puts you inside a cozy cat cafe staffed by animated cat companions who help you learn Japanese. Walk up to different stations in the cafe to play mini-games that quiz you on vocabulary and kanji. An SM-2 spaced repetition system tracks what you know and schedules reviews for maximum retention. Earn XP, level up, unlock new cats, and decorate your cafe as you progress.

**Target Audience:** Intermediate Japanese learners with some existing Kanji knowledge.

## Features

### Mini-Games (6 total)
| Game | Description | Station |
|------|-------------|---------|
| **Multiple Choice Quiz** | Pick the correct English meaning from 4 cards | Menu Board |
| **Flashcard Review** | Flip cards, self-rate with SM-2 quality ratings | Counter |
| **Kanji Matching** | Memory card game — match kanji to meanings | Table |
| **Typing Input** | Type readings using on-screen Hiragana/Katakana keyboard | Register |
| **Fill in the Blank** | Complete Japanese sentences with the correct word | Bookshelf |
| **Cat Cafe Orders** | Serve customers by matching Japanese orders to items | Kitchen |

### Vocabulary Database
- **JLPT N5** (~100 kanji, ~800 vocabulary words)
- **JLPT N4** (~200 kanji, ~700 vocabulary words)
- **Custom curated list** of high-frequency useful words
- Organized by both JLPT level and topic categories (food, greetings, cafe, verbs, etc.)

### Spaced Repetition (SM-2)
- Anki-style SM-2 algorithm tracks ease factor, interval, and repetitions per word
- Cards scheduled for review based on performance quality (0–5 scale)
- Due cards sorted by priority: overdue first, hardest first
- Persistent across sessions via per-profile save data

### Progression System
- **XP & Levels** — earn XP per correct answer, scale with difficulty, 15 level tiers
- **Daily Streaks** — consecutive day tracking with bonus XP multiplier
- **Achievements** — 15-20 badges for milestones (first quiz, 100 words, 7-day streak, etc.)
- **Cafe Decorations** — unlock visual customizations for the hub scene
- **Cat Collection** — 5-8 unique cats unlocked through progress

### Cat Companions
- Each cat has a unique name, personality, and specialty mini-game
- Cats react to correct/wrong answers with animations
- Mascot cat guides new players through onboarding
- Collectible cats unlocked at level/achievement milestones

### Configurable Display
- Toggle independently: Kanji, Furigana, Romaji, English
- Per-profile settings that persist across sessions
- Audio volume controls (BGM and SFX)
- Configurable words-per-session count

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
| `VocabDatabase` | Loads/queries vocabulary and kanji Resource data |

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
│   ├── audio_manager.gd
│   ├── save_manager.gd
│   ├── srs_engine.gd
│   └── vocab_database.gd
├── Scenes/
│   ├── TitleScreen/              # Animated logo, start button
│   │   ├── title_screen.tscn
│   │   └── title_screen.gd
│   ├── ProfileSelect/            # Profile management (create/load/delete)
│   │   ├── profile_select.tscn
│   │   └── profile_select.gd
│   ├── CafeHub/                  # Side-view cafe with clickable stations
│   │   ├── cafe_hub.tscn
│   │   └── cafe_hub.gd
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
│   │   └── CafeOrders/           # Timed cafe ordering game
│   │       ├── cafe_orders.tscn
│   │       └── cafe_orders.gd
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
│   │   └── LevelUpNotification/  # Animated level-up toast overlay
│   │       └── level_up_notification.gd
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
│   │   └── n5_vocab.tres         # 50 hand-curated N5 vocabulary words
│   ├── Kanji/                    # .tres kanji lists (n5, n4)
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
│   └── srs_data.json             # SRS card data (JSON for flexibility)
└── another_player/
    ├── profile.tres
    └── srs_data.json
```

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
Test scenes are located in `Tests/`. To run a specific test:
```
& "C:\Users\danie\OneDrive\Documents\GODOT\Godot_v4.4.1-stable_win64.exe" --path "c:\Users\danie\Documents\kanjikafe" Tests/MainTest.tscn
```

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
- [ ] Background music (lofi cafe ambiance, game tracks)
- [ ] Sound effects (correct/wrong, card flip, meows, UI clicks, fanfares)
- [ ] Achievement system (15-20 achievements with popup notifications)
- [ ] Expand vocabulary to full N5 + N4 + custom curated list
- [ ] On-screen keyboard polish (dakuten, handakuten, small kana toggles)
- [ ] Scene transition and animation polish (TweenFX throughout)
- [ ] Tutorial/onboarding flow (mascot cat introduction, guided first quiz)

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

