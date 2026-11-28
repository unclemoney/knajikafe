extends Control

var _failures: int = 0
var _passes: int = 0


func _ready() -> void:
	_test_stages()
	_test_skill_summary()
	_test_level_summary()
	_test_kanji_summary()
	_test_practice_and_dates()
	_test_session_selection()
	await _test_matching_reporting()
	AudioManager.stop_bgm(0.0)
	for player in AudioManager._sfx_players:
		player.stop()
	await get_tree().create_timer(0.1).timeout
	print("ProgressMetrics tests: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_stages() -> void:
	var card := SRSCard.new()
	_check("New stage", ProgressMetrics.get_card_stage(card) == ProgressMetrics.CardStage.NEW)
	card.total_reviews = 2
	card.correct_reviews = 1
	card.repetitions = 1
	card.interval = 1.0
	_check("Learning stage", ProgressMetrics.get_card_stage(card) == ProgressMetrics.CardStage.LEARNING)
	card.total_reviews = 3
	card.correct_reviews = 2
	card.repetitions = 2
	card.interval = 6.0
	_check("Familiar stage", ProgressMetrics.get_card_stage(card) == ProgressMetrics.CardStage.FAMILIAR)
	card.total_reviews = 4
	card.correct_reviews = 4
	card.repetitions = 3
	card.interval = 14.0
	_check("Retained stage", ProgressMetrics.get_card_stage(card) == ProgressMetrics.CardStage.RETAINED)
	card.repetitions = 0
	card.interval = 1.0
	_check("Lapse returns to Learning", ProgressMetrics.get_card_stage(card) == ProgressMetrics.CardStage.LEARNING)


func _test_skill_summary() -> void:
	var card := SRSCard.new()
	var evidence := SkillEvidence.new()
	evidence.record(SRSEngine.Quality.GOOD, "2026-01-01", "multiple_choice")
	evidence.record(SRSEngine.Quality.WRONG, "2026-01-02", "multiple_choice")
	card.skill_evidence["meaning"] = evidence
	var cards: Array[SRSCard] = [card]
	var summary := ProgressMetrics.get_skill_summary(cards)
	_check("Skill attempts", summary["meaning"]["attempts"] == 2)
	_check("Skill successes", summary["meaning"]["correct"] == 1)
	_check("Skill rate", is_equal_approx(summary["meaning"]["success_rate"], 0.5))
	_check("Empty reading has no data", not summary["reading"]["has_data"])
	_check("Evidence lapse", evidence.lapses == 1 and evidence.consecutive_correct == 0)


func _test_level_summary() -> void:
	var word_a := _word("a", "一")
	var word_b := _word("b", "二")
	var card_a := SRSCard.new()
	card_a.vocab_id = "a"
	var card_b := SRSCard.new()
	card_b.vocab_id = "b"
	card_b.total_reviews = 4
	card_b.correct_reviews = 4
	card_b.repetitions = 3
	card_b.interval = 14.0
	var cards: Array[SRSCard] = [card_a, card_b]
	var words: Array[VocabWord] = [word_a, word_b]
	var kanji: Array[KanjiEntry] = [_kanji("一"), _kanji("二")]
	var summary := ProgressMetrics.get_level_summary(cards, words, kanji, 5)
	_check("Level coverage", summary["introduced"] == 2 and summary["coverage"] == 1.0)
	_check("Level retained", summary["retained"] == 1 and summary["retained_ratio"] == 0.5)
	_check("Encountered kanji", summary["kanji_encountered"] == 2)
	_check("Stage counts", summary["stage_counts"]["New"] == 1 and summary["stage_counts"]["Retained"] == 1)
	var word_c := _word("c", "三")
	word_c.jlpt_level = 4
	var card_c := SRSCard.new()
	card_c.vocab_id = "c"
	var mixed_cards: Array[SRSCard] = [card_a, card_b, card_c]
	var mixed_words: Array[VocabWord] = [word_a, word_b, word_c]
	var mixed_kanji: Array[KanjiEntry] = [_kanji("一"), _kanji("二"), _kanji("三")]
	mixed_kanji[2].jlpt_level = 4
	var mixed := ProgressMetrics.get_level_summary(mixed_cards, mixed_words, mixed_kanji, 0)
	_check("Mixed coverage includes N5 and N4", mixed["total_words"] == 3 and mixed["introduced"] == 3)
	word_a.lesson_ids = PackedInt32Array([1])
	word_b.lesson_ids = PackedInt32Array([1])
	word_c.lesson_ids = PackedInt32Array([2])
	var lesson_one := ProgressMetrics.get_level_summary(mixed_cards, mixed_words, mixed_kanji, 0, 1)
	_check("Lesson coverage filters professional vocabulary", lesson_one["total_words"] == 2 and lesson_one["introduced"] == 2)
	var n4 := ProgressMetrics.get_level_summary(mixed_cards, mixed_words, mixed_kanji, 4)
	_check("N4 coverage excludes N5", n4["total_words"] == 1 and n4["introduced"] == 1)


func _test_kanji_summary() -> void:
	var learning := KanjiCard.new()
	learning.setup("一")
	var retained := KanjiCard.new()
	retained.setup("二")
	retained.total_reviews = 4
	retained.correct_reviews = 4
	retained.repetitions = 3
	retained.interval = 14.0
	var evidence := SkillEvidence.new()
	evidence.record(SRSEngine.Quality.GOOD, "2026-01-01", "kanji_workshop")
	retained.skill_evidence["kanji_form"] = evidence
	var cards: Array[KanjiCard] = [learning, retained]
	var entries: Array[KanjiEntry] = [_kanji("一"), _kanji("二")]
	var summary := ProgressMetrics.get_kanji_summary(cards, entries, "2026-01-02")
	_check("Kanji introduced and retained", summary["introduced"] == 2 and summary["retained"] == 1)
	_check("Kanji due count", summary["due"] == 2)
	var vocabulary: Array[SRSCard] = []
	var skills := ProgressMetrics.get_skill_summary(vocabulary, cards)
	_check("Kanji Form evidence included", skills["kanji_form"]["attempts"] == 1)
	_check("Listening remains empty", not skills["listening"]["has_data"])


func _test_practice_and_dates() -> void:
	var new_card := SRSCard.new()
	new_card.vocab_id = "new"
	var lapse := SRSCard.new()
	lapse.vocab_id = "lapse"
	lapse.total_reviews = 2
	lapse.correct_reviews = 1
	lapse.repetitions = 0
	lapse.next_review_date = "2026-01-02"
	var retained := SRSCard.new()
	retained.vocab_id = "retained"
	retained.total_reviews = 4
	retained.correct_reviews = 4
	retained.repetitions = 3
	retained.interval = 14.0
	retained.next_review_date = "2026-01-01"
	var cards: Array[SRSCard] = [new_card, retained, lapse]
	var practice := ProgressMetrics.get_needs_practice(cards, "2026-01-03")
	_check("Needs Practice excludes new", practice.size() == 2)
	_check("Needs Practice prioritizes lapse", practice[0] == lapse)
	_check("Next review date", ProgressMetrics.get_next_review_date(cards) == "2026-01-01")


func _test_session_selection() -> void:
	var saved_cards := SRSEngine.cards
	var saved_profile := GameController.current_profile
	var saved_config := GameController.session_data
	var profile := PlayerProfile.new()
	profile.player_name = "SessionTest"
	profile.settings["target_jlpt_level"] = 5
	profile.settings["target_lesson"] = 1
	GameController.current_profile = profile
	var n4_word: VocabWord = null
	for candidate in VocabDatabase.get_words_by_jlpt(4):
		if candidate.has_meaning() and candidate.first_lesson > 1:
			n4_word = candidate
			break
	var n4_card := SRSCard.new()
	n4_card.vocab_id = n4_word.id
	SRSEngine.cards = [n4_card]
	GameController.session_data = {"game_type": "multiple_choice", "words_per_session": 10}
	var session := MiniGameBase.new()
	add_child(session)
	session._setup_session()
	_check("Locked future due card is ineligible", n4_card not in session._session_cards)
	_check("Five new cards fill the session", session._session_words.size() == 5)
	var new_words_valid := true
	for word in session._session_words:
		if word.id != n4_word.id and 1 not in word.lesson_ids:
			new_words_valid = false
	_check("New cards use Lesson 1 regardless of JLPT setting", new_words_valid)
	session.free()
	SRSEngine.cards = saved_cards
	GameController.current_profile = saved_profile
	GameController.session_data = saved_config


func _test_matching_reporting() -> void:
	var saved_cards := SRSEngine.cards
	var saved_profile := GameController.current_profile
	var saved_config := GameController.session_data
	var profile := PlayerProfile.new()
	profile.player_name = "MatchingTest"
	profile.settings["target_jlpt_level"] = 5
	profile.settings["target_lesson"] = 1
	GameController.current_profile = profile
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "kanji_matching", "words_per_session": 6}
	var matching = load("res://Scenes/MiniGames/KanjiMatching/kanji_matching.tscn").instantiate()
	add_child(matching)
	_check("Matching receives six pairs", matching._session_words.size() == 6 and matching._card_buttons.size() == 12)
	var first := -1
	var second := -1
	for i in matching._card_data.size():
		if matching._card_data[i]["word_index"] == 0:
			if first == -1:
				first = i
			else:
				second = i
	matching._pair_mistakes[0] = 1
	matching._first_flip = first
	matching._second_flip = second
	matching._check_match()
	var card: SRSCard = matching._session_cards[0]
	var evidence := card.skill_evidence.get("meaning") as SkillEvidence
	_check("Matching records one attempt", card.total_reviews == 1 and evidence != null and evidence.attempts == 1)
	_check("Matching mistakes lower quality", evidence != null and evidence.last_quality == SRSEngine.Quality.HARD)
	await get_tree().create_timer(0.6).timeout
	matching.free()
	SRSEngine.cards = saved_cards
	GameController.current_profile = saved_profile
	GameController.session_data = saved_config


func _word(id: String, character: String) -> VocabWord:
	var word := VocabWord.new()
	word.id = id
	word.kanji = character
	word.jlpt_level = 5
	return word


func _kanji(character: String) -> KanjiEntry:
	var entry := KanjiEntry.new()
	entry.character = character
	entry.jlpt_level = 5
	return entry


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
