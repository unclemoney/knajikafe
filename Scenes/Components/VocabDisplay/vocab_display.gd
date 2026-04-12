extends VBoxContainer
class_name VocabDisplay
## VocabDisplay
##
## Reusable component that displays a Japanese vocabulary word
## according to the player's display settings (show/hide kanji,
## furigana, romaji, english). Used across all mini-games.

## The main word text (kanji or kana).
@onready var main_label: Label = $MainLabel

## Furigana reading above/below kanji.
@onready var furigana_label: Label = $FuriganaLabel

## Romaji transliteration.
@onready var romaji_label: Label = $RomajiLabel

## English meaning.
@onready var english_label: Label = $EnglishLabel

## The word currently being displayed.
var _current_word: VocabWord = null


func _ready() -> void:
	# Start blank
	clear()


## Displays a word using the current profile's display settings.
## If override_settings is provided, it merges over profile settings.
func show_word(word: VocabWord, override_settings: Dictionary = {}) -> void:
	_current_word = word
	if word == null:
		clear()
		return

	var settings := _get_display_settings(override_settings)

	var show_kanji: bool = settings.get("show_kanji", true)
	var show_furigana: bool = settings.get("show_furigana", true)
	var show_romaji: bool = settings.get("show_romaji", false)
	var show_english: bool = settings.get("show_english", true)

	# Main label: show kanji if enabled and available, else kana
	if show_kanji and word.kanji != "":
		main_label.text = word.kanji
	elif word.hiragana != "":
		main_label.text = word.hiragana
	else:
		main_label.text = word.katakana
	main_label.visible = true

	# Furigana: only relevant when kanji is shown
	if show_furigana and show_kanji and word.kanji != "":
		if word.hiragana != "":
			furigana_label.text = word.hiragana
		else:
			furigana_label.text = word.katakana
		furigana_label.visible = true
	else:
		furigana_label.visible = false

	# Romaji
	if show_romaji and word.romaji != "":
		romaji_label.text = word.romaji
		romaji_label.visible = true
	else:
		romaji_label.visible = false

	# English
	if show_english:
		english_label.text = word.get_primary_meaning()
		english_label.visible = true
	else:
		english_label.visible = false


## Clears all labels.
func clear() -> void:
	_current_word = null
	main_label.text = ""
	furigana_label.text = ""
	furigana_label.visible = false
	romaji_label.text = ""
	romaji_label.visible = false
	english_label.text = ""
	english_label.visible = false


## Returns the current word.
func get_current_word() -> VocabWord:
	return _current_word


## Merges override settings with profile settings.
func _get_display_settings(overrides: Dictionary) -> Dictionary:
	var profile := GameController.current_profile
	var base := {}
	if profile:
		base = profile.settings.duplicate()
	else:
		base = {
			"show_kanji": true,
			"show_furigana": true,
			"show_romaji": false,
			"show_english": true,
		}
	for key in overrides:
		base[key] = overrides[key]
	return base
