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


static func get_skill_summary(cards: Array[SRSCard], kanji_cards: Array[KanjiCard] = [], level: int = 0) -> Dictionary:
	var summary: Dictionary = {}
	for skill in SKILL_IDS:
		summary[skill] = {
			"attempts": 0,
			"correct": 0,
			"lapses": 0,
			"success_rate": 0.0,
			"has_data": false,
			"last_practice": "",
			"evidence_label": "No Evidence",
		}
	for card in cards:
		if level > 0:
			var word := VocabDatabase.get_word_by_id(card.vocab_id)
			if word == null or word.jlpt_level != level:
				continue
		for skill in SKILL_IDS:
			if not card.skill_evidence.has(skill):
				continue
			var evidence := card.skill_evidence[skill] as SkillEvidence
			if evidence == null:
				continue
			summary[skill]["attempts"] += evidence.attempts
			summary[skill]["correct"] += evidence.correct
			summary[skill]["lapses"] += evidence.lapses
			if evidence.last_review_date > summary[skill]["last_practice"]:
				summary[skill]["last_practice"] = evidence.last_review_date
	for card in kanji_cards:
		if level > 0:
			var entry := VocabDatabase.get_kanji(card.character)
			if entry == null or entry.jlpt_level != level:
				continue
		for skill in SKILL_IDS:
			if not card.skill_evidence.has(skill):
				continue
			var evidence := card.skill_evidence[skill] as SkillEvidence
			if evidence == null:
				continue
			summary[skill]["attempts"] += evidence.attempts
			summary[skill]["correct"] += evidence.correct
			summary[skill]["lapses"] += evidence.lapses
			if evidence.last_review_date > summary[skill]["last_practice"]:
				summary[skill]["last_practice"] = evidence.last_review_date
	for skill in SKILL_IDS:
		var attempts: int = summary[skill]["attempts"]
		summary[skill]["has_data"] = attempts > 0
		if attempts > 0:
			summary[skill]["success_rate"] = float(summary[skill]["correct"]) / float(attempts)
		summary[skill]["evidence_label"] = get_evidence_label(attempts, summary[skill]["success_rate"])
	return summary


static func get_evidence_label(attempts: int, success_rate: float) -> String:
	if attempts == 0:
		return "No Evidence"
	if attempts < 5:
		return "Early Evidence"
	if attempts >= 10 and success_rate >= 0.8:
		return "Consistent"
	return "Developing"


static func get_level_summary(cards: Array[SRSCard], words: Array[VocabWord], kanji: Array[KanjiEntry], level: int) -> Dictionary:
	var words_by_id: Dictionary = {}
	var level_word_ids: Dictionary = {}
	for word in words:
		words_by_id[word.id] = word
		if level == 0 or word.jlpt_level == level:
			level_word_ids[word.id] = true
	var authored_kanji: Dictionary = {}
	for entry in kanji:
		if level == 0 or entry.jlpt_level == level:
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


static func get_topic_summary(cards: Array[SRSCard], words: Array[VocabWord], level: int = 0) -> Dictionary:
	var summary: Dictionary = {}
	var words_by_id: Dictionary = {}
	for word in words:
		if level > 0 and word.jlpt_level != level:
			continue
		words_by_id[word.id] = word
		for category in word.categories:
			if not summary.has(category):
				summary[category] = {"total": 0, "introduced": 0, "retained": 0, "coverage": 0.0}
			summary[category]["total"] += 1
	for card in cards:
		var word := words_by_id.get(card.vocab_id) as VocabWord
		if word == null:
			continue
		var retained := get_card_stage(card) == CardStage.RETAINED
		for category in word.categories:
			summary[category]["introduced"] += 1
			if retained:
				summary[category]["retained"] += 1
	for category in summary:
		var total: int = summary[category]["total"]
		if total > 0:
			summary[category]["coverage"] = float(summary[category]["introduced"]) / float(total)
	return summary


static func get_kanji_summary(cards: Array[KanjiCard], entries: Array[KanjiEntry], current_date: String, level: int = 5) -> Dictionary:
	var authored: Dictionary = {}
	for entry in entries:
		if level == 0 or entry.jlpt_level == level:
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
