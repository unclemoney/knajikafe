extends RefCounted
class_name StudyPlanner


static func get_recommendation() -> Dictionary:
	var profile := GameController.current_profile
	if profile == null:
		return {}
	return recommend(profile, SRSEngine.cards, SRSEngine.kanji_cards, SRSEngine.sessions)


static func recommend(profile: PlayerProfile, cards: Array[SRSCard], kanji_cards: Array[KanjiCard], sessions: Array) -> Dictionary:
	var level := int(profile.settings.get("target_jlpt_level", 0))
	var lesson := LessonProgressManager.get_current_lesson(profile)
	var new_limit := int(profile.settings.get("new_cards_per_session", 5))
	if cards.is_empty() and kanji_cards.is_empty() and lesson == 1 and level == 0 and new_limit > 0:
		return _recommendation("multiple_choice", profile, "Start with Lesson 1 meanings from the professional curriculum.", {"size": 5, "due": 0}, {})
	var summary := ProgressMetrics.get_skill_summary(cards, kanji_cards, level, lesson)
	var last_game := ""
	if not sessions.is_empty():
		last_game = str(sessions.back().get("game_type", ""))
	var candidates: Array = []
	for activity in ActivityCatalog.ACTIVITIES:
		var pool := _activity_pool(activity, profile, cards, kanji_cards)
		var minimum := 6 if activity["game_type"] == "kanji_matching" else 1
		if int(pool["size"]) < minimum:
			continue
		var skill: String = activity["skill"]
		var evidence: Dictionary = summary[skill]
		var attempts := int(evidence["attempts"])
		var score := minf(float(pool["due"]) * 5.0, 50.0)
		if attempts == 0:
			score += 25.0 if cards.size() >= 5 else 5.0
		elif attempts < 5:
			score += 20.0
		else:
			score += (1.0 - float(evidence["success_rate"])) * 40.0
			if attempts < 10 or float(evidence["success_rate"]) < 0.8:
				score += 10.0
		if int(pool["size"]) > 0 and int(pool["due"]) == 0:
			score += 5.0
		if activity["game_type"] == last_game:
			score -= 8.0
		candidates.append({"activity": activity, "pool": pool, "evidence": evidence, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["score"] == b["score"]:
			return a["activity"]["game_type"] < b["activity"]["game_type"]
		return a["score"] > b["score"]
	)
	if candidates.is_empty():
		var fallback := ActivityCatalog.get_notebook_option()
		fallback["reason"] = "No scored activity has enough material in this lesson. Review the lesson or adjust New cards in Settings."
		fallback["game_type"] = "study_notebook"
		return fallback
	var best: Dictionary = candidates[0]
	var activity: Dictionary = best["activity"]
	var evidence: Dictionary = best["evidence"]
	var reason := ""
	if int(best["pool"]["due"]) > 0:
		reason = "%d eligible cards due · %s has %d recorded attempts." % [best["pool"]["due"], activity["skill"].capitalize(), evidence["attempts"]]
	elif int(evidence["attempts"]) == 0:
		reason = "Build %s evidence; no attempts have been recorded yet." % activity["skill"].capitalize()
	else:
		reason = "%s evidence: %d attempts, %d%% correct." % [activity["skill"].capitalize(), int(evidence["attempts"]), int(float(evidence["success_rate"]) * 100.0)]
	return _recommendation(activity["game_type"], profile, reason, best["pool"], evidence)


static func _recommendation(game_type: String, profile: PlayerProfile, reason: String, _pool: Dictionary, _evidence: Dictionary) -> Dictionary:
	var option := ActivityCatalog.get_option(game_type, profile)
	option["reason"] = reason
	option["game_type"] = game_type
	return option


static func _activity_pool(activity: Dictionary, profile: PlayerProfile, cards: Array[SRSCard], kanji_cards: Array[KanjiCard]) -> Dictionary:
	if activity["game_type"] == "kanji_workshop":
		return _kanji_pool(profile, kanji_cards)
	if activity.get("require_menu", false):
		return _cafe_pool(cards, int(profile.settings.get("new_cards_per_session", 5)))
	if activity["game_type"] == "reading_shelf":
		return _reading_pool(profile)
	var config := ActivityCatalog.get_config(activity["game_type"], profile)
	var filters: Dictionary = {}
	for key in ["require_audio", "require_cloze", "require_examples"]:
		if activity.get(key, false):
			filters[key] = true
	var selection := LessonSessionPlanner.build_vocabulary_session(config, filters, int(config["words_per_session"]), int(profile.settings.get("new_cards_per_session", 5)), false, cards)
	return {"size": selection["words"].size(), "due": selection["due"]}


static func _cafe_pool(cards: Array[SRSCard], new_limit: int) -> Dictionary:
	var existing: Dictionary = {}
	var eligible: Dictionary = {}
	var due := 0
	var today := GameController.get_current_date()
	for card in cards:
		existing[card.vocab_id] = true
		if card.is_due(today) and VocabDatabase.is_legacy_cafe_id(card.vocab_id):
			if not VocabDatabase.get_menu_item(card.vocab_id).is_empty() and AudioManager.has_speech("order:" + card.vocab_id):
				eligible[card.vocab_id] = true
				due += 1
	if new_limit > 0:
		for item in VocabDatabase.cafe_menu:
			var word_id := str(item["vocab_id"])
			if not existing.has(word_id) and AudioManager.has_speech("order:" + word_id):
				eligible[word_id] = true
	return {"size": eligible.size(), "due": due}


static func _reading_pool(profile: PlayerProfile) -> Dictionary:
	var config := ActivityCatalog.get_config("reading_shelf", profile)
	var passages := LessonSessionPlanner.get_reading_passages(config, 5)
	var count := 0
	for passage in passages:
		if str(passage.get("question", "")) != "":
			count += 1
	return {"size": count, "due": 0}


static func _word_matches(word: VocabWord, activity: Dictionary, level: int, lesson: int) -> bool:
	if level > 0 and word.jlpt_level != level:
		return false
	if lesson > 0 and lesson not in word.lesson_ids:
		return false
	if not word.has_meaning():
		return false
	if activity.get("require_cloze", false):
		if word.example_sentences.is_empty() and VocabDatabase.get_exercises_for_word(word.id).is_empty():
			return false
	elif activity.get("require_examples", false) and word.example_sentences.is_empty():
		return false
	if activity.get("require_audio", false):
		if word.get_reading() == "" or not AudioManager.has_speech("vocab:" + word.id):
			return false
	return true


static func _kanji_pool(profile: PlayerProfile, cards: Array[KanjiCard]) -> Dictionary:
	var new_limit := mini(3, int(profile.settings.get("new_cards_per_session", 5)))
	var today := GameController.get_current_date()
	var config := ActivityCatalog.get_config("kanji_workshop", profile)
	var entries := LessonSessionPlanner.get_kanji_entries(config)
	var scoped: Dictionary = {}
	for entry in entries:
		scoped[entry.character] = true
	var existing: Dictionary = {}
	var eligible: Dictionary = {}
	var due := 0
	for card in cards:
		existing[card.character] = true
		if card.is_due(today) and scoped.has(card.character):
			eligible[card.character] = true
			due += 1
	if new_limit > 0:
		for entry in entries:
			if not existing.has(entry.character):
				eligible[entry.character] = true
	return {"size": eligible.size(), "due": due}
