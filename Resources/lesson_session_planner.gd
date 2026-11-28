extends RefCounted
class_name LessonSessionPlanner


static func get_allowed_lessons(config: Dictionary) -> Array:
	var focus := LessonProgressManager.get_focus_lesson(config)
	var lessons: Array = []
	for lesson in range(1, focus + 1):
		lessons.append(lesson)
	return lessons


static func get_scope_words(config: Dictionary, filters: Dictionary = {}) -> Array[VocabWord]:
	var allowed := get_allowed_lessons(config)
	var scoped_filters := filters.duplicate(true)
	scoped_filters["allowed_lessons"] = allowed
	var results: Array[VocabWord] = []
	for word in VocabDatabase.get_all_words():
		if word.first_lesson in allowed and VocabDatabase.word_matches_filters(word, scoped_filters):
			results.append(word)
	return results


static func build_vocabulary_session(config: Dictionary, activity_filters: Dictionary, desired: int, new_limit: int, create_cards: bool = true, cards_override: Variant = null) -> Dictionary:
	var focus := LessonProgressManager.get_focus_lesson(config)
	var allowed := get_allowed_lessons(config)
	var filters := activity_filters.duplicate(true)
	filters["require_meaning"] = true
	filters["allowed_lessons"] = allowed
	var existing: Dictionary = {}
	var current_entries: Array = []
	var review_entries: Array = []
	var source_cards: Array = SRSEngine.cards if cards_override == null else cards_override
	for card in source_cards:
		existing[card.vocab_id] = true
		var word := VocabDatabase.get_word_by_id(card.vocab_id)
		if word == null or word.first_lesson not in allowed:
			continue
		if not VocabDatabase.word_matches_filters(word, filters):
			continue
		var entry := {"word": word, "card": card}
		if focus in word.lesson_ids:
			current_entries.append(entry)
		elif word.first_lesson < focus:
			review_entries.append(entry)
	current_entries.sort_custom(_compare_entries)
	review_entries.sort_custom(_compare_entries)
	var new_entries: Array = []
	if new_limit > 0:
		for word in VocabDatabase.get_words_by_lesson(focus):
			if not existing.has(word.id) and VocabDatabase.word_matches_filters(word, filters):
				new_entries.append({"word": word, "card": null})
		new_entries.shuffle()
	var result := {"cards": [], "words": [], "current_count": 0, "review_count": 0, "due": 0}
	var review_target := 0 if focus == 1 else int(round(float(desired) * 0.3))
	var current_target := desired - review_target
	var new_used := 0
	var current_index := 0
	while result["words"].size() < current_target and current_index < current_entries.size():
		_append_entry(result, current_entries[current_index])
		current_index += 1
	while result["words"].size() < current_target and new_used < mini(new_limit, new_entries.size()):
		_append_new_entry(result, new_entries[new_used], create_cards)
		new_used += 1
	var review_added := 0
	for entry in review_entries:
		if review_added >= review_target:
			break
		_append_entry(result, entry)
		review_added += 1
	while result["words"].size() < desired and current_index < current_entries.size():
		_append_entry(result, current_entries[current_index])
		current_index += 1
	while result["words"].size() < desired and new_used < mini(new_limit, new_entries.size()):
		_append_new_entry(result, new_entries[new_used], create_cards)
		new_used += 1
	return result


static func _append_entry(result: Dictionary, entry: Dictionary) -> void:
	result["words"].append(entry["word"])
	result["cards"].append(entry["card"])
	if entry["card"].is_due(GameController.get_current_date()):
		result["due"] += 1


static func _append_new_entry(result: Dictionary, entry: Dictionary, create_cards: bool) -> void:
	var word := entry["word"] as VocabWord
	var card: SRSCard = null
	if create_cards:
		var created := SRSEngine.add_new_cards(PackedStringArray([word.id]))
		if created.is_empty():
			return
		card = created[0]
	result["words"].append(word)
	result["cards"].append(card)
	result["current_count"] += 1


static func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	var today := GameController.get_current_date()
	var a_due: bool = a["card"].is_due(today)
	var b_due: bool = b["card"].is_due(today)
	if a_due != b_due:
		return a_due
	var a_card := a["card"] as SRSCard
	var b_card := b["card"] as SRSCard
	var a_rate := float(a_card.correct_reviews) / maxi(1, a_card.total_reviews)
	var b_rate := float(b_card.correct_reviews) / maxi(1, b_card.total_reviews)
	if a_rate != b_rate:
		return a_rate < b_rate
	return a_card.vocab_id < b_card.vocab_id


static func get_reading_passages(config: Dictionary, desired: int) -> Array:
	var focus := LessonProgressManager.get_focus_lesson(config)
	var passages: Array = []
	for passage in VocabDatabase.reading_passages:
		if int(passage.get("lesson", 0)) == focus:
			passages.append(passage)
	for lesson in range(focus - 1, 0, -1):
		for passage in VocabDatabase.reading_passages:
			if int(passage.get("lesson", 0)) == lesson:
				passages.append(passage)
	return passages.slice(0, mini(desired, passages.size()))


static func get_kanji_entries(config: Dictionary) -> Array[KanjiEntry]:
	var focus := LessonProgressManager.get_focus_lesson(config)
	var entries: Array[KanjiEntry] = []
	var used: Dictionary = {}
	for lesson in range(1, focus + 1):
		for word in VocabDatabase.get_words_by_lesson(lesson):
			for character in word.kanji:
				if used.has(character):
					continue
				var entry := VocabDatabase.get_kanji(character)
				if entry != null:
					used[character] = true
					entries.append(entry)
	return entries
