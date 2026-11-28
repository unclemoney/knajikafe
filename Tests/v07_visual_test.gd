extends Control

const CAPTURE_DIR := "res://build/captures"
const SCENES := [
	{"name": "orders_n4", "path": "res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn", "game_type": "cafe_orders"},
	{"name": "reading_n4", "path": "res://Scenes/MiniGames/ReadingShelf/reading_shelf.tscn", "game_type": "reading_shelf"},
	{"name": "workshop_n4", "path": "res://Scenes/MiniGames/KanjiWorkshop/kanji_workshop.tscn", "game_type": "kanji_workshop"},
	{"name": "listening_n4", "path": "res://Scenes/MiniGames/ListeningLab/listening_lab.tscn", "game_type": "listening_lab", "submit": true},
	{"name": "notebook_n4", "path": "res://Scenes/StudyNotebook/study_notebook.tscn", "game_type": "study_notebook", "detail": true},
	{"name": "notebook_grammar", "path": "res://Scenes/StudyNotebook/study_notebook.tscn", "game_type": "study_notebook", "grammar": true},
	{"name": "fill_blank_lesson5", "path": "res://Scenes/MiniGames/FillInBlank/fill_in_blank.tscn", "game_type": "fill_in_blank"},
	{"name": "settings", "path": "res://Scenes/Settings/settings.tscn", "game_type": ""},
	{"name": "stats_n4", "path": "res://Scenes/Stats/stats_screen.tscn", "game_type": ""},
	{"name": "register_picker", "path": "res://Scenes/CafeHub/cafe_hub.tscn", "game_type": "", "picker": "_on_typing_pressed"},
	{"name": "bookshelf_picker", "path": "res://Scenes/CafeHub/cafe_hub.tscn", "game_type": "", "picker": "_on_fill_blank_pressed"},
	{"name": "menu_board_picker", "path": "res://Scenes/CafeHub/cafe_hub.tscn", "game_type": "", "picker": "_on_quiz_pressed"},
	{"name": "results_n4", "path": "res://Scenes/Results/results_screen.tscn", "game_type": "", "results": true},
	{"name": "lessons", "path": "res://Scenes/Lessons/lessons_screen.tscn", "game_type": "lessons"},
	{"name": "lesson_test", "path": "res://Scenes/Lessons/lesson_test.tscn", "game_type": "lesson_test"},
	{"name": "lesson_translation", "path": "res://Scenes/Lessons/lesson_test.tscn", "game_type": "lesson_translation"},
	{"name": "lesson_test_failed", "path": "res://Scenes/Results/results_screen.tscn", "game_type": "", "lesson_test_results": false},
	{"name": "lesson_test_passed", "path": "res://Scenes/Results/results_screen.tscn", "game_type": "", "lesson_test_results": true},
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(CAPTURE_DIR)
	for resolution in [Vector2i(640, 360), Vector2i(1280, 720)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		await get_tree().process_frame
		await get_tree().process_frame
		for definition in SCENES:
			_setup_profile(definition["game_type"])
			if definition.get("results", false):
				GameController.session_data = {"game_type": "multiple_choice", "item_label": "Words", "words_reviewed": 10, "correct_count": 8, "xp_earned": 80, "base_xp": 80, "streak_multiplier": 1.0, "skill_results": {"meaning": {"correct": 8, "attempts": 10}}, "recommendation": StudyPlanner.get_recommendation()}
			if definition.has("lesson_test_results"):
				var passed: bool = definition["lesson_test_results"]
				GameController.session_data = {"result_kind": "lesson_test", "lesson_number": 5, "correct_count": 18 if passed else 12, "vocabulary_correct": 9 if passed else 7, "cloze_correct": 9 if passed else 5, "passed": passed, "practice_required": not passed, "save_ok": true, "newly_unlocked": 6 if passed else 0, "best_score": 18 if passed else 12, "attempts": 2}
			var scene = load(definition["path"]).instantiate()
			add_child(scene)
			if definition.has("picker"):
				scene.call(definition["picker"])
			if definition["game_type"] == "lesson_translation":
				for index in scene._questions.size():
					if scene._questions[index].get("question_format", "") == "word_translation":
						scene._questions.insert(0, scene._questions.pop_at(index))
						scene._show_question()
						break
			if definition.get("grammar", false):
				scene._mode_option.select(1)
				scene.topic_option.select(scene.topic_option.get_item_index(5))
				scene._on_filters_changed(0)
				scene._show_grammar_detail(scene._filtered_grammar[0])
			elif definition.get("detail", false):
				scene._show_detail(scene._filtered_words[0])
			if definition.get("submit", false):
				scene.input_field.text = scene._session_words[0].get_reading()
				scene._on_submit_pressed()
			await get_tree().create_timer(0.25).timeout
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var filename := "%s/%s_%dx%d.png" % [CAPTURE_DIR, definition["name"], resolution.x, resolution.y]
			var result := image.save_png(filename)
			print("Capture ", filename, ": ", error_string(result), " ", image.get_size())
			AudioManager.stop_speech()
			AudioManager.stop_bgm(0.0)
			scene.free()
			await get_tree().process_frame
	get_tree().quit()


func _setup_profile(game_type: String) -> void:
	var profile := PlayerProfile.new()
	profile.player_name = "__v07_visual__"
	profile.xp = 450
	profile.add_xp(0)
	profile.coffee_beans = 120
	profile.has_completed_tutorial = true
	for achievement in AchievementManager.get_all_achievements():
		profile.unlocked_achievements.append(achievement.id)
	profile.settings["target_jlpt_level"] = 0 if game_type == "fill_in_blank" else 4
	profile.settings["target_lesson"] = 26 if game_type == "reading_shelf" else 5
	if game_type == "lesson_translation":
		profile.settings["target_lesson"] = 1
	profile.current_lesson = int(profile.settings["target_lesson"])
	profile.highest_unlocked_lesson = profile.current_lesson
	profile.settings["new_cards_per_session"] = 5
	profile.settings["difficulty"] = "standard"
	profile.settings["reduced_motion"] = true
	GameController.current_profile = profile
	GameController.session_data = {"game_type": game_type, "words_per_session": 10}
	SRSEngine.cards = []
	SRSEngine.kanji_cards = []
	var ids := PackedStringArray()
	for word in VocabDatabase.get_words_by_jlpt(4).slice(0, 20):
		ids.append(word.id)
	for i in range(691, 701):
		ids.append("n4_%03d" % i)
	var cards := SRSEngine.add_new_cards(ids)
	for i in mini(5, cards.size()):
		cards[i].total_reviews = 2
		cards[i].correct_reviews = 1
		cards[i].next_review_date = "2026-01-01"
	var kanji_ids := PackedStringArray()
	for entry in VocabDatabase.get_kanji_by_jlpt(4).slice(0, 5):
		kanji_ids.append(entry.character)
	SRSEngine.add_new_kanji_cards(kanji_ids)
