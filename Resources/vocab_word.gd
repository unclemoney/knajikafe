extends Resource
class_name VocabWord
## VocabWord
##
## A single Japanese vocabulary word with all associated data.
## Used by VocabDatabase for querying and by mini-games for display.

## Unique identifier for this word (e.g., "n5_001").
@export var id: String = ""

## The kanji representation (e.g., "食べる"). Empty if word has no kanji.
@export var kanji: String = ""

## Hiragana reading (e.g., "たべる").
@export var hiragana: String = ""

## Katakana reading if applicable (e.g., for loanwords).
@export var katakana: String = ""

## Romaji transliteration (e.g., "taberu").
@export var romaji: String = ""

## English meanings / translations.
@export var english_meanings: PackedStringArray = []

## JLPT level: 5 = N5 through 1 = N1, 0 = untagged.
@export_range(0, 5) var jlpt_level: int = 5

## Topic categories (e.g., "food", "greetings", "cafe", "verbs").
@export var categories: PackedStringArray = []

## Example sentences using this word. Format: "Japanese|English" per entry.
@export var example_sentences: PackedStringArray = []

## Part of speech (e.g., "noun", "verb", "adjective", "adverb").
@export var part_of_speech: String = ""

## Professional lesson numbers in which this word appears.
@export var lesson_ids: PackedInt32Array = []

## First professional lesson introducing this word.
@export var first_lesson: int = 0

## Professional course stage containing the first lesson.
@export var stage: String = ""

## Original vocabulary-table sections.
@export var source_sections: PackedStringArray = []

## Pitch-accent notation supplied by the lesson.
@export var pitch: String = ""

## Language of origin supplied by the lesson.
@export var origin: String = ""

## Unmodified professional part-of-speech notation.
@export var source_pos: String = ""

## Professional Markdown source file.
@export var source_file: String = ""

## Original headword used for sentence/exercise occurrence matching.
@export var source_word: String = ""

## Original reading used for identity and migration matching.
@export var source_reading: String = ""

## Content origin; official curriculum words use professional_lesson.
@export var content_source: String = "professional_lesson"

## Whether the runtime reading is reliable enough for typing and audio.
@export var reading_eligible: bool = true

## Whether the English meaning passed extraction reliability checks.
@export var meaning_eligible: bool = true

## Whether the headword is usable as Japanese study content.
@export var japanese_eligible: bool = true


## Returns the kana reading, preferring hiragana.
func get_reading() -> String:
	if not reading_eligible:
		return ""
	if hiragana != "":
		return hiragana
	return katakana


## Returns whether the professional source supplies an English meaning.
func has_meaning() -> bool:
	return not english_meanings.is_empty()


## Returns the primary display text — kanji if available, then hiragana, then katakana.
func get_display_text() -> String:
	if kanji != "":
		return kanji
	if hiragana != "":
		return hiragana
	return katakana


## Returns the first English meaning, or empty string.
func get_primary_meaning() -> String:
	if english_meanings.size() > 0:
		return english_meanings[0]
	return ""
