extends Control

var _passes := 0
var _failures := 0


func _ready() -> void:
	var saved_cards := SRSEngine.cards
	var saved_kanji := SRSEngine.kanji_cards
	var saved_profile := GameController.current_profile
	var saved_config := GameController.session_data
	await _test_orders()
	await _test_difficulty()
	await _test_mixed_orders()
	await _test_n4_reading()
	await _test_reading()
	await _test_kanji()
	await _test_n4_kanji()
	SRSEngine.cards = saved_cards
	SRSEngine.kanji_cards = saved_kanji
	GameController.current_profile = saved_profile
	GameController.session_data = saved_config
	AudioManager.stop_speech()
	AudioManager.stop_bgm(0.0)
	for player in AudioManager._sfx_players:
		player.stop()
	await get_tree().create_timer(0.6).timeout
	print("v0.5 activity tests: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _profile(name: String) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_name = name
	profile.settings["target_jlpt_level"] = 5
	profile.settings["target_lesson"] = 5
	profile.settings["new_cards_per_session"] = 5
	profile.settings["difficulty"] = "standard"
	GameController.current_profile = profile
	return profile


func _test_orders() -> void:
	_profile("OrdersTest")
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "cafe_orders", "words_per_session": 10}
	var orders = load("res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn").instantiate()
	add_child(orders)
	_check("Orders use five new menu items", orders._session_menu.size() == 5)
	_check("Order timer waits for audio", orders._audio_active and not orders._timer_active)
	AudioManager.stop_speech()
	orders._on_speech_finished(orders._session_menu[0]["order_clip"])
	_check("Order timer starts after audio", orders._timer_active)
	var first_card: SRSCard = orders._session_cards[0]
	orders._finish_answer(orders._correct_btn_index)
	_check("Unassisted order records Listening", first_card.skill_evidence.has("listening") and first_card.skill_evidence["listening"].attempts == 1)
	await get_tree().create_timer(2.0).timeout
	orders._activate_assist("Test assist")
	var second_card: SRSCard = orders._session_cards[1]
	orders._finish_answer(orders._correct_btn_index)
	_check("Assisted order records Meaning", second_card.skill_evidence.has("meaning") and not second_card.skill_evidence.has("listening"))
	_check("Assist count recorded", orders._assisted_count == 1)
	await get_tree().create_timer(2.0).timeout
	AudioManager.stop_speech()
	orders.free()


func _test_reading() -> void:
	var profile := _profile("ReadingTest")
	profile.settings["target_jlpt_level"] = 0
	profile.settings["target_lesson"] = 5
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "reading_shelf", "words_per_session": 5}
	var reading = load("res://Scenes/MiniGames/ReadingShelf/reading_shelf.tscn").instantiate()
	add_child(reading)
	_check("Professional reading builds Lesson 5 source text", reading._session_passages.size() == 1)
	_check("Reading uses professional Japanese lines", not reading._session_passages[0]["japanese_lines"].is_empty() and reading._session_passages[0]["source_file"].contains("第5课"))
	_check("Passage-only reading has no fabricated question", reading._session_passages[0]["question"] == "" and reading.answer_btns[0].text == "Finish Reading")
	_check("Passage-only reading creates no SRS cards", reading._session_cards.is_empty() and SRSEngine.cards.is_empty() and reading._correct_count == 0)
	reading.free()


func _test_kanji() -> void:
	_profile("KanjiTest")
	SRSEngine.kanji_cards = []
	var entries := VocabDatabase.get_kanji_by_jlpt(5)
	var initial: Array[KanjiCard] = []
	for i in 5:
		var card := KanjiCard.new()
		card.setup(entries[i].character)
		initial.append(card)
	SRSEngine.kanji_cards = initial
	GameController.session_data = {"game_type": "kanji_workshop", "words_per_session": 8}
	var workshop = load("res://Scenes/MiniGames/KanjiWorkshop/kanji_workshop.tscn").instantiate()
	workshop._forced_exercise = "meaning"
	add_child(workshop)
	_check("Workshop combines due and new kanji", workshop._session_entries.size() == 8)
	var correct_index := 0
	for i in 4:
		if workshop.answer_btns[i].text == workshop._correct_answer:
			correct_index = i
	var card: SRSCard = workshop._session_cards[0]
	workshop._on_answer_pressed(correct_index)
	_check("Kanji scheduled once", card.total_reviews == 1 and card.skill_evidence["meaning"].attempts == 1)
	await get_tree().create_timer(2.0).timeout
	workshop._build_question(entries[0], "reading")
	var valid_readings := entries[0].get_all_readings()
	var valid_count := 0
	for button in workshop.answer_btns:
		if button.text in valid_readings:
			valid_count += 1
	_check("Reading choices are unambiguous", valid_count == 1)
	var form_entry: KanjiEntry = null
	for entry in entries:
		if not entry.components.is_empty():
			form_entry = entry
			break
	workshop._build_question(form_entry, "form")
	_check("Form question uses authored component", workshop._correct_answer in form_entry.components)
	workshop.free()


func _test_difficulty() -> void:
	var profile := _profile("DifficultyTest")
	profile.settings["target_jlpt_level"] = 4
	var expected_times := {"relaxed": 15.0, "standard": 12.0, "challenge": 8.0}
	var quiz_script = load("res://Scenes/MiniGames/MultipleChoice/multiple_choice.gd")
	var quiz = quiz_script.new()
	var word: VocabWord = null
	for candidate in VocabDatabase.get_words_by_jlpt(4):
		if candidate.has_meaning():
			word = candidate
			break
	for mode in expected_times:
		profile.settings["difficulty"] = mode
		SRSEngine.cards = []
		GameController.session_data = {"game_type": "cafe_orders", "words_per_session": 10}
		var orders = load("res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn").instantiate()
		add_child(orders)
		_check("%s Orders keep the independent legacy supplement" % mode.capitalize(), orders._session_menu.size() == 5 and orders._session_words.all(func(item: VocabWord) -> bool: return item.content_source == "legacy_cafe"))
		_check("%s Orders timer is %.0f seconds" % [mode.capitalize(), expected_times[mode]], orders._get_order_time() == expected_times[mode])
		orders.free()
		var filters: Dictionary = quiz._get_distractor_filters(word)
		if mode == "relaxed":
			_check("Relaxed uses closer professional distractors", filters.has("lesson") and filters.has("part_of_speech"))
		elif mode == "standard":
			_check("Standard retains lesson distractors", filters.has("lesson") and not filters.has("part_of_speech"))
		else:
			_check("Challenge broadens distractors within JLPT level", not filters.has("lesson") and filters.get("jlpt_level") == 4)
		var base := MiniGameBase.new()
		base._game_type = "difficulty_test"
		var card := SRSCard.new()
		card.vocab_id = "n4_691"
		base._report_correct(card, SRSEngine.Quality.GOOD, "meaning")
		_check("%s preserves SRS and XP outcomes" % mode.capitalize(), card.repetitions == 1 and card.interval == 1.0 and base._total_xp == 10)
		base.free()
	quiz.free()


func _test_mixed_orders() -> void:
	var profile := _profile("MixedOrdersTest")
	profile.settings["target_jlpt_level"] = 1
	profile.settings["target_lesson"] = 1
	profile.settings["new_cards_per_session"] = 0
	SRSEngine.cards = []
	SRSEngine.add_new_cards(PackedStringArray(["n5_011", "n4_691"]))
	GameController.session_data = {"game_type": "cafe_orders", "words_per_session": 10}
	var orders = load("res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn").instantiate()
	add_child(orders)
	var levels: Dictionary = {}
	for word in orders._session_words:
		levels[word.jlpt_level] = true
	_check("Mixed due-only Orders include N5 and N4", levels.has(5) and levels.has(4) and orders._session_menu.size() == 2)
	orders.free()


func _test_n4_reading() -> void:
	var profile := _profile("ProfessionalReadingTest")
	profile.settings["target_jlpt_level"] = 0
	profile.settings["target_lesson"] = 26
	SRSEngine.cards = []
	GameController.session_data = {"game_type": "reading_shelf", "words_per_session": 5}
	var reading = load("res://Scenes/MiniGames/ReadingShelf/reading_shelf.tscn").instantiate()
	add_child(reading)
	var valid: bool = reading._session_passages.size() == 1
	for passage in reading._session_passages:
		if int(passage.get("lesson", 0)) != 26 or not passage.get("source_file", "").contains("第26课"):
			valid = false
	_check("Reading Shelf builds professional Lesson 26 text", valid)
	_check("Advanced reading remains unscored without authored comprehension", reading._session_cards.is_empty() and reading._session_passages[0]["question"] == "")
	reading.free()


func _test_n4_kanji() -> void:
	var profile := _profile("N4KanjiTest")
	profile.settings["target_jlpt_level"] = 4
	SRSEngine.kanji_cards = []
	GameController.session_data = {"game_type": "kanji_workshop", "words_per_session": 8}
	var workshop = load("res://Scenes/MiniGames/KanjiWorkshop/kanji_workshop.tscn").instantiate()
	workshop._forced_exercise = "meaning"
	add_child(workshop)
	var valid: bool = workshop._session_entries.size() == 3 and SRSEngine.kanji_cards.size() == 3
	for entry in workshop._session_entries:
		if entry.jlpt_level != 4:
			valid = false
	_check("N4 Workshop uses N4 kanji and three new cards", valid)
	workshop._build_question(workshop._session_entries[0], "reading")
	_check("N4 reading exercise has four choices", workshop.answer_btns.all(func(button: Button) -> bool: return button.text != ""))
	workshop.free()


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
