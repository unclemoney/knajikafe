extends Control

const CAPTURE_DIR := "res://build/captures"
const SCENES := [
	{"name": "orders_n4", "path": "res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn", "game_type": "cafe_orders"},
	{"name": "reading_n4", "path": "res://Scenes/MiniGames/ReadingShelf/reading_shelf.tscn", "game_type": "reading_shelf"},
	{"name": "workshop_n4", "path": "res://Scenes/MiniGames/KanjiWorkshop/kanji_workshop.tscn", "game_type": "kanji_workshop"},
	{"name": "listening_n4", "path": "res://Scenes/MiniGames/ListeningLab/listening_lab.tscn", "game_type": "listening_lab", "submit": true},
	{"name": "notebook_n4", "path": "res://Scenes/StudyNotebook/study_notebook.tscn", "game_type": "study_notebook", "detail": true},
	{"name": "settings", "path": "res://Scenes/Settings/settings.tscn", "game_type": ""},
	{"name": "stats_n4", "path": "res://Scenes/Stats/stats_screen.tscn", "game_type": ""},
	{"name": "register_picker", "path": "res://Scenes/CafeHub/cafe_hub.tscn", "game_type": "", "picker": "_on_typing_pressed"},
	{"name": "bookshelf_picker", "path": "res://Scenes/CafeHub/cafe_hub.tscn", "game_type": "", "picker": "_on_fill_blank_pressed"},
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
			var scene = load(definition["path"]).instantiate()
			add_child(scene)
			if definition.has("picker"):
				scene.call(definition["picker"])
			if definition.get("detail", false):
				scene._show_detail(scene._filtered_words[0])
			if definition.get("submit", false):
				scene.input_field.text = scene._session_words[0].hiragana
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
	profile.settings["target_jlpt_level"] = 4
	profile.settings["target_topic"] = "all"
	profile.settings["new_cards_per_session"] = 5
	profile.settings["difficulty"] = "standard"
	GameController.current_profile = profile
	GameController.session_data = {"game_type": game_type, "words_per_session": 10}
	SRSEngine.cards = []
	SRSEngine.kanji_cards = []
	var ids := PackedStringArray()
	for i in range(1, 21):
		ids.append("n4_%03d" % i)
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
