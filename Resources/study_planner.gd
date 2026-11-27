extends RefCounted
class_name StudyPlanner


static func get_recommendation() -> Dictionary:
	var profile := GameController.current_profile
	if profile == null:
		return {}
	return recommend(profile, SRSEngine.cards, SRSEngine.kanji_cards, SRSEngine.sessions)


static func recommend(profile: PlayerProfile, cards: Array[SRSCard], kanji_cards: Array[KanjiCard], sessions: Array) -> Dictionary:
	var level := int(profile.settings.get("target_jlpt_level", 5))
	var topic := str(profile.settings.get("target_topic", "all"))
	var new_limit := int(profile.settings.get("new_cards_per_session", 5))
	if cards.is_empty() and kanji_cards.is_empty() and level == 5 and topic == "all" and new_limit > 0:
		return _recommendation("multiple_choice", profile, "Start with N5 meanings to build your first study evidence.", {"size": 5, "due": 0}, {})
	var summary := ProgressMetrics.get_skill_summary(cards, kanji_cards, level)
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
		fallback["reason"] = "No scored activity matches the current filters. Browse the Notebook or adjust Settings."
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
		reason = "%s evidence: %d attempts, %d%% correct." % [activity["skill"].capitalize(), evidence["attempts"], int(float(evidence["success_rate"]) * 100.0)]
	return _recommendation(activity["game_type"], profile, reason, best["pool"], evidence)


static func _recommendation(game_type: String, profile: PlayerProfile, reason: String, _pool: Dictionary, _evidence: Dictionary) -> Dictionary:
	var option := ActivityCatalog.get_option(game_type, profile)
	option["reason"] = reason
	option["game_type"] = game_type
	return option


static func _activity_pool(activity: Dictionary, profile: PlayerProfile, cards: Array[SRSCard], kanji_cards: Array[KanjiCard]) -> Dictionary:
	if activity["game_type"] == "kanji_workshop":
		return _kanji_pool(profile, kanji_cards)
	var level := int(profile.settings.get("target_jlpt_level", 5))
	var topic := str(profile.settings.get("target_topic", "all"))
	var new_limit := int(profile.settings.get("new_cards_per_session", 5))
	var today := GameController.get_current_date()
	var existing: Dictionary = {}
	var eligible: Dictionary = {}
	var due := 0
	for card in cards:
		existing[card.vocab_id] = true
		if not card.is_due(today):
			continue
		var word := VocabDatabase.get_word_by_id(card.vocab_id)
		if word and _word_matches(word, activity, 0, topic):
			eligible[word.id] = true
			due += 1
	if new_limit > 0:
		for word in VocabDatabase.get_all_words():
			if not existing.has(word.id) and _word_matches(word, activity, level, topic):
				eligible[word.id] = true
	return {"size": eligible.size(), "due": due}


static func _word_matches(word: VocabWord, activity: Dictionary, level: int, topic: String) -> bool:
	if level > 0 and word.jlpt_level != level:
		return false
	if topic != "all" and topic not in word.categories:
		return false
	if activity.get("require_examples", false) and word.example_sentences.is_empty():
		return false
	if activity.get("require_menu", false):
		if VocabDatabase.get_menu_item(word.id).is_empty() or not AudioManager.has_speech("order:" + word.id):
			return false
	elif activity.get("require_audio", false) and not AudioManager.has_speech("vocab:" + word.id):
		return false
	if activity.get("require_reading", false):
		for passage in VocabDatabase.reading_passages:
			if passage.get("target_vocab_id", "") == word.id:
				return true
		return false
	return true


static func _kanji_pool(profile: PlayerProfile, cards: Array[KanjiCard]) -> Dictionary:
	var level := int(profile.settings.get("target_jlpt_level", 5))
	var new_limit := mini(3, int(profile.settings.get("new_cards_per_session", 5)))
	var today := GameController.get_current_date()
	var existing: Dictionary = {}
	var eligible: Dictionary = {}
	var due := 0
	for card in cards:
		existing[card.character] = true
		if card.is_due(today) and VocabDatabase.get_kanji(card.character):
			eligible[card.character] = true
			due += 1
	if new_limit > 0:
		var entries: Array[KanjiEntry] = []
		if level == 0:
			entries.append_array(VocabDatabase.get_kanji_by_jlpt(5))
			entries.append_array(VocabDatabase.get_kanji_by_jlpt(4))
		else:
			entries.append_array(VocabDatabase.get_kanji_by_jlpt(level))
		for entry in entries:
			if not existing.has(entry.character):
				eligible[entry.character] = true
	return {"size": eligible.size(), "due": due}
