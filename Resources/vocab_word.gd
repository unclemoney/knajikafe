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

## JLPT level: 5 = N5, 4 = N4, 0 = custom/unclassified.
@export_range(0, 5) var jlpt_level: int = 5

## Topic categories (e.g., "food", "greetings", "cafe", "verbs").
@export var categories: PackedStringArray = []

## Example sentences using this word. Format: "Japanese|English" per entry.
@export var example_sentences: PackedStringArray = []

## Part of speech (e.g., "noun", "verb", "adjective", "adverb").
@export var part_of_speech: String = ""


## Returns the primary display text — kanji if available, else hiragana.
func get_display_text() -> String:
	if kanji != "":
		return kanji
	return hiragana


## Returns the first English meaning, or empty string.
func get_primary_meaning() -> String:
	if english_meanings.size() > 0:
		return english_meanings[0]
	return ""
