extends Control

var _passes := 0
var _failures := 0


func _ready() -> void:
	var saved_cards := SRSEngine.cards
	var saved_profile := GameController.current_profile
	var saved_config := GameController.session_data
	_test_normalizer()
	await _test_listening()
	await _test_listening_levels()
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


func _profile(level: int, new_cards: int = 5) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_name = "V08Test"
	profile.settings["target_jlpt_level"] = level
	profile.settings["target_topic"] = "all"
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


func _test_listening() -> void:
	_profile(5)
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "listening_lab", "words_per_session": 10}
	var lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
	add_child(lab)
	_check("Listening Lab introduces five audio-ready cards", lab._session_words.size() == 5)
	var audio_ready := true
	for word in lab._session_words:
		if not AudioManager.has_speech("vocab:" + word.id):
			audio_ready = false
	_check("Listening Lab session has ready pronunciation", audio_ready)
	var first_card: SRSCard = lab._session_cards[0]
	lab.input_field.text = lab._session_words[0].hiragana
	lab._on_submit_pressed()
	_check("Unassisted dictation records Listening", first_card.skill_evidence.has("listening") and not first_card.skill_evidence.has("reading"))
	_check("Listening Lab preserves standard XP", lab._total_xp == 10 and lab._assisted_count == 0)
	await get_tree().create_timer(2.0).timeout
	var second_card: SRSCard = lab._session_cards[1]
	lab._on_assist_pressed()
	lab.input_field.text = lab._session_words[1].hiragana
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
		_check("Listening Lab level %d selection" % level, valid)
		lab.free()
	_profile(4, 0)
	SRSEngine.cards = []
	SRSEngine.add_new_cards(PackedStringArray(["n5_001", "n4_001"]))
	var lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
	add_child(lab)
	_check("Listening Lab due-only spans introduced levels", lab._session_words.size() == 2)
	lab.free()
	_profile(4, 5)
	var empty_topic := ""
	for category in VocabDatabase.get_categories():
		if VocabDatabase.get_random_words(1, PackedStringArray(), {"jlpt_level": 4, "category": category}).is_empty():
			empty_topic = category
			break
	GameController.current_profile.settings["target_topic"] = empty_topic
	SRSEngine.cards = []
	lab = load("res://Scenes/MiniGames/ListeningLab/listening_lab.tscn").instantiate()
	add_child(lab)
	_check("Listening Lab empty topic does not substitute", lab._session_words.is_empty() and lab.submit_btn.disabled)
	lab.free()


func _test_notebook() -> void:
	var profile := _profile(5, 0)
	SRSEngine.cards = []
	var cards := SRSEngine.add_new_cards(PackedStringArray(["n5_001", "n4_001"]))
	cards[0].total_reviews = 2
	cards[0].correct_reviews = 1
	var before_due := SRSEngine.get_due_count()
	var notebook = load("res://Scenes/StudyNotebook/study_notebook.tscn").instantiate()
	add_child(notebook)
	_check("Notebook defaults to 800 N5 words", notebook._filtered_words.size() == 800 and notebook.list_container.get_child_count() == 20)
	notebook.search_field.text = "konnichiwa"
	notebook._on_filters_changed("")
	_check("Notebook searches romaji", notebook._filtered_words.size() == 1 and notebook._filtered_words[0].id == "n5_001")
	notebook.search_field.text = "こんにちは"
	notebook._on_filters_changed("")
	_check("Notebook searches Japanese", notebook._filtered_words.size() == 1)
	notebook.search_field.text = "hello"
	notebook._on_filters_changed("")
	_check("Notebook searches English", notebook._filtered_words.size() >= 1)
	notebook.search_field.text = ""
	notebook.level_option.select(notebook.level_option.get_item_index(0))
	notebook._on_filters_changed(0)
	notebook.state_option.select(1)
	notebook._on_filters_changed(0)
	_check("Notebook Introduced filter uses existing cards", notebook._filtered_words.size() == 2)
	notebook.state_option.select(2)
	notebook._on_filters_changed(0)
	_check("Notebook Due filter uses due cards", notebook._filtered_words.size() == 2)
	notebook.state_option.select(3)
	notebook._on_filters_changed(0)
	_check("Notebook Needs Practice excludes new cards", notebook._filtered_words.size() == 1 and notebook._filtered_words[0].id == "n5_001")
	notebook._show_detail(VocabDatabase.get_word_by_id("n5_001"))
	var audio_button: Button = null
	for child in notebook.detail_container.get_children():
		if child is Button:
			audio_button = child
	_check("Notebook detail provides audio", audio_button != null and not audio_button.disabled)
	if audio_button:
		audio_button.pressed.emit()
		_check("Notebook plays selected pronunciation", AudioManager._active_speech_id == "vocab:n5_001")
	notebook.search_field.text = "no_such_entry_12345"
	notebook._on_filters_changed("")
	_check("Notebook explains empty results", notebook._filtered_words.is_empty() and notebook.result_label.text == "No words match these filters.")
	_check("Notebook does not mutate learning or rewards", SRSEngine.cards.size() == 2 and SRSEngine.get_due_count() == before_due and profile.xp == 0 and profile.coffee_beans == 0)
	notebook.free()
	GameController.current_profile = null
	SRSEngine.cards = []
	notebook = load("res://Scenes/StudyNotebook/study_notebook.tscn").instantiate()
	add_child(notebook)
	_check("Notebook supports no-profile browsing", notebook._filtered_words.size() == 800)
	notebook.free()


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
