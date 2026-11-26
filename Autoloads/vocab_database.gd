extends Node
## VocabDatabase (Autoload)
##
## Loads and queries the vocabulary and kanji databases.
## Vocabulary and kanji data are loaded from JSON files to avoid
## Godot .tres resave issues with PackedStringArray fields.

## All loaded VocabWord resources, keyed by id.
var _words: Dictionary = {}

## All loaded KanjiEntry resources, keyed by character.
var _kanji: Dictionary = {}

var reading_passages: Array = []
var cafe_menu: Array = []

## Paths to vocabulary JSON files to load on startup.
var _vocab_json_paths: PackedStringArray = [
	"res://Resources/Vocabulary/n5_vocab.json",
	"res://Resources/Vocabulary/n4_vocab.json",
]

## Paths to kanji JSON files to load on startup.
var _kanji_json_paths: PackedStringArray = [
	"res://Resources/Kanji/n5_kanji.json",
]


func _ready() -> void:
	_load_all_data()


## Returns a VocabWord by its id, or null if not found.
func get_word_by_id(id: String) -> VocabWord:
	return _words.get(id) as VocabWord


## Returns all words matching a given JLPT level.
func get_words_by_jlpt(level: int) -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord and word.jlpt_level == level:
			results.append(word)
	return results


## Returns all words that have the given category.
func get_words_by_category(category: String) -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord and category in word.categories:
			results.append(word)
	return results


## Returns a random selection matching optional level/category/content filters.
func get_random_words(count: int, exclude: PackedStringArray = [], filters: Dictionary = {}) -> Array[VocabWord]:
	var pool: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord and word.id not in exclude and word_matches_filters(word, filters):
			pool.append(word)

	pool.shuffle()
	var result: Array[VocabWord] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result


## Returns whether a word matches the supplied content filters.
func word_matches_filters(word: VocabWord, filters: Dictionary) -> bool:
	var level := int(filters.get("jlpt_level", 0))
	if level > 0 and word.jlpt_level != level:
		return false
	var category: String = filters.get("category", "")
	if category != "" and category not in word.categories:
		return false
	var categories: Array = filters.get("categories", [])
	if not categories.is_empty():
		var matches_category := false
		for candidate in categories:
			if candidate in word.categories:
				matches_category = true
				break
		if not matches_category:
			return false
	if filters.get("require_examples", false) and word.example_sentences.is_empty():
		return false
	if filters.get("require_kanji", false) and word.kanji == "":
		return false
	return true


## Returns all loaded words as an array.
func get_all_words() -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord:
			results.append(word)
	return results


## Returns the total number of loaded words.
func get_word_count() -> int:
	return _words.size()


## Returns a KanjiEntry by its character, or null if not found.
func get_kanji(character: String) -> KanjiEntry:
	return _kanji.get(character) as KanjiEntry


## Returns all kanji matching a given JLPT level.
func get_kanji_by_jlpt(level: int) -> Array[KanjiEntry]:
	var results: Array[KanjiEntry] = []
	for entry in _kanji.values():
		if entry is KanjiEntry and entry.jlpt_level == level:
			results.append(entry)
	return results


## Returns the total number of loaded kanji.
func get_kanji_count() -> int:
	return _kanji.size()


## Loads all vocabulary and kanji data.
func _load_all_data() -> void:
	for path in _vocab_json_paths:
		_load_vocab_json(path)
	for path in _kanji_json_paths:
		_load_kanji_json(path)
	reading_passages = _load_json_array("res://Resources/Reading/n5_reading.json")
	cafe_menu = _load_json_array("res://Resources/Vocabulary/cafe_menu.json")
	print("VocabDatabase: Loaded %d words, %d kanji." % [_words.size(), _kanji.size()])


## Loads a single vocab JSON file and creates VocabWord instances.
func _load_vocab_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("VocabDatabase: Could not open %s" % path)
		return
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_warning("VocabDatabase: Failed to parse JSON in %s" % path)
		return
	if parsed is not Array:
		push_warning("VocabDatabase: Expected Array in %s" % path)
		return

	for entry in parsed:
		if entry is not Dictionary:
			continue
		var word_id: String = entry.get("id", "")
		if word_id == "":
			continue
		var word := VocabWord.new()
		word.id = word_id
		word.kanji = entry.get("kanji", "")
		word.hiragana = entry.get("hiragana", "")
		word.katakana = entry.get("katakana", "")
		word.romaji = entry.get("romaji", "")
		var meanings = entry.get("english_meanings", [])
		for m in meanings:
			word.english_meanings.append(m)
		word.jlpt_level = entry.get("jlpt_level", 0)
		var cats = entry.get("categories", [])
		for c in cats:
			word.categories.append(c)
		var sentences = entry.get("example_sentences", [])
		for s in sentences:
			word.example_sentences.append(s)
		word.part_of_speech = entry.get("part_of_speech", "")
		_words[word.id] = word


## Loads a single kanji JSON file and creates KanjiEntry resources.
func _load_kanji_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("VocabDatabase: Could not open %s" % path)
		return
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed is not Array:
		push_warning("VocabDatabase: Expected kanji Array in %s" % path)
		return
	for data in parsed:
		if data is not Dictionary:
			continue
		var character: String = data.get("character", "")
		if character == "":
			continue
		var entry := KanjiEntry.new()
		entry.character = character
		for meaning in data.get("meanings", []):
			entry.meanings.append(meaning)
		for reading in data.get("on_readings", []):
			entry.on_readings.append(reading)
		for reading in data.get("kun_readings", []):
			entry.kun_readings.append(reading)
		entry.stroke_count = data.get("stroke_count", 1)
		entry.jlpt_level = data.get("jlpt_level", 5)
		entry.radical = data.get("radical", "")
		for component in data.get("components", []):
			entry.components.append(component)
		_kanji[character] = entry


func get_menu_item(vocab_id: String) -> Dictionary:
	for item in cafe_menu:
		if item.get("vocab_id", "") == vocab_id:
			return item
	return {}


func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Array else []
