extends Node
## VocabDatabase (Autoload)
##
## Loads and queries the vocabulary and kanji databases.
## Vocab data is loaded from JSON files (immune to Godot .tres resave issues).
## Kanji data is still loaded from .tres Resource files.

## All loaded VocabWord resources, keyed by id.
var _words: Dictionary = {}

## All loaded KanjiEntry resources, keyed by character.
var _kanji: Dictionary = {}

## Paths to vocabulary JSON files to load on startup.
var _vocab_json_paths: PackedStringArray = [
	"res://Resources/Vocabulary/n5_vocab.json",
	"res://Resources/Vocabulary/n4_vocab.json",
]

## Paths to kanji resource files to load on startup.
var _kanji_paths: PackedStringArray = [
	"res://Resources/Kanji/n5_kanji.tres",
	"res://Resources/Kanji/n4_kanji.tres",
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


## Returns a random selection of words, excluding the given IDs.
## count: how many words to return. exclude: IDs to skip.
func get_random_words(count: int, exclude: PackedStringArray = []) -> Array[VocabWord]:
	var pool: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord and word.id not in exclude:
			pool.append(word)

	pool.shuffle()
	var result: Array[VocabWord] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result


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
	for path in _kanji_paths:
		_load_kanji_file(path)
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


## Loads a single kanji .tres file (expects a KanjiList resource).
func _load_kanji_file(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var resource = ResourceLoader.load(path)
	if resource == null:
		return
	if resource is KanjiList:
		for entry in resource.entries:
			if entry is KanjiEntry and entry.character != "":
				_kanji[entry.character] = entry
