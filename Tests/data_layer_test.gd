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


func _on_run_all() -> void:
	_pass_count = 0
	_fail_count = 0
	output.clear()
	_log("[b]===== Running All Data Layer Tests =====[/b]\n")

	_test_vocab_database()
	_test_save_manager()
	_test_srs_engine()
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
	_assert("get_words_by_jlpt(5) returns words", n5_words.size() > 0, "got %d" % n5_words.size())

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

	# Test: katakana word (coffee)
	var coffee := VocabDatabase.get_word_by_id("n5_011")
	if coffee:
		_assert("Katakana word has katakana", coffee.katakana == "コーヒー", "got '%s'" % coffee.katakana)
		_assert("Katakana word get_display_text()", coffee.get_display_text() == "コーヒー", "got '%s'" % coffee.get_display_text())

	# Test: word helper methods
	if word:
		_assert("get_display_text() returns hiragana for kana-only", word.get_display_text() == "こんにちは", "got '%s'" % word.get_display_text())
		_assert("get_primary_meaning() returns first meaning", word.get_primary_meaning() == "hello", "got '%s'" % word.get_primary_meaning())

	var kanji_word := VocabDatabase.get_word_by_id("n5_025")
	if kanji_word:
		_assert("get_display_text() returns kanji when present", kanji_word.get_display_text() == "食べる", "got '%s'" % kanji_word.get_display_text())

	_log("")


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
		_assert("  loaded.level == 3", loaded.level == 3, "got %d (expected 3 for xp=250)" % loaded.level)

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
