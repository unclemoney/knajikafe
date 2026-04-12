extends Node
## VocabDatabase (Autoload)
##
## Loads and queries the vocabulary and kanji databases from Resource files.
## Registered as an autoload singleton.

## All loaded VocabWord resources, keyed by id.
var _words: Dictionary = {}

## All loaded KanjiEntry resources, keyed by character.
var _kanji: Dictionary = {}

## Paths to vocabulary resource files to load on startup.
var _vocab_paths: PackedStringArray = [
	"res://Resources/Vocabulary/n5_vocab.tres",
	"res://Resources/Vocabulary/n4_vocab.tres",
	"res://Resources/Vocabulary/custom_vocab.tres",
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


## Loads all vocabulary and kanji data from resource files.
func _load_all_data() -> void:
	for path in _vocab_paths:
		_load_vocab_file(path)
	for path in _kanji_paths:
		_load_kanji_file(path)
	print("VocabDatabase: Loaded %d words, %d kanji." % [_words.size(), _kanji.size()])


## Loads a single vocab .tres file (expects a VocabList resource).
func _load_vocab_file(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var resource = ResourceLoader.load(path)
	if resource == null:
		return
	if resource is VocabList:
		for word in resource.words:
			if word is VocabWord and word.id != "":
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
