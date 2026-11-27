extends Control

var _passes := 0
var _failures := 0


func _ready() -> void:
	var saved_cards := SRSEngine.cards
	var saved_profile := GameController.current_profile
	var saved_config := GameController.session_data
	_test_normalizer()
	_test_flashcard_empty_session()
	await _test_listening()
	await _test_listening_levels()
	await _test_cloze()
	await _test_notebook()
	SRSEngine.cards = saved_cards
	GameController.current_profile = saved_profile
	GameController.session_data = saved_config
	AudioManager.stop_speech()
	AudioManager.stop_bgm(0.0)
	for player in AudioManager._sfx_players:
		player.stop()
	await get_tree().create_timer(0.6).timeout
	print("v0.8 activity tests: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _profile(level: int = 0, new_cards: int = 5, lesson: int = 5) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_name = "V08Test"
	profile.settings["target_jlpt_level"] = level
	profile.settings["target_lesson"] = lesson
	profile.settings["new_cards_per_session"] = new_cards
	profile.settings["difficulty"] = "standard"
	GameController.current_profile = profile
	return profile


func _test_normalizer() -> void:
	var word := VocabWord.new()
	word.hiragana = "がっこう"
	word.katakana = "ガッコウ"
	word.romaji = "Gakkou"
	_check("Normalizer accepts hiragana", JapaneseAnswerNormalizer.matches(word, " がっこう "))
	_check("Normalizer accepts katakana", JapaneseAnswerNormalizer.matches(word, "ガッコウ"))
	_check("Normalizer accepts halfwidth voiced kana", JapaneseAnswerNormalizer.matches(word, "ｶﾞｯｺｳ"))
	_check("Normalizer accepts case-insensitive romaji", JapaneseAnswerNormalizer.matches(word, "gAkKoU"))
	_check("Normalizer accepts fullwidth romaji", JapaneseAnswerNormalizer.matches(word, "Ｇａｋｋｏｕ"))
	_check("Normalizer rejects wrong answers", not JapaneseAnswerNormalizer.matches(word, "がこう"))


func _test_flashcard_empty_session() -> void:
	_profile(0, 0, 1)
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "flashcard_review", "words_per_session": 10}
	var review = load("res://Scenes/MiniGames/FlashcardReview/flashcard_review.tscn").instantiate()
	add_child(review)
	_check("Flashcard empty session reports no cards", review._session_words.is_empty() and review.progress_label.text == "0 / 0")
	_check("Flashcard empty session disables card controls", review.flip_btn.disabled and review.pronounce_btn.disabled and not review.rating_box.visible)
	review._on_pronounce_pressed()
	review._on_flip_pressed()
	review._on_rate_pressed(SRSEngine.Quality.GOOD)
	_check("Flashcard empty handlers are safe no-ops", review._correct_count == 0 and review._session_cards.is_empty() and SRSEngine.cards.is_empty() and not review.back_panel.visible)
	review.free()


func _test_listening() -> void:
	_profile()
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "listening_lab", "words_per_session": 10}
	var lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
	add_child(lab)
	_check("Listening Lab introduces five professional audio-ready cards", lab._session_words.size() == 5)
	var audio_ready := true
	for word in lab._session_words:
		if not AudioManager.has_speech("vocab:" + word.id):
			audio_ready = false
	_check("Listening Lab session has ready pronunciation", audio_ready)
	var first_card: SRSCard = lab._session_cards[0]
	lab.input_field.text = lab._session_words[0].get_reading()
	lab._on_submit_pressed()
	_check("Unassisted dictation records Listening", first_card.skill_evidence.has("listening") and not first_card.skill_evidence.has("reading"))
	_check("Listening Lab preserves standard XP", lab._total_xp == 10 and lab._assisted_count == 0)
	await get_tree().create_timer(2.0).timeout
	var second_card: SRSCard = lab._session_cards[1]
	lab._on_assist_pressed()
	lab.input_field.text = lab._session_words[1].get_reading()
	lab._on_submit_pressed()
	_check("Show Text records assisted Reading", second_card.skill_evidence.has("reading") and not second_card.skill_evidence.has("listening") and lab._assisted_count == 1)
	await get_tree().create_timer(2.0).timeout
	var third_card: SRSCard = lab._session_cards[2]
	var clip_id: String = "vocab:" + lab._session_words[2].id
	var saved_clip: String = AudioManager._audio_manifest[clip_id]
	AudioManager._audio_manifest.erase(clip_id)
	lab._play_word_audio(lab._session_words[2])
	_check("Audio failure activates assisted fallback", lab._assisted and lab.answer_label.visible)
	AudioManager._audio_manifest[clip_id] = saved_clip
	lab._on_skip_pressed()
	_check("Assisted skip records Reading only", third_card.skill_evidence.has("reading") and not third_card.skill_evidence.has("listening"))
	await get_tree().create_timer(2.0).timeout
	lab.free()


func _test_listening_levels() -> void:
	for level in [5, 4, 0]:
		_profile(level)
		SRSEngine.cards = []
		GameController.session_data = {"game_type": "listening_lab", "words_per_session": 10}
		var lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
		add_child(lab)
		var valid: bool = not lab._session_words.is_empty()
		for word in lab._session_words:
			if level > 0 and word.jlpt_level != level:
				valid = false
		_check("Listening Lab JLPT %d selection" % level, valid)
		lab.free()
	_profile(4, 0)
	SRSEngine.cards = []
	var due_ids := PackedStringArray()
	for level in [5, 4]:
		for word in VocabDatabase.get_words_by_jlpt(level):
			if AudioManager.has_speech("vocab:" + word.id):
				due_ids.append(word.id)
				break
	var lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
	SRSEngine.add_new_cards(due_ids)
	add_child(lab)
	_check("Listening due-only spans introduced levels and lessons", lab._session_words.size() == 2)
	lab.free()
	_profile(0, 5, 1)
	var empty_level := 0
	for level in [1, 2, 3, 4, 5]:
		if VocabDatabase.get_random_words(1, PackedStringArray(), {"lesson": 1, "jlpt_level": level, "require_audio": true}).is_empty():
			empty_level = level
			break
	GameController.current_profile.settings["target_jlpt_level"] = empty_level
	SRSEngine.cards = []
	lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
	add_child(lab)
	_check("Listening empty filters do not substitute", lab._session_words.is_empty() and lab.submit_btn.disabled)
	lab.free()


func _test_cloze() -> void:
	_profile(0, 5, 5)
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "fill_in_blank", "words_per_session": 5}
	var cloze = load("res://Scenes/MiniGames/FillInBlank/fill_in_blank.tscn").instantiate()
	add_child(cloze)
	_check("Professional cloze session builds", cloze._session_words.size() > 0)
	_check("Cloze displays one explicit blank", cloze.sentence_label.text.count("______") == 1)
	_check("Cloze uses four real choices", cloze.answer_btns.all(func(button: Button) -> bool: return button.text not in ["", "???", "...", "---"]))
	var card: SRSCard = cloze._session_cards[0]
	for i in 4:
		if cloze.answer_btns[i].text == cloze._correct_answer:
			cloze._on_answer_pressed(i)
			break
	_check("Cloze records context evidence", card.skill_evidence.has("context") and card.total_reviews == 1)
	await get_tree().create_timer(1.4).timeout
	cloze.free()


func _test_notebook() -> void:
	var profile := _profile(0, 0, 1)
	SRSEngine.cards = []
	var lesson_five_word := VocabDatabase.get_words_by_lesson(5)[0]
	var lesson_one_word := VocabDatabase.get_words_by_lesson(1)[0]
	var cards := SRSEngine.add_new_cards(PackedStringArray([lesson_one_word.id, lesson_five_word.id]))
	cards[0].total_reviews = 2
	cards[0].correct_reviews = 1
	var before_due := SRSEngine.get_due_count()
	var notebook = load("res://Scenes/StudyNotebook/study_notebook.tscn").instantiate()
	add_child(notebook)
	_check("Notebook defaults to Lesson 1 professional words", notebook._filtered_words.size() == VocabDatabase.get_words_by_lesson(1).size() and notebook.list_container.get_child_count() == 20)
	notebook.search_field.text = lesson_one_word.romaji
	notebook._on_filters_changed("")
	_check("Notebook searches derived romaji", notebook._filtered_words.size() >= 1)
	notebook.search_field.text = lesson_one_word.source_word
	notebook._on_filters_changed("")
	_check("Notebook searches professional Japanese", notebook._filtered_words.size() >= 1)
	if lesson_one_word.has_meaning():
		notebook.search_field.text = lesson_one_word.get_primary_meaning()
		notebook._on_filters_changed("")
		_check("Notebook searches professional English", notebook._filtered_words.size() >= 1)
	notebook.search_field.text = ""
	notebook.topic_option.select(notebook.topic_option.get_item_index(0))
	notebook._on_filters_changed(0)
	notebook.state_option.select(1)
	notebook._on_filters_changed(0)
	_check("Notebook Introduced filter uses professional cards", notebook._filtered_words.size() == 2)
	notebook.state_option.select(2)
	notebook._on_filters_changed(0)
	_check("Notebook Due filter uses professional cards", notebook._filtered_words.size() == 2)
	notebook.state_option.select(3)
	notebook._on_filters_changed(0)
	_check("Notebook Needs Practice excludes new cards", notebook._filtered_words.size() == 1 and notebook._filtered_words[0].id == lesson_one_word.id)
	notebook._show_detail(lesson_one_word)
	_check("Notebook shows professional provenance", notebook.detail_container.get_child_count() > 8)
	_check("Notebook does not mutate learning or rewards", SRSEngine.cards.size() == 2 and SRSEngine.get_due_count() == before_due and profile.xp == 0 and profile.coffee_beans == 0)
	notebook._mode_option.select(1)
	notebook.topic_option.select(notebook.topic_option.get_item_index(5))
	notebook._on_filters_changed(0)
	_check("Notebook Grammar mode filters Lesson 5", notebook._filtered_grammar.size() == 8 and notebook.state_option.disabled)
	notebook._show_grammar_detail(notebook._filtered_grammar[0])
	_check("Notebook displays full professional grammar", notebook.detail_container.get_child_count() > 4)
	notebook.free()
	GameController.current_profile = null
	SRSEngine.cards = []
	notebook = load("res://Scenes/StudyNotebook/study_notebook.tscn").instantiate()
	add_child(notebook)
	_check("Notebook supports no-profile professional browsing", notebook._filtered_words.size() == VocabDatabase.get_words_by_lesson(1).size())
	notebook.free()


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
