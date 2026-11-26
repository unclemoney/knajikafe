extends RefCounted
class_name ProgressMetrics

const SKILL_IDS: Array[String] = ["meaning", "reading", "context", "listening", "kanji_form"]

enum CardStage { NEW, LEARNING, FAMILIAR, RETAINED }


static func get_card_stage(card: SRSCard) -> CardStage:
	if card.total_reviews == 0:
		return CardStage.NEW
	var success_rate := card.get_accuracy()
	if card.repetitions >= 3 and card.interval >= 14.0 and success_rate >= 0.8:
		return CardStage.RETAINED
	if card.repetitions >= 2 and card.interval >= 6.0 and success_rate >= 0.6:
		return CardStage.FAMILIAR
	return CardStage.LEARNING


static func get_stage_name(stage: CardStage) -> String:
	match stage:
		CardStage.NEW:
			return "New"
		CardStage.LEARNING:
			return "Learning"
		CardStage.FAMILIAR:
			return "Familiar"
		CardStage.RETAINED:
			return "Retained"
	return "Learning"


static func get_skill_summary(cards: Array[SRSCard], kanji_cards: Array[KanjiCard] = []) -> Dictionary:
	var summary: Dictionary = {}
	for skill in SKILL_IDS:
		summary[skill] = {
			"attempts": 0,
			"correct": 0,
			"success_rate": 0.0,
			"has_data": false,
		}
	for card in cards:
		for skill in SKILL_IDS:
			if not card.skill_evidence.has(skill):
				continue
			var evidence := card.skill_evidence[skill] as SkillEvidence
			if evidence == null:
				continue
			summary[skill]["attempts"] += evidence.attempts
			summary[skill]["correct"] += evidence.correct
	for card in kanji_cards:
		for skill in SKILL_IDS:
			if not card.skill_evidence.has(skill):
				continue
			var evidence := card.skill_evidence[skill] as SkillEvidence
			if evidence == null:
				continue
			summary[skill]["attempts"] += evidence.attempts
			summary[skill]["correct"] += evidence.correct
	for skill in SKILL_IDS:
		var attempts: int = summary[skill]["attempts"]
		summary[skill]["has_data"] = attempts > 0
		if attempts > 0:
			summary[skill]["success_rate"] = float(summary[skill]["correct"]) / float(attempts)
	return summary


static func get_level_summary(cards: Array[SRSCard], words: Array[VocabWord], kanji: Array[KanjiEntry], level: int) -> Dictionary:
	var words_by_id: Dictionary = {}
	var level_word_ids: Dictionary = {}
	for word in words:
		words_by_id[word.id] = word
		if word.jlpt_level == level:
			level_word_ids[word.id] = true
	var authored_kanji: Dictionary = {}
	for entry in kanji:
		if entry.jlpt_level == level:
			authored_kanji[entry.character] = true

	var stage_counts := {
		"New": 0,
		"Learning": 0,
		"Familiar": 0,
		"Retained": 0,
	}
	var introduced := 0
	var retained := 0
	var encountered: Dictionary = {}
	for card in cards:
		if not level_word_ids.has(card.vocab_id):
			continue
		introduced += 1
		var stage := get_card_stage(card)
		stage_counts[get_stage_name(stage)] += 1
		if stage == CardStage.RETAINED:
			retained += 1
		var word := words_by_id.get(card.vocab_id) as VocabWord
		if word:
			for i in word.kanji.length():
				var character := word.kanji[i]
				if authored_kanji.has(character):
					encountered[character] = true
	var total := level_word_ids.size()
	return {
		"level": level,
		"total_words": total,
		"introduced": introduced,
		"coverage": float(introduced) / float(total) if total > 0 else 0.0,
		"retained": retained,
		"retained_ratio": float(retained) / float(total) if total > 0 else 0.0,
		"stage_counts": stage_counts,
		"kanji_encountered": encountered.size(),
		"total_kanji": authored_kanji.size(),
	}


static func get_kanji_summary(cards: Array[KanjiCard], entries: Array[KanjiEntry], current_date: String, level: int = 5) -> Dictionary:
	var authored: Dictionary = {}
	for entry in entries:
		if entry.jlpt_level == level:
			authored[entry.character] = true
	var stages := {"New": 0, "Learning": 0, "Familiar": 0, "Retained": 0}
	var introduced := 0
	var retained := 0
	var due := 0
	for card in cards:
		if not authored.has(card.character):
			continue
		introduced += 1
		var stage := get_card_stage(card)
		stages[get_stage_name(stage)] += 1
		if stage == CardStage.RETAINED:
			retained += 1
		if card.is_due(current_date):
			due += 1
	var total := authored.size()
	return {
		"total": total,
		"introduced": introduced,
		"coverage": float(introduced) / float(total) if total > 0 else 0.0,
		"retained": retained,
		"retained_ratio": float(retained) / float(total) if total > 0 else 0.0,
		"stage_counts": stages,
		"due": due,
	}


static func get_kanji_needs_practice(cards: Array[KanjiCard], current_date: String, limit: int = 4) -> Array[KanjiCard]:
	var eligible: Array[KanjiCard] = []
	for card in cards:
		if card.total_reviews > 0:
			eligible.append(card)
	eligible.sort_custom(func(a: KanjiCard, b: KanjiCard) -> bool:
		var score_a := _practice_score(a, current_date)
		var score_b := _practice_score(b, current_date)
		if score_a == score_b:
			return a.character < b.character
		return score_a > score_b
	)
	return eligible.slice(0, mini(limit, eligible.size()))


static func get_needs_practice(cards: Array[SRSCard], current_date: String, limit: int = 8) -> Array[SRSCard]:
	var eligible: Array[SRSCard] = []
	for card in cards:
		if card.total_reviews > 0:
			eligible.append(card)
	eligible.sort_custom(func(a: SRSCard, b: SRSCard) -> bool:
		var score_a := _practice_score(a, current_date)
		var score_b := _practice_score(b, current_date)
		if score_a == score_b:
			return a.vocab_id < b.vocab_id
		return score_a > score_b
	)
	return eligible.slice(0, mini(limit, eligible.size()))


static func _practice_score(card: SRSCard, current_date: String) -> float:
	var score := (1.0 - card.get_accuracy()) * 40.0
	if card.repetitions == 0:
		score += 100.0
	if card.is_due(current_date):
		score += 50.0
	score += minf(float(card.total_reviews), 5.0)
	return score


static func get_next_review_date(cards: Array[SRSCard]) -> String:
	var next_date := ""
	for card in cards:
		if card.next_review_date == "":
			continue
		if next_date == "" or card.next_review_date < next_date:
			next_date = card.next_review_date
	return next_date
