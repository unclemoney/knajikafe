extends Control
class_name MiniGameBase
## MiniGameBase
##
## Abstract base class for all mini-games. Provides shared session
## setup (loading words/cards from SRS), XP calculation with streak
## bonus, and finish/save/transition logic.
## Subclasses must override _on_session_ready() and _show_question().

## Base XP per correct answer.
const BASE_XP: int = 10

## Bonus XP for answering quickly or easily.
const EASY_BONUS_XP: int = 5

## Delay after showing feedback before next question (seconds).
const FEEDBACK_DELAY: float = 1.2

## Session configuration.
var _words_per_session: int = 10

## Quiz state.
var _session_words: Array[VocabWord] = []
var _session_cards: Array[SRSCard] = []
var _current_index: int = 0
var _correct_count: int = 0
var _total_xp: int = 0


## Adds an exit button to the top-right corner of the mini-game.
## Called automatically during _setup_session().
func _add_exit_button() -> void:
	var exit_btn := Button.new()
	exit_btn.text = "✕"
	exit_btn.custom_minimum_size = Vector2(28, 28)
	exit_btn.add_theme_font_size_override("font_size", 12)
	exit_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	exit_btn.offset_left = -36
	exit_btn.offset_top = 4
	exit_btn.offset_right = -4
	exit_btn.offset_bottom = 32
	exit_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	exit_btn.pressed.connect(_on_exit_pressed)
	add_child(exit_btn)


## Returns to the cafe hub when the exit button is pressed.
func _on_exit_pressed() -> void:
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")


## Prepares the session: loads due/new cards and resolves to VocabWords.
## Call this from _ready() after setting up UI references.
func _setup_session() -> void:
	_add_exit_button()
	var config := GameController.session_data
	_words_per_session = config.get("words_per_session", 10)

	var due := SRSEngine.get_due_cards()
	var needed := _words_per_session

	for card in due:
		if _session_cards.size() >= needed:
			break
		var word := VocabDatabase.get_word_by_id(card.vocab_id)
		if word != null:
			_session_cards.append(card)
			_session_words.append(word)

	if _session_cards.size() < needed:
		var remaining := needed - _session_cards.size()
		var existing_ids: PackedStringArray = []
		for card in SRSEngine.cards:
			existing_ids.append(card.vocab_id)

		var new_words := VocabDatabase.get_random_words(remaining, existing_ids)
		if new_words.size() > 0:
			var new_ids: PackedStringArray = []
			for w in new_words:
				new_ids.append(w.id)
			var new_cards := SRSEngine.add_new_cards(new_ids)
			for j in new_cards.size():
				_session_cards.append(new_cards[j])
				_session_words.append(new_words[j])

	_words_per_session = _session_words.size()
	AudioManager.play_quiz_bgm()
	_on_session_ready()


## Called after session setup is complete. Override in subclasses
## to start the game (e.g., show the first question).
func _on_session_ready() -> void:
	pass


## Override in subclasses to display the current question/card.
func _show_question() -> void:
	pass


## Reports a correct answer to SRS with the given quality and awards XP.
func _report_correct(card: SRSCard, quality: int = SRSEngine.Quality.GOOD) -> void:
	_correct_count += 1
	SRSEngine.review_card(card, quality)
	_total_xp += BASE_XP
	if quality >= SRSEngine.Quality.EASY:
		_total_xp += EASY_BONUS_XP


## Reports an incorrect answer to SRS.
func _report_incorrect(card: SRSCard) -> void:
	SRSEngine.review_card(card, SRSEngine.Quality.WRONG)


## Advances to the next question, or finishes if done.
func _advance() -> void:
	_current_index += 1
	if _current_index >= _words_per_session:
		_finish_session()
	else:
		_show_question()


## Ends the session: applies streak bonus, saves, transitions to results.
func _finish_session() -> void:
	var profile := GameController.current_profile
	if profile:
		var streak_mult := profile.get_streak_multiplier()
		var final_xp := int(_total_xp * streak_mult)

		var leveled_up := profile.add_xp(final_xp)
		SRSEngine.save_cards_for_profile(profile)
		SaveManager.save_profile(profile)

		if leveled_up:
			GameController.show_level_up(profile.level)
			AudioManager.play_level_up()

		AchievementManager.check_achievements()

		GameController.session_data = {
			"words_reviewed": _words_per_session,
			"correct_count": _correct_count,
			"base_xp": _total_xp,
			"streak_multiplier": streak_mult,
			"xp_earned": final_xp,
			"leveled_up": leveled_up,
			"new_level": profile.level,
			"streak_days": profile.streak_days,
		}

	GameController.change_scene("res://Scenes/Results/results_screen.tscn")
