extends Control

var _passes := 0
var _failures := 0


func _ready() -> void:
	var saved_profile := GameController.current_profile
	var saved_cards := SRSEngine.cards
	var saved_kanji := SRSEngine.kanji_cards
	var saved_sessions := SRSEngine.sessions
	var saved_manifest := AudioManager._audio_manifest.duplicate()
	_test_catalog()
	_test_planner()
	_test_metrics()
	await _test_motion()
	await _test_focus()
	await _test_audio()
	GameController.current_profile = saved_profile
	SRSEngine.cards = saved_cards
	SRSEngine.kanji_cards = saved_kanji
	SRSEngine.sessions = saved_sessions
	AudioManager._audio_manifest = saved_manifest
	AudioManager.stop_bgm(0.0)
	await get_tree().create_timer(0.1).timeout
	print("v0.9 release tests: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _profile(level: int = 5, topic: String = "all", new_cards: int = 5) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_name = "V09Test"
	profile.settings["target_jlpt_level"] = level
	profile.settings["target_topic"] = topic
	profile.settings["new_cards_per_session"] = new_cards
	GameController.current_profile = profile
	return profile


func _card(word_id: String, due: bool = false) -> SRSCard:
	var card := SRSCard.new()
	card.vocab_id = word_id
	card.next_review_date = "2020-01-01" if due else "2999-01-01"
	return card


func _test_catalog() -> void:
	var ids: Dictionary = {}
	var paths_valid := true
	for activity in ActivityCatalog.ACTIVITIES:
		ids[activity["game_type"]] = true
		if not ResourceLoader.exists(activity["scene_path"]):
			paths_valid = false
	_check("Catalog contains nine unique activities", ids.size() == 9 and ActivityCatalog.ACTIVITIES.size() == 9)
	_check("Catalog scene paths are valid", paths_valid)
	var profile := _profile()
	_check("Catalog preserves fixed session sizes", ActivityCatalog.get_config("kanji_matching", profile)["words_per_session"] == 6 and ActivityCatalog.get_config("reading_shelf", profile)["words_per_session"] == 5)
	_check("Catalog preserves Notebook reference", ActivityCatalog.get_station_options("bookshelf", profile).size() == 3)


func _test_planner() -> void:
	var profile := _profile()
	SRSEngine.cards = []
	SRSEngine.kanji_cards = []
	SRSEngine.sessions = []
	var recommendation := StudyPlanner.get_recommendation()
	_check("New profile receives N5 Multiple Choice", recommendation.get("game_type") == "multiple_choice")
	var before_xp := profile.xp
	var before_beans := profile.coffee_beans
	var repeated := StudyPlanner.get_recommendation()
	_check("Recommendations are deterministic", recommendation == repeated)
	_check("Recommendations have no progression side effects", SRSEngine.cards.is_empty() and profile.xp == before_xp and profile.coffee_beans == before_beans)
	var cards: Array[SRSCard] = []
	for i in range(1, 7):
		cards.append(_card("n5_%03d" % i))
	var evidence := SkillEvidence.new()
	for i in 6:
		evidence.record(SRSEngine.Quality.GOOD if i < 3 else SRSEngine.Quality.WRONG, "2026-01-01", "listening_lab")
	cards[0].skill_evidence["listening"] = evidence
	SRSEngine.cards = cards
	recommendation = StudyPlanner.recommend(profile, cards, [], [])
	_check("Weak Listening recommends a listening activity", recommendation.get("game_type") in ["listening_lab", "cafe_orders"])
	_check("Recommendation explains evidence", str(recommendation.get("reason", "")).contains("Listening"))
	profile.settings["target_jlpt_level"] = 0
	profile.settings["new_cards_per_session"] = 0
	var due_cards: Array[SRSCard] = [_card("n5_001", true), _card("n4_001", true)]
	recommendation = StudyPlanner.recommend(profile, due_cards, [], [])
	_check("Due-only Mixed recommendation remains available", recommendation.get("game_type") not in ["", "study_notebook"])
	profile.settings["target_jlpt_level"] = 4
	var empty_topic := ""
	for category in VocabDatabase.get_categories():
		if VocabDatabase.get_random_words(1, PackedStringArray(), {"jlpt_level": 4, "category": category}).is_empty():
			empty_topic = category
			break
	profile.settings["target_topic"] = empty_topic
	recommendation = StudyPlanner.recommend(profile, [], [], [])
	_check("Empty filters recommend Notebook without substitution", recommendation.get("game_type") == "study_notebook")
	profile.settings["target_topic"] = "all"
	profile.settings["target_jlpt_level"] = 5
	profile.settings["new_cards_per_session"] = 0
	var menu_due: Array[SRSCard] = [_card("n5_011", true)]
	var saved_vocab: String = AudioManager._audio_manifest["vocab:n5_011"]
	var saved_order: String = AudioManager._audio_manifest["order:n5_011"]
	AudioManager._audio_manifest.erase("vocab:n5_011")
	AudioManager._audio_manifest.erase("order:n5_011")
	recommendation = StudyPlanner.recommend(profile, menu_due, [], [])
	_check("Unavailable audio excludes audio-only recommendations", recommendation.get("game_type") not in ["listening_lab", "cafe_orders"])
	AudioManager._audio_manifest["vocab:n5_011"] = saved_vocab
	AudioManager._audio_manifest["order:n5_011"] = saved_order


func _test_metrics() -> void:
	_check("Evidence labels cover zero and early samples", ProgressMetrics.get_evidence_label(0, 0.0) == "No Evidence" and ProgressMetrics.get_evidence_label(4, 1.0) == "Early Evidence")
	_check("Developing begins at five attempts", ProgressMetrics.get_evidence_label(5, 1.0) == "Developing")
	_check("Consistency requires ten attempts and 80%", ProgressMetrics.get_evidence_label(10, 0.8) == "Consistent" and ProgressMetrics.get_evidence_label(10, 0.79) == "Developing")
	var n5 := _card("n5_001")
	var n4 := _card("n4_001")
	var n5_evidence := SkillEvidence.new()
	n5_evidence.record(SRSEngine.Quality.GOOD, "2026-01-02", "multiple_choice")
	n5_evidence.record(SRSEngine.Quality.WRONG, "2026-01-03", "multiple_choice")
	var n4_evidence := SkillEvidence.new()
	n4_evidence.record(SRSEngine.Quality.GOOD, "2026-01-04", "multiple_choice")
	n5.skill_evidence["meaning"] = n5_evidence
	n4.skill_evidence["meaning"] = n4_evidence
	var cards: Array[SRSCard] = [n5, n4]
	var n5_summary := ProgressMetrics.get_skill_summary(cards, [], 5)
	var mixed_summary := ProgressMetrics.get_skill_summary(cards, [], 0)
	_check("Skill summaries filter by level", n5_summary["meaning"]["attempts"] == 2 and mixed_summary["meaning"]["attempts"] == 3)
	_check("Skill summaries include lapses and latest practice", n5_summary["meaning"]["lapses"] == 1 and mixed_summary["meaning"]["last_practice"] == "2026-01-04")
	_check("Summary labels use shared thresholds", mixed_summary["meaning"]["evidence_label"] == "Early Evidence")


func _test_motion() -> void:
	var profile := _profile()
	profile.settings["reduced_motion"] = true
	_check("Reduced motion reads active profile", MotionManager.is_reduced())
	var label := Label.new()
	add_child(label)
	label.modulate.a = 0.0
	MotionManager.fade_in(label, 1.0)
	_check("Reduced fade reaches final state immediately", label.modulate.a == 1.0)
	label.scale = Vector2.ZERO
	MotionManager.pop_in(label, 1.0)
	_check("Reduced pop reaches final scale immediately", label.scale == Vector2.ONE)
	await GameController._fade_out()
	_check("Reduced scene fade out is immediate", GameController._transition_rect.color.a == 1.0)
	await GameController._fade_in()
	_check("Reduced scene fade in is immediate", GameController._transition_rect.color.a == 0.0)
	label.free()
	GameController._transition_in_progress = true
	GameController.change_scene("res://unused.tscn")
	_check("Reentrant scene request is rejected", GameController.current_scene_path != "res://unused.tscn")
	GameController._transition_in_progress = false


func _test_focus() -> void:
	var previous := Button.new()
	add_child(previous)
	previous.grab_focus()
	var picker := StationModePicker.new()
	add_child(picker)
	picker.open("Test", [ActivityCatalog.get_option("multiple_choice", GameController.current_profile)])
	_check("Picker focuses first activity", get_viewport().gui_get_focus_owner() == picker._options_box.get_child(0))
	var event := InputEventAction.new()
	event.action = "ui_focus_next"
	event.pressed = true
	picker._input(event)
	_check("Picker wraps keyboard focus", get_viewport().gui_get_focus_owner() == picker._cancel_btn)
	picker._close()
	await get_tree().process_frame
	_check("Picker restores previous focus", get_viewport().gui_get_focus_owner() == previous)
	previous.free()


func _test_audio() -> void:
	AudioManager.play_bgm(AudioManager._bgm_cafe, 0.05)
	AudioManager.play_bgm(AudioManager._bgm_quiz, 0.05)
	AudioManager.play_bgm(AudioManager._bgm_results, 0.05)
	await get_tree().create_timer(0.3).timeout
	_check("Latest rapid crossfade remains active", AudioManager._bgm_player.stream == AudioManager._bgm_results and AudioManager._bgm_player.playing)
	_check("Completed crossfade clears tween reference", AudioManager._bgm_tween == null)
	var inactive_stopped := true
	for player in AudioManager._bgm_players:
		if player != AudioManager._bgm_player and player.playing:
			inactive_stopped = false
	_check("Crossfade stops obsolete player", inactive_stopped)
	AudioManager.stop_bgm(0.0)
	_check("Immediate stop releases BGM streams", AudioManager._bgm_players.all(func(player: AudioStreamPlayer) -> bool: return player.stream == null and not player.playing))


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
