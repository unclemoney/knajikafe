extends Control
## DataLayerTest
##
## Test scene that exercises VocabDatabase, SaveManager, and SRSEngine.
## Press "Run All Tests" to execute. Results appear in the output panel.

const TEST_PROFILE_NAME: String = "__test_profile__"

@onready var output: RichTextLabel = %"Output" if has_node("%Output") else $VBoxContainer/Output
@onready var run_btn: Button = $VBoxContainer/HBox/RunAllBtn
@onready var clear_btn: Button = $VBoxContainer/HBox/ClearBtn

var _pass_count: int = 0
var _fail_count: int = 0


func _ready() -> void:
	run_btn.pressed.connect(_on_run_all)
	clear_btn.pressed.connect(_on_clear)
	_log("[b]KanjiKafe Data Layer Test[/b]")
	_log("Press 'Run All Tests' to begin.\n")
	if OS.get_cmdline_user_args().has("--run-all"):
		call_deferred("_run_all_headless")


func _run_all_headless() -> void:
	_on_run_all()
	get_tree().quit(0 if _fail_count == 0 else 1)


func _on_run_all() -> void:
	_pass_count = 0
	_fail_count = 0
	output.clear()
	_log("[b]===== Running All Data Layer Tests =====[/b]\n")

	_test_vocab_database()
	_test_production_resources()
	_test_save_manager()
	_test_learning_data_migration()
	_test_srs_engine()
	_test_curriculum_settings()
	_cleanup()

	_log("\n[b]===== Results =====[/b]")
	if _fail_count == 0:
		_log("[color=green]ALL PASSED: %d tests[/color]" % _pass_count)
	else:
		_log("[color=red]FAILED: %d  |  PASSED: %d[/color]" % [_fail_count, _pass_count])


func _on_clear() -> void:
	output.clear()


# ── VocabDatabase Tests ──────────────────────────────────────────────

func _test_vocab_database() -> void:
	_log("[b]── VocabDatabase ──[/b]")

	# Test: words loaded
	var count := VocabDatabase.get_word_count()
	_assert("Words loaded > 0", count > 0, "got %d" % count)

	# Test: get_word_by_id
	var word := VocabDatabase.get_word_by_id("n5_001")
	_assert("get_word_by_id('n5_001') found", word != null, "")
	if word:
		_assert("  word.romaji == 'konnichiwa'", word.romaji == "konnichiwa", "got '%s'" % word.romaji)
		_assert("  word.jlpt_level == 5", word.jlpt_level == 5, "got %d" % word.jlpt_level)

	# Test: get_words_by_jlpt
	var n5_words := VocabDatabase.get_words_by_jlpt(5)
	_assert("N5 has 800 words", n5_words.size() == 800, "got %d" % n5_words.size())
	var n4_words := VocabDatabase.get_words_by_jlpt(4)
	_assert("N4 has 700 words", n4_words.size() == 700, "got %d" % n4_words.size())
	_assert("Combined curriculum has 1500 words", count == 1500, "got %d" % count)
	var examples_valid := true
	for n5_word in n5_words:
		if n5_word.example_sentences.is_empty():
			examples_valid = false
		for example in n5_word.example_sentences:
			var parts := example.split("|")
			if parts.size() != 2 or n5_word.get_display_text() not in parts[0] or parts[1].strip_edges() == "":
				examples_valid = false
	_assert("All N5 examples are valid", examples_valid, "")
	_assert("N5 has 100 kanji", VocabDatabase.get_kanji_by_jlpt(5).size() == 100, "")
	_assert("N4 has 200 kanji", VocabDatabase.get_kanji_by_jlpt(4).size() == 200, "")
	_assert("Curriculum has 300 unique kanji", VocabDatabase.get_kanji_count() == 300, "got %d" % VocabDatabase.get_kanji_count())
	var kanji_entry := VocabDatabase.get_kanji("一")
	_assert("Kanji fields load", kanji_entry != null and not kanji_entry.meanings.is_empty() and not kanji_entry.get_all_readings().is_empty(), "")
	_assert("All 60 reading passages load", VocabDatabase.reading_passages.size() == 60, "")
	_assert("All 20 cafe menu entries load", VocabDatabase.cafe_menu.size() == 20, "")
	_assert("Vocabulary speech available", AudioManager.has_speech("vocab:n5_001"), "")
	_assert("Order speech available", AudioManager.has_speech("order:n5_011"), "")
	var menu_resources_valid := true
	for item in VocabDatabase.cafe_menu:
		if not ResourceLoader.exists(item["texture"]):
			menu_resources_valid = false
	_assert("Menu textures load", menu_resources_valid, "")
	var manifest_file := FileAccess.open("res://Resources/Audio/japanese_audio_manifest.json", FileAccess.READ)
	var manifest: Array = JSON.parse_string(manifest_file.get_as_text()) if manifest_file else []
	if manifest_file:
		manifest_file.close()
	var audio_ready := manifest.size() == 1520
	for clip in manifest:
		if clip.get("status", "") != "ready" or not FileAccess.file_exists(clip.get("file", "")):
			audio_ready = false
	_assert("All 1520 Japanese audio clips are ready", audio_ready, "got %d" % manifest.size())
	var source_words_by_id: Dictionary = {}
	for level in [5, 4]:
		var source_file := FileAccess.open("res://Resources/Vocabulary/n%d_vocab.json" % level, FileAccess.READ)
		var source_words: Array = JSON.parse_string(source_file.get_as_text())
		source_file.close()
		for source_word in source_words:
			source_words_by_id[source_word["id"]] = source_word
	var drafts_valid := true
	for source_vocab_word in VocabDatabase.get_all_words():
		var number := int(source_vocab_word.id.right(3))
		if (source_vocab_word.jlpt_level == 5 and number > 120) or (source_vocab_word.jlpt_level == 4 and number > 100):
			if source_words_by_id[source_vocab_word.id].get("review_status", "") not in ["draft_pending_human_review", "needs_correction", "human_reviewed"]:
				drafts_valid = false
	_assert("Imported vocabulary has valid review states", drafts_valid, "")

	# Test: get_words_by_category
	var cafe_words := VocabDatabase.get_words_by_category("cafe")
	_assert("get_words_by_category('cafe') > 0", cafe_words.size() > 0, "got %d" % cafe_words.size())

	var verb_words := VocabDatabase.get_words_by_category("verbs")
	_assert("get_words_by_category('verbs') > 0", verb_words.size() > 0, "got %d" % verb_words.size())

	# Test: get_random_words
	var random := VocabDatabase.get_random_words(5)
	_assert("get_random_words(5) returns 5", random.size() == 5, "got %d" % random.size())

	# Test: get_random_words with exclusion
	var exclude := PackedStringArray(["n5_001", "n5_002", "n5_003"])
	var random_excl := VocabDatabase.get_random_words(3, exclude)
	var has_excluded := false
	for w in random_excl:
		if w.id in exclude:
			has_excluded = true
	_assert("get_random_words excludes IDs", not has_excluded, "")

	# Test: get_all_words
	var all := VocabDatabase.get_all_words()
	_assert("get_all_words() == get_word_count()", all.size() == count, "got %d vs %d" % [all.size(), count])

	# Test: katakana word (bread)
	var bread := VocabDatabase.get_word_by_id("n5_014")
	if bread:
		_assert("Katakana word has katakana", bread.katakana == "パン", "got '%s'" % bread.katakana)
		_assert("Katakana word get_display_text()", bread.get_display_text() == "パン", "got '%s'" % bread.get_display_text())

	# Test: word helper methods
	if word:
		_assert("get_display_text() returns hiragana for kana-only", word.get_display_text() == "こんにちは", "got '%s'" % word.get_display_text())
		_assert("get_primary_meaning() returns first meaning", word.get_primary_meaning() == "hello", "got '%s'" % word.get_primary_meaning())

	var kanji_word := VocabDatabase.get_word_by_id("n5_025")
	if kanji_word:
		_assert("get_display_text() returns kanji when present", kanji_word.get_display_text() == "五", "got '%s'" % kanji_word.get_display_text())

	_log("")


# ── Production Resource Tests ─────────────────────────────────────────


func _test_production_resources() -> void:
	_log("[b]── Production Resources ──[/b]")

	var achievements := AchievementManager.get_all_achievements()
	_assert("All 26 achievements load", achievements.size() == 26, "got %d" % achievements.size())
	var achievement_ids: Dictionary = {}
	for achievement in achievements:
		achievement_ids[achievement.id] = true
	_assert("Achievement IDs are unique", achievement_ids.size() == achievements.size(), "")

	_assert("All 6 cats load", _count_resources("res://Resources/Cats/", "CatCharacter") == 6, "")
	_assert("All 16 decorations load", _count_resources("res://Resources/Decorations/", "CafeDecoration") == 16, "")
	_assert("Japanese font loads", load("res://Themes/japanese_font.tres") is Font, "")

	var decoration_textures_valid := true
	var decoration_dir := DirAccess.open("res://Resources/Decorations/")
	if decoration_dir:
		decoration_dir.list_dir_begin()
		var file_name := decoration_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var decor := load("res://Resources/Decorations/" + file_name) as CafeDecoration
				if decor == null or decor.texture == null or decor.cafe_size.x <= 0 or decor.cafe_size.y <= 0:
					decoration_textures_valid = false
			file_name = decoration_dir.get_next()
		decoration_dir.list_dir_end()
	_assert("Decoration textures and placement sizes are valid", decoration_textures_valid, "")

	var required_scenes: PackedStringArray = [
		"res://Scenes/TitleScreen/title_screen.tscn",
		"res://Scenes/ProfileSelect/profile_select.tscn",
		"res://Scenes/CafeHub/cafe_hub.tscn",
		"res://Scenes/MiniGames/MultipleChoice/multiple_choice.tscn",
		"res://Scenes/MiniGames/FlashcardReview/flashcard_review.tscn",
		"res://Scenes/MiniGames/KanjiMatching/kanji_matching.tscn",
		"res://Scenes/MiniGames/FillInBlank/fill_in_blank.tscn",
		"res://Scenes/MiniGames/TypingInput/typing_input.tscn",
		"res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn",
		"res://Scenes/MiniGames/ReadingShelf/reading_shelf.tscn",
		"res://Scenes/MiniGames/KanjiWorkshop/kanji_workshop.tscn",
		"res://Scenes/MiniGames/ListeningLab/listening_lab.tscn",
		"res://Scenes/StudyNotebook/study_notebook.tscn",
		"res://Scenes/Results/results_screen.tscn",
		"res://Scenes/Stats/stats_screen.tscn",
	]
	var missing_scenes: PackedStringArray = []
	for scene_path in required_scenes:
		if not ResourceLoader.exists(scene_path):
			missing_scenes.append(scene_path)
	_assert("All required scenes exist", missing_scenes.is_empty(), str(missing_scenes))
	_log("")


func _count_resources(directory_path: String, expected_type: String) -> int:
	var count := 0
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return count
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(directory_path + file_name)
			if resource and resource.get_script():
				if resource.get_script().get_global_name() == expected_type:
					count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


# ── SaveManager Tests ────────────────────────────────────────────────

func _test_save_manager() -> void:
	_log("[b]── SaveManager ──[/b]")

	# Cleanup any leftover test profile
	SaveManager.delete_profile(TEST_PROFILE_NAME)

	# Test: create profile
	var profile := SaveManager.create_profile(TEST_PROFILE_NAME)
	_assert("create_profile() returns non-null", profile != null, "")
	if profile:
		_assert("  profile.player_name matches", profile.player_name == TEST_PROFILE_NAME, "got '%s'" % profile.player_name)
		_assert("  profile.xp == 0", profile.xp == 0, "got %d" % profile.xp)
		_assert("  profile.level == 1", profile.level == 1, "got %d" % profile.level)
		_assert("  profile.created_date not empty", profile.created_date != "", "")

	# Test: duplicate name rejected
	var dup := SaveManager.create_profile(TEST_PROFILE_NAME)
	_assert("create_profile() rejects duplicate", dup == null, "")

	# Test: list profiles includes test
	var names := SaveManager.list_profiles()
	var found := false
	for n in names:
		if n == TEST_PROFILE_NAME:
			found = true
	_assert("list_profiles() includes test profile", found, "profiles: %s" % str(names))

	# Test: modify and save profile
	if profile:
		profile.xp = 250
		profile.add_xp(0)  # Recalculate level
		var saved := SaveManager.save_profile(profile)
		_assert("save_profile() succeeds", saved, "")

	# Test: reload profile
	var loaded := SaveManager.load_profile(TEST_PROFILE_NAME)
	_assert("load_profile() returns non-null", loaded != null, "")
	if loaded:
		_assert("  loaded.xp == 250", loaded.xp == 250, "got %d" % loaded.xp)
		_assert("  loaded.level == 2", loaded.level == 2, "got %d (expected 2 for xp=250)" % loaded.level)

	# Test: SRS card save/load round-trip
	var test_cards: Array = []
	var card1 := SRSCard.new()
	card1.vocab_id = "n5_001"
	card1.ease_factor = 2.3
	card1.interval = 6.0
	card1.repetitions = 2
	card1.next_review_date = "2026-04-15"
	card1.total_reviews = 5
	card1.correct_reviews = 4
	test_cards.append(card1)

	var card2 := SRSCard.new()
	card2.vocab_id = "n5_002"
	card2.ease_factor = 1.8
	card2.interval = 1.0
	card2.repetitions = 0
	card2.next_review_date = "2026-04-12"
	card2.total_reviews = 3
	card2.correct_reviews = 1
	test_cards.append(card2)

	var srs_saved := SaveManager.save_srs_data(TEST_PROFILE_NAME, test_cards)
	_assert("save_srs_data() succeeds", srs_saved, "")

	var loaded_cards := SaveManager.load_srs_cards(TEST_PROFILE_NAME)
	_assert("load_srs_cards() returns 2 cards", loaded_cards.size() == 2, "got %d" % loaded_cards.size())
	if loaded_cards.size() >= 2:
		_assert("  card[0].vocab_id == 'n5_001'", loaded_cards[0].vocab_id == "n5_001", "got '%s'" % loaded_cards[0].vocab_id)
		_assert("  card[0].ease_factor ~= 2.3", absf(loaded_cards[0].ease_factor - 2.3) < 0.01, "got %f" % loaded_cards[0].ease_factor)
		_assert("  card[0].interval == 6.0", loaded_cards[0].interval == 6.0, "got %f" % loaded_cards[0].interval)
		_assert("  card[1].vocab_id == 'n5_002'", loaded_cards[1].vocab_id == "n5_002", "got '%s'" % loaded_cards[1].vocab_id)
		_assert("  card[1].correct_reviews == 1", loaded_cards[1].correct_reviews == 1, "got %d" % loaded_cards[1].correct_reviews)

	# Test: delete profile
	var deleted := SaveManager.delete_profile(TEST_PROFILE_NAME)
	_assert("delete_profile() succeeds", deleted, "")

	var after_delete := SaveManager.load_profile(TEST_PROFILE_NAME)
	_assert("profile gone after delete", after_delete == null, "")

	_log("")


# ── Learning Data Migration Tests ─────────────────────────────────────


func _test_learning_data_migration() -> void:
	_log("[b]── Learning Data Migration ──[/b]")
	SaveManager.delete_profile(TEST_PROFILE_NAME)
	var profile := SaveManager.create_profile(TEST_PROFILE_NAME)
	_assert("Create migration test profile", profile != null, "")
	if profile == null:
		return

	profile.settings.erase("target_jlpt_level")
	ResourceSaver.save(profile, "user://profiles/__test_profile__/profile.tres")
	var defaulted_profile := SaveManager.load_profile(TEST_PROFILE_NAME)
	_assert("Profile curriculum default", defaulted_profile.settings.get("target_jlpt_level", -1) == 5, "")
	_assert("Reduced Motion defaults off", defaulted_profile.settings.get("reduced_motion", true) == false, "")

	var legacy: Array = [{
		"vocab_id": "n5_001",
		"ease_factor": 2.3,
		"interval": 6.0,
		"repetitions": 2,
		"next_review_date": "2026-01-08",
		"last_review_date": "2026-01-02",
		"total_reviews": 4,
		"correct_reviews": 3,
	}]
	var path := "user://profiles/__test_profile__/srs_data.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()

	var migrated := SaveManager.load_learning_data(TEST_PROFILE_NAME)
	_assert("Legacy migration succeeds", migrated["load_ok"] and migrated["migrated"], "")
	var migrated_cards: Array[SRSCard] = migrated["cards"]
	_assert("Legacy card count", migrated_cards.size() == 1, "")
	if migrated_cards.size() == 1:
		var card := migrated_cards[0]
		_assert("Legacy SM-2 fields preserved", card.ease_factor == 2.3 and card.interval == 6.0 and card.repetitions == 2, "")
		_assert("Legacy totals preserved", card.total_reviews == 4 and card.correct_reviews == 3, "")
		_assert("Legacy skills remain empty", card.skill_evidence.is_empty(), "")
	_assert("Legacy backup created", FileAccess.file_exists("user://profiles/__test_profile__/srs_data_v1_backup.json"), "")

	var reloaded := SaveManager.load_learning_data(TEST_PROFILE_NAME)
	_assert("Migration is idempotent", reloaded["load_ok"] and not reloaded["migrated"], "")
	var roundtrip_cards: Array[SRSCard] = reloaded["cards"]
	var evidence := SkillEvidence.new()
	evidence.record(SRSEngine.Quality.GOOD, "2026-01-03", "multiple_choice")
	roundtrip_cards[0].skill_evidence["meaning"] = evidence
	var sessions: Array = []
	for i in 105:
		sessions.append({"timestamp": "session_%d" % i, "game_type": "multiple_choice"})
	_assert("Learning data save succeeds", SaveManager.save_learning_data(TEST_PROFILE_NAME, roundtrip_cards, sessions), "")
	var roundtrip := SaveManager.load_learning_data(TEST_PROFILE_NAME)
	_assert("Session history capped", roundtrip["sessions"].size() == 100, "got %d" % roundtrip["sessions"].size())
	var saved_cards: Array[SRSCard] = roundtrip["cards"]
	_assert("Skill evidence round trip", saved_cards[0].skill_evidence["meaning"].attempts == 1, "")

	var v2_envelope := {
		"schema_version": 2,
		"cards": [SaveManager._serialize_card(saved_cards[0])],
		"sessions": [{"game_type": "v2_session"}],
	}
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(v2_envelope))
	file.close()
	var v2_migration := SaveManager.load_learning_data(TEST_PROFILE_NAME)
	_assert("V2 migration succeeds", v2_migration["load_ok"] and v2_migration["migrated"], "")
	_assert("V2 history preserved", v2_migration["sessions"].size() == 1, "")
	_assert("V2 kanji initialized empty", v2_migration["kanji_cards"].is_empty(), "")
	_assert("V2 backup created", FileAccess.file_exists("user://profiles/__test_profile__/srs_data_v2_backup.json"), "")

	var kanji_card := KanjiCard.new()
	kanji_card.setup("一")
	var kanji_evidence := SkillEvidence.new()
	kanji_evidence.record(SRSEngine.Quality.GOOD, "2026-01-04", "kanji_workshop")
	kanji_card.skill_evidence["kanji_form"] = kanji_evidence
	var kanji_cards: Array[KanjiCard] = [kanji_card]
	_assert("Schema 3 kanji save", SaveManager.save_learning_data(TEST_PROFILE_NAME, saved_cards, sessions, kanji_cards), "")
	var v3_reload := SaveManager.load_learning_data(TEST_PROFILE_NAME)
	_assert("Kanji card round trip", v3_reload["kanji_cards"].size() == 1 and v3_reload["kanji_cards"][0].character == "一", "")
	_assert("Kanji evidence round trip", v3_reload["kanji_cards"][0].skill_evidence["kanji_form"].attempts == 1, "")

	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var corrupt := SaveManager.load_learning_data(TEST_PROFILE_NAME)
	_assert("Corrupt data rejected", not corrupt["load_ok"], "")
	_assert("Corrupt data write blocked", not SaveManager.save_learning_data(TEST_PROFILE_NAME, [], []), "")
	file = FileAccess.open(path, FileAccess.READ)
	var remaining := file.get_as_text()
	file.close()
	_assert("Corrupt source remains intact", remaining == "{broken", "got '%s' (%d chars)" % [remaining, remaining.length()])
	SaveManager.delete_profile(TEST_PROFILE_NAME)
	_log("")


# ── SRSEngine Tests ──────────────────────────────────────────────────

func _test_srs_engine() -> void:
	_log("[b]── SRSEngine ──[/b]")

	# Create a fresh test profile
	var profile := SaveManager.create_profile(TEST_PROFILE_NAME)
	_assert("Create test profile for SRS", profile != null, "")

	# Load cards (should be empty)
	SRSEngine.load_cards_for_profile(profile)
	_assert("Cards empty initially", SRSEngine.get_total_card_count() == 0, "got %d" % SRSEngine.get_total_card_count())

	# Add new cards
	var ids := PackedStringArray(["n5_001", "n5_002", "n5_003", "n5_004", "n5_005"])
	var new_cards := SRSEngine.add_new_cards(ids)
	_assert("add_new_cards() returns 5", new_cards.size() == 5, "got %d" % new_cards.size())
	_assert("Total cards == 5", SRSEngine.get_total_card_count() == 5, "got %d" % SRSEngine.get_total_card_count())

	# All new cards should be due
	var due := SRSEngine.get_due_cards()
	_assert("All 5 new cards are due", due.size() == 5, "got %d" % due.size())

	# Test: duplicate add is ignored
	var dups := SRSEngine.add_new_cards(PackedStringArray(["n5_001", "n5_006"]))
	_assert("add_new_cards() skips existing, adds 1 new", dups.size() == 1, "got %d" % dups.size())
	_assert("Total cards == 6", SRSEngine.get_total_card_count() == 6, "got %d" % SRSEngine.get_total_card_count())

	# Test: get_card_for_vocab
	var card := SRSEngine.get_card_for_vocab("n5_001")
	_assert("get_card_for_vocab('n5_001') found", card != null, "")

	# Test SM-2: review with quality 5 (perfect)
	if card:
		SRSEngine.review_card(card, SRSEngine.Quality.EASY)
		_assert("After EASY: repetitions == 1", card.repetitions == 1, "got %d" % card.repetitions)
		_assert("After EASY: interval == 1.0", card.interval == 1.0, "got %f" % card.interval)
		_assert("After EASY: ease_factor == 2.6", absf(card.ease_factor - 2.6) < 0.01, "got %f" % card.ease_factor)
		_assert("After EASY: next_review_date not empty", card.next_review_date != "", "")

		# Second review, quality GOOD (4)
		SRSEngine.review_card(card, SRSEngine.Quality.GOOD)
		_assert("After 2nd GOOD: repetitions == 2", card.repetitions == 2, "got %d" % card.repetitions)
		_assert("After 2nd GOOD: interval == 6.0", card.interval == 6.0, "got %f" % card.interval)

		# Third review, quality GOOD (4)
		SRSEngine.review_card(card, SRSEngine.Quality.GOOD)
		_assert("After 3rd GOOD: repetitions == 3", card.repetitions == 3, "got %d" % card.repetitions)
		var expected_interval := 6.0 * card.ease_factor
		# Note: ease_factor has been updated by now, so check interval is reasonable
		_assert("After 3rd GOOD: interval > 6", card.interval > 6.0, "got %f" % card.interval)

	# Test SM-2: wrong answer resets
	var card2 := SRSEngine.get_card_for_vocab("n5_002")
	if card2:
		SRSEngine.review_card(card2, SRSEngine.Quality.EASY)
		SRSEngine.review_card(card2, SRSEngine.Quality.GOOD)
		_assert("card2 reps before fail == 2", card2.repetitions == 2, "got %d" % card2.repetitions)

		SRSEngine.review_card(card2, SRSEngine.Quality.WRONG)
		_assert("After WRONG: repetitions reset to 0", card2.repetitions == 0, "got %d" % card2.repetitions)
		_assert("After WRONG: interval reset to 1.0", card2.interval == 1.0, "got %f" % card2.interval)
		_assert("After WRONG: ease_factor >= 1.3", card2.ease_factor >= 1.3, "got %f" % card2.ease_factor)

	# Test: accuracy tracking
	if card:
		_assert("card1 total_reviews == 3", card.total_reviews == 3, "got %d" % card.total_reviews)
		_assert("card1 correct_reviews == 3", card.correct_reviews == 3, "got %d" % card.correct_reviews)
		_assert("card1 accuracy == 1.0", card.get_accuracy() == 1.0, "got %f" % card.get_accuracy())
	if card2:
		_assert("card2 total_reviews == 3", card2.total_reviews == 3, "got %d" % card2.total_reviews)
		_assert("card2 correct_reviews == 2", card2.correct_reviews == 2, "got %d" % card2.correct_reviews)

	# Test: save and reload SRS data
	SRSEngine.save_cards_for_profile(profile)
	SRSEngine.cards.clear()
	_assert("Cards cleared", SRSEngine.get_total_card_count() == 0, "")

	SRSEngine.load_cards_for_profile(profile)
	_assert("Cards reloaded == 6", SRSEngine.get_total_card_count() == 6, "got %d" % SRSEngine.get_total_card_count())

	var reloaded := SRSEngine.get_card_for_vocab("n5_001")
	if reloaded:
		_assert("Reloaded card1 reps == 3", reloaded.repetitions == 3, "got %d" % reloaded.repetitions)
		_assert("Reloaded card1 correct == 3", reloaded.correct_reviews == 3, "got %d" % reloaded.correct_reviews)

	# Test: PlayerProfile XP and leveling
	_log("\n[b]── PlayerProfile XP ──[/b]")
	var xp_profile := PlayerProfile.new()
	xp_profile.player_name = "xp_test"

	var leveled := xp_profile.add_xp(50)
	_assert("50 XP: level == 1, no level-up", xp_profile.level == 1 and not leveled, "level=%d, leveled=%s" % [xp_profile.level, str(leveled)])

	leveled = xp_profile.add_xp(50)
	_assert("100 XP: level == 2, leveled up", xp_profile.level == 2 and leveled, "level=%d, leveled=%s" % [xp_profile.level, str(leveled)])

	leveled = xp_profile.add_xp(200)
	_assert("300 XP: level == 3, leveled up", xp_profile.level == 3 and leveled, "level=%d, leveled=%s" % [xp_profile.level, str(leveled)])

	var progress := xp_profile.level_progress()
	_assert("Level progress at 300 XP == 0.0", absf(progress) < 0.01, "got %f" % progress)

	xp_profile.add_xp(150)
	progress = xp_profile.level_progress()
	_assert("Level progress at 450 XP == 0.5", absf(progress - 0.5) < 0.01, "got %f" % progress)

	_log("")


func _test_curriculum_settings() -> void:
	_log("[b]── Curriculum Settings ──[/b]")
	var saved_cards := SRSEngine.cards
	var saved_profile := GameController.current_profile
	var profile := PlayerProfile.new()
	profile.player_name = "curriculum_test"
	profile.settings["new_cards_per_session"] = 0
	profile.settings["target_jlpt_level"] = 5
	profile.settings["target_topic"] = "all"
	GameController.current_profile = profile
	SRSEngine.cards = []
	var base := MiniGameBase.new()
	base._words_per_session = 10
	base._populate_session({})
	_assert("Zero new cards creates a due-only empty session", base._session_words.is_empty() and SRSEngine.cards.is_empty(), "")
	base.free()

	profile.settings["new_cards_per_session"] = 10
	profile.settings["target_topic"] = "greetings"
	base = MiniGameBase.new()
	base._words_per_session = 10
	base._populate_session({})
	var topic_matches := not base._session_words.is_empty()
	for word in base._session_words:
		if "greetings" not in word.categories or word.jlpt_level != 5:
			topic_matches = false
	_assert("Topic and level filters isolate new cards", topic_matches, "")
	base.free()

	var empty_topic := ""
	for category in VocabDatabase.get_categories():
		if VocabDatabase.get_random_words(1, PackedStringArray(), {"jlpt_level": 4, "category": category}).is_empty():
			empty_topic = category
			break
	_assert("At least one empty N4 topic is disabled by Settings", empty_topic != "", "")
	profile.settings["target_jlpt_level"] = 4
	profile.settings["target_topic"] = empty_topic
	SRSEngine.cards = []
	base = MiniGameBase.new()
	base._words_per_session = 10
	base._populate_session({})
	_assert("Empty topics never substitute another topic", base._session_words.is_empty() and SRSEngine.cards.is_empty(), "")
	base.free()

	profile.settings["target_topic"] = "all"
	profile.settings["new_cards_per_session"] = 0
	SRSEngine.add_new_cards(PackedStringArray(["n5_001", "n4_001"]))
	base = MiniGameBase.new()
	base._words_per_session = 10
	base._populate_session({})
	var due_ids: PackedStringArray = []
	for word in base._session_words:
		due_ids.append(word.id)
	_assert("Due cards span introduced levels", "n5_001" in due_ids and "n4_001" in due_ids, str(due_ids))
	base.free()
	profile.settings["target_jlpt_level"] = 0
	base = MiniGameBase.new()
	_assert("Mixed selection does not restrict new cards to one level", not base._get_curriculum_filters().has("jlpt_level"), "")
	base.free()
	SRSEngine.cards = saved_cards
	GameController.current_profile = saved_profile
	_log("")


func _cleanup() -> void:
	# Clean up test profile
	SaveManager.delete_profile(TEST_PROFILE_NAME)
	SRSEngine.cards.clear()


# ── Test Helpers ─────────────────────────────────────────────────────

func _assert(description: String, condition: bool, detail: String) -> void:
	if condition:
		_pass_count += 1
		_log("[color=green]  PASS[/color] %s" % description)
	else:
		_fail_count += 1
		var msg := "[color=red]  FAIL[/color] %s" % description
		if detail != "":
			msg += " [color=gray](%s)[/color]" % detail
		_log(msg)


func _log(text: String) -> void:
	output.append_text(text + "\n")
	print(text.replace("[b]", "").replace("[/b]", "").replace("[color=green]", "").replace("[color=red]", "").replace("[color=gray]", "").replace("[/color]", ""))
