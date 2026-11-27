extends Node
## VocabDatabase (Autoload)
##
## Loads the professional lesson curriculum, separate legacy café content,
## and the existing kanji database. Runtime study content is JSON-backed.

var _words: Dictionary = {}
var _legacy_cafe_words: Dictionary = {}
var _kanji: Dictionary = {}
var _lessons: Dictionary = {}
var _grammar: Dictionary = {}
var _sentences: Dictionary = {}

var reading_passages: Array = []
var exercises: Array = []
var cafe_menu: Array = []


func _ready() -> void:
	_load_all_data()


func get_word_by_id(id: String) -> VocabWord:
	return _words.get(id) as VocabWord


func get_cafe_word_by_id(id: String) -> VocabWord:
	return _legacy_cafe_words.get(id) as VocabWord


func is_legacy_cafe_id(id: String) -> bool:
	return _legacy_cafe_words.has(id)


func get_words_by_jlpt(level: int) -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord and word.jlpt_level == level:
			results.append(word)
	return results


func get_words_by_lesson(lesson: int) -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord and lesson in word.lesson_ids:
			results.append(word)
	results.sort_custom(func(a: VocabWord, b: VocabWord) -> bool: return a.id < b.id)
	return results


func get_lessons() -> Array:
	var results := _lessons.values()
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["number"]) < int(b["number"]))
	return results


func get_lesson(number: int) -> Dictionary:
	return _lessons.get("lesson_%02d" % number, {})


func get_stages() -> PackedStringArray:
	var stages := PackedStringArray()
	for lesson in get_lessons():
		if lesson["stage"] not in stages:
			stages.append(lesson["stage"])
	return stages


func get_grammar_points(lesson: int = 0, query: String = "") -> Array:
	var results: Array = []
	var normalized_query := query.strip_edges().to_lower()
	for grammar in _grammar.values():
		if lesson > 0 and int(grammar["lesson"]) != lesson:
			continue
		if normalized_query != "":
			var searchable := (str(grammar["title"]) + " " + str(grammar["category"]) + " " + "\n".join(grammar["body_lines"])).to_lower()
			if normalized_query not in searchable:
				continue
		results.append(grammar)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["lesson"]) == int(b["lesson"]):
			if int(a["number"]) == int(b["number"]):
				return str(a["id"]) < str(b["id"])
			return int(a["number"]) < int(b["number"])
		return int(a["lesson"]) < int(b["lesson"])
	)
	return results


func get_grammar_by_id(grammar_id: String) -> Dictionary:
	return _grammar.get(grammar_id, {})


func get_sentences_for_word(word_id: String) -> Array:
	var results: Array = []
	for sentence in _sentences.values():
		if word_id in sentence.get("vocab_ids", []):
			results.append(sentence)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["lesson"]) == int(b["lesson"]):
			return int(a["source_line"]) < int(b["source_line"])
		return int(a["lesson"]) < int(b["lesson"])
	)
	return results


func get_exercises_for_word(word_id: String) -> Array:
	var results: Array = []
	for exercise in exercises:
		if exercise.get("target_vocab_id", "") == word_id:
			results.append(exercise)
	return results


func get_readings_for_lesson(lesson: int) -> Array:
	var results: Array = []
	for passage in reading_passages:
		if int(passage.get("lesson", 0)) == lesson:
			results.append(passage)
	return results


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


func word_matches_filters(word: VocabWord, filters: Dictionary) -> bool:
	if word == null or word.content_source != "professional_lesson":
		return false
	var lesson := int(filters.get("lesson", 0))
	if lesson > 0 and lesson not in word.lesson_ids:
		return false
	var first_lesson := int(filters.get("first_lesson", 0))
	if first_lesson > 0 and word.first_lesson != first_lesson:
		return false
	var level := int(filters.get("jlpt_level", 0))
	if level > 0 and word.jlpt_level != level:
		return false
	if filters.get("untagged_only", false) and word.jlpt_level != 0:
		return false
	var section: String = filters.get("source_section", "")
	if section != "" and section not in word.source_sections:
		return false
	if filters.get("require_meaning", false) and not word.has_meaning():
		return false
	if filters.get("require_examples", false) and word.example_sentences.is_empty():
		return false
	if filters.get("require_cloze", false):
		if word.example_sentences.is_empty() and get_exercises_for_word(word.id).is_empty():
			return false
	if filters.get("require_reading", false) and word.get_reading() == "":
		return false
	if filters.get("require_kanji", false) and word.kanji == "":
		return false
	if filters.get("require_audio", false):
		if word.get_reading() == "" or not AudioManager.has_speech("vocab:" + word.id):
			return false
	var part_of_speech: String = filters.get("part_of_speech", "")
	if part_of_speech != "" and word.part_of_speech != part_of_speech:
		return false
	return true


func get_all_words() -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	for word in _words.values():
		if word is VocabWord:
			results.append(word)
	return results


func get_word_count() -> int:
	return _words.size()


func get_kanji(character: String) -> KanjiEntry:
	return _kanji.get(character) as KanjiEntry


func get_kanji_by_jlpt(level: int) -> Array[KanjiEntry]:
	var results: Array[KanjiEntry] = []
	for entry in _kanji.values():
		if entry is KanjiEntry and entry.jlpt_level == level:
			results.append(entry)
	return results


func get_kanji_count() -> int:
	return _kanji.size()


func _load_all_data() -> void:
	_load_vocab_json("res://Resources/Curriculum/vocabulary.json", false)
	_load_vocab_json("res://Resources/Vocabulary/cafe_legacy_vocab.json", true)
	for path in ["res://Resources/Kanji/n5_kanji.json", "res://Resources/Kanji/n4_kanji.json"]:
		_load_kanji_json(path)
	for lesson in _load_json_array("res://Resources/Curriculum/lessons.json"):
		_lessons[lesson["id"]] = lesson
	for grammar in _load_json_array("res://Resources/Curriculum/grammar.json"):
		_grammar[grammar["id"]] = grammar
	for sentence in _load_json_array("res://Resources/Curriculum/sentences.json"):
		_sentences[sentence["id"]] = sentence
	reading_passages = _load_json_array("res://Resources/Curriculum/readings.json")
	exercises = _load_json_array("res://Resources/Curriculum/exercises.json")
	cafe_menu = _load_json_array("res://Resources/Vocabulary/cafe_menu.json")
	print("VocabDatabase: Loaded %d professional words, %d lessons, %d grammar points, %d kanji." % [_words.size(), _lessons.size(), _grammar.size(), _kanji.size()])


func _load_vocab_json(path: String, legacy_cafe: bool) -> void:
	for entry in _load_json_array(path):
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
		for meaning in entry.get("english_meanings", []):
			word.english_meanings.append(meaning)
		word.jlpt_level = int(entry.get("jlpt_level", 0))
		for category in entry.get("categories", []):
			word.categories.append(category)
		for sentence in entry.get("example_sentences", []):
			word.example_sentences.append(sentence)
		word.part_of_speech = entry.get("part_of_speech", "")
		for lesson in entry.get("lesson_ids", []):
			word.lesson_ids.append(int(lesson))
		word.first_lesson = int(entry.get("first_lesson", 0))
		word.stage = entry.get("stage", "")
		for section in entry.get("source_sections", []):
			word.source_sections.append(section)
		word.pitch = entry.get("pitch", "")
		word.origin = entry.get("origin", "")
		var raw_pos = entry.get("source_pos", "")
		word.source_pos = "、".join(raw_pos) if raw_pos is Array else str(raw_pos)
		word.source_file = entry.get("source_file", "")
		word.source_word = entry.get("source_word", "")
		word.source_reading = entry.get("source_reading", "")
		word.content_source = entry.get("content_source", "legacy_cafe" if legacy_cafe else "professional_lesson")
		var eligibility: Dictionary = entry.get("eligibility", {})
		word.reading_eligible = bool(eligibility.get("reading", true))
		word.meaning_eligible = bool(eligibility.get("meaning", true))
		word.japanese_eligible = bool(eligibility.get("japanese", true))
		if legacy_cafe:
			_legacy_cafe_words[word.id] = word
		else:
			_words[word.id] = word


func _load_kanji_json(path: String) -> void:
	for data in _load_json_array(path):
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
		push_warning("VocabDatabase: Missing content file %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("VocabDatabase: Could not open %s" % path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is not Array:
		push_warning("VocabDatabase: Expected Array in %s" % path)
		return []
	return parsed
