extends Node
## SRSEngine (Autoload)
##
## Implements the SM-2 (SuperMemo 2) spaced repetition algorithm.
## Manages review scheduling and card queue for the active profile.

## Quality ratings for SM-2 (passed by mini-games after each answer).
## 0 = complete blackout, 1 = wrong, 2 = wrong but recognized,
## 3 = correct with difficulty, 4 = correct, 5 = perfect/easy.
enum Quality { BLACKOUT = 0, WRONG = 1, RECOGNIZED = 2, HARD = 3, GOOD = 4, EASY = 5 }

## Minimum ease factor allowed by SM-2.
const MIN_EASE_FACTOR: float = 1.3

## The currently loaded SRS cards for the active profile.
var cards: Array[SRSCard] = []

## Kanji cards for the active profile.
var kanji_cards: Array[KanjiCard] = []

## Completed session summaries for the active profile.
var sessions: Array = []
var learning_data_writable: bool = true


## Loads cards and session history for the given profile.
func load_cards_for_profile(profile: PlayerProfile) -> void:
	var data := SaveManager.load_learning_data(profile.player_name)
	cards = data["cards"]
	kanji_cards = data["kanji_cards"]
	sessions = data["sessions"]
	learning_data_writable = data["load_ok"]


## Saves cards and session history for the given profile.
func save_cards_for_profile(profile: PlayerProfile) -> bool:
	if not learning_data_writable:
		return false
	return SaveManager.save_learning_data(profile.player_name, cards, sessions, kanji_cards)


## Reviews a card with the given quality rating (0–5).
## Updates the card's SM-2 parameters and schedules the next review.
func review_card(card: SRSCard, quality: int) -> void:
	quality = clampi(quality, 0, 5)
	var today := GameController.get_current_date()

	card.total_reviews += 1
	if quality >= 3:
		card.correct_reviews += 1

	# SM-2 algorithm
	if quality >= 3:
		# Correct response
		if card.repetitions == 0:
			card.interval = 1.0
		elif card.repetitions == 1:
			card.interval = 6.0
		else:
			card.interval = card.interval * card.ease_factor
		card.repetitions += 1
	else:
		# Incorrect response — reset
		card.repetitions = 0
		card.interval = 1.0

	# Update ease factor: EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
	var q := float(quality)
	card.ease_factor = card.ease_factor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
	if card.ease_factor < MIN_EASE_FACTOR:
		card.ease_factor = MIN_EASE_FACTOR

	card.last_review_date = today
	card.next_review_date = _add_days_to_date(today, int(card.interval))


## Records skill evidence without changing the SM-2 schedule.
func record_attempt(card: SRSCard, skill: String, quality: int, source: String) -> void:
	if skill not in ProgressMetrics.SKILL_IDS:
		return
	if not card.skill_evidence.has(skill):
		card.skill_evidence[skill] = SkillEvidence.new()
	var evidence := card.skill_evidence[skill] as SkillEvidence
	evidence.record(quality, GameController.get_current_date(), source)


## Appends a completed session and bounds local history.
func record_session(summary: Dictionary) -> void:
	sessions.append(summary.duplicate(true))
	if sessions.size() > SaveManager.MAX_SESSION_HISTORY:
		sessions = sessions.slice(sessions.size() - SaveManager.MAX_SESSION_HISTORY)


## Returns all cards that are due for review on or before the current date.
## Sorted by priority: overdue cards first, then by ease factor (hardest first).
func get_due_cards() -> Array[SRSCard]:
	var today := GameController.get_current_date()
	var due: Array[SRSCard] = []
	for card in cards:
		if card.is_due(today):
			due.append(card)

	due.sort_custom(_sort_by_priority)
	return due


## Creates new SRS cards for the given vocab IDs and adds them to the deck.
## Skips IDs that already have cards.
func add_new_cards(vocab_ids: PackedStringArray) -> Array[SRSCard]:
	var existing_ids: Dictionary = {}
	for card in cards:
		existing_ids[card.vocab_id] = true

	var new_cards: Array[SRSCard] = []
	for vid in vocab_ids:
		if existing_ids.has(vid):
			continue
		var card := SRSCard.new()
		card.vocab_id = vid
		card.ease_factor = 2.5
		card.interval = 0.0
		card.repetitions = 0
		card.next_review_date = ""
		cards.append(card)
		new_cards.append(card)

	return new_cards


## Returns the SRS card for a given vocab ID, or null if not found.
func get_card_for_vocab(vocab_id: String) -> SRSCard:
	for card in cards:
		if card.vocab_id == vocab_id:
			return card
	return null


## Returns due kanji cards in the same priority order as vocabulary.
func get_due_kanji_cards() -> Array[KanjiCard]:
	var today := GameController.get_current_date()
	var due: Array[KanjiCard] = []
	for card in kanji_cards:
		if card.is_due(today):
			due.append(card)
	due.sort_custom(_sort_by_priority)
	return due


## Creates kanji cards not already present in the deck.
func add_new_kanji_cards(characters: PackedStringArray) -> Array[KanjiCard]:
	var existing: Dictionary = {}
	for card in kanji_cards:
		existing[card.character] = true
	var new_cards: Array[KanjiCard] = []
	for character in characters:
		if existing.has(character):
			continue
		var card := KanjiCard.new()
		card.setup(character)
		card.ease_factor = 2.5
		card.interval = 0.0
		card.repetitions = 0
		card.next_review_date = ""
		kanji_cards.append(card)
		new_cards.append(card)
	return new_cards


func get_kanji_card(character: String) -> KanjiCard:
	for card in kanji_cards:
		if card.character == character:
			return card
	return null


func get_due_kanji_count() -> int:
	return get_due_kanji_cards().size()


## Returns the total number of cards in the deck.
func get_total_card_count() -> int:
	return cards.size()


## Returns the number of cards due today.
func get_due_count() -> int:
	return get_due_cards().size()


## Sorts cards: overdue first (empty next_review_date = new = highest priority),
## then by ease_factor ascending (hardest cards first).
func _sort_by_priority(a: SRSCard, b: SRSCard) -> bool:
	# New cards (no review date) come first
	if a.next_review_date == "" and b.next_review_date != "":
		return true
	if a.next_review_date != "" and b.next_review_date == "":
		return false
	# Then sort by date (earlier = more overdue = higher priority)
	if a.next_review_date != b.next_review_date:
		return a.next_review_date < b.next_review_date
	# Tie-break by ease factor (lower = harder = review first)
	return a.ease_factor < b.ease_factor


## Adds a number of days to an ISO date string and returns the new date.
func _add_days_to_date(date_str: String, days: int) -> String:
	var parts := date_str.split("-")
	if parts.size() != 3:
		return date_str

	var dict := {
		"year": parts[0].to_int(),
		"month": parts[1].to_int(),
		"day": parts[2].to_int(),
		"hour": 0,
		"minute": 0,
		"second": 0,
	}
	var unix := Time.get_unix_time_from_datetime_dict(dict)
	unix += days * 86400
	var new_dict := Time.get_date_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [new_dict["year"], new_dict["month"], new_dict["day"]]
