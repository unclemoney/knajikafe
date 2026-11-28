extends Control
class_name MiniGameBase
## Shared session selection, skill evidence, XP, and completion logic.

const BASE_XP: int = 10
const EASY_BONUS_XP: int = 5
const FEEDBACK_DELAY: float = 1.2
const MAX_NEW_CARDS_PER_SESSION: int = 5

var _words_per_session: int = 10
var _session_words: Array[VocabWord] = []
var _session_cards: Array[SRSCard] = []
var _session_item_count: int = 0
var _current_index: int = 0
var _correct_count: int = 0
var _total_xp: int = 0
var _game_type: String = ""
var _skill_results: Dictionary = {}
var _stage_before: Dictionary = {}
var _assisted_count: int = 0


func _focus_first_available() -> void:
	if get_viewport().gui_get_focus_owner():
		return
	var button := _find_first_button(self)
	if button:
		button.grab_focus()


func _find_first_button(node: Node) -> Button:
	if node is Button and node.is_visible_in_tree() and not node.disabled:
		return node
	for child in node.get_children():
		var found := _find_first_button(child)
		if found:
			return found
	return null


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_exit_pressed()
		get_viewport().set_input_as_handled()


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
	var top_bar := get_node_or_null("TopBar") as Control
	if top_bar:
		top_bar.offset_right = -44


func _on_exit_pressed() -> void:
	AudioManager.stop_speech()
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")


func _setup_session() -> void:
	_add_exit_button()
	var config := GameController.session_data
	_words_per_session = config.get("words_per_session", 10)
	_game_type = config.get("game_type", "")
	_populate_session(config)
	_words_per_session = _session_item_count
	for card in _session_cards:
		_stage_before[card.vocab_id] = ProgressMetrics.get_card_stage(card)
	AudioManager.play_quiz_bgm()
	_on_session_ready()
	call_deferred("_focus_first_available")


func _populate_session(config: Dictionary) -> void:
	var selection := LessonSessionPlanner.build_vocabulary_session(config, _get_session_filters(), _words_per_session, _get_new_card_limit())
	for card in selection["cards"]:
		_session_cards.append(card as SRSCard)
	for word in selection["words"]:
		_session_words.append(word as VocabWord)
	_session_item_count = _session_words.size()


func _get_session_filters() -> Dictionary:
	return {}


func _get_curriculum_filters() -> Dictionary:
	return {"require_meaning": true}


func _get_target_lesson() -> int:
	return LessonProgressManager.get_focus_lesson(GameController.session_data)


func _get_target_jlpt_level() -> int:
	var profile := GameController.current_profile
	return int(profile.settings.get("target_jlpt_level", 0)) if profile else 0


func _get_difficulty() -> String:
	var profile := GameController.current_profile
	return str(profile.settings.get("difficulty", "standard")) if profile else "standard"


func _get_new_card_limit() -> int:
	var profile := GameController.current_profile
	if profile == null:
		return MAX_NEW_CARDS_PER_SESSION
	return clampi(int(profile.settings.get("new_cards_per_session", MAX_NEW_CARDS_PER_SESSION)), 0, 10)


func _get_empty_session_message(item_label: String) -> String:
	var lesson := _get_target_lesson()
	var lesson_name := "All lessons" if lesson == 0 else "Lesson %d" % lesson
	var level := _get_target_jlpt_level()
	var level_name := "all JLPT tags" if level == 0 else "N%d" % level
	return "No %s for %s · %s. Review the lesson or adjust New cards in Settings." % [item_label.to_lower(), lesson_name, level_name]


func _get_item_label() -> String:
	return "Words"


func _get_card_display_text(card: SRSCard) -> String:
	var word := VocabDatabase.get_word_by_id(card.vocab_id)
	return word.get_display_text() if word else card.vocab_id


func _on_session_ready() -> void:
	pass


func _show_question() -> void:
	pass


func _report_correct(card: SRSCard, quality: int, skill: String) -> void:
	_correct_count += 1
	_record_skill_attempt(card, skill, quality)
	SRSEngine.review_card(card, quality)
	_total_xp += BASE_XP
	if quality >= SRSEngine.Quality.EASY:
		_total_xp += EASY_BONUS_XP


func _report_incorrect(card: SRSCard, skill: String) -> void:
	_record_skill_attempt(card, skill, SRSEngine.Quality.WRONG)
	SRSEngine.review_card(card, SRSEngine.Quality.WRONG)


func _record_skill_attempt(card: SRSCard, skill: String, quality: int) -> void:
	SRSEngine.record_attempt(card, skill, quality, _game_type)
	if not _skill_results.has(skill):
		_skill_results[skill] = {"attempts": 0, "correct": 0}
	_skill_results[skill]["attempts"] += 1
	if quality >= 3:
		_skill_results[skill]["correct"] += 1


func _register_assist() -> void:
	_assisted_count += 1


func _advance() -> void:
	_current_index += 1
	if _current_index >= _words_per_session:
		_finish_session()
	else:
		_show_question()


func _finish_session() -> void:
	var profile := GameController.current_profile
	if profile:
		var streak_mult := profile.get_streak_multiplier()
		var final_xp := int(_total_xp * streak_mult)
		var leveled_up := profile.add_xp(final_xp)
		var next_review_date := ProgressMetrics.get_next_review_date(_session_cards)
		var stage_changes := _get_stage_changes()
		var summary := {
			"timestamp": Time.get_datetime_string_from_system(),
			"game_type": _game_type,
			"lesson_number": _get_target_lesson(),
			"item_label": _get_item_label(),
			"words_reviewed": _words_per_session,
			"correct_count": _correct_count,
			"xp_earned": final_xp,
			"skill_results": _skill_results.duplicate(true),
			"assisted_count": _assisted_count,
			"next_review_date": next_review_date,
		}
		var cafe_rewards := CafeProgressManager.apply_session(summary)
		summary["cafe_rewards"] = cafe_rewards
		SRSEngine.record_session(summary)
		SRSEngine.save_cards_for_profile(profile)
		LessonProgressManager.record_practice_session(profile)
		SaveManager.save_profile(profile)
		if leveled_up:
			GameController.show_level_up(profile.level)
			AudioManager.play_level_up()
		AchievementManager.check_achievements()
		var recommendation := StudyPlanner.get_recommendation()
		GameController.session_data = {
			"game_type": _game_type,
			"lesson_number": _get_target_lesson(),
			"item_label": _get_item_label(),
			"words_reviewed": _words_per_session,
			"correct_count": _correct_count,
			"base_xp": _total_xp,
			"streak_multiplier": streak_mult,
			"xp_earned": final_xp,
			"leveled_up": leveled_up,
			"new_level": profile.level,
			"streak_days": profile.streak_days,
			"skill_results": _skill_results.duplicate(true),
			"assisted_count": _assisted_count,
			"stage_changes": stage_changes,
			"next_review_date": next_review_date,
			"cafe_rewards": cafe_rewards,
			"recommendation": recommendation,
		}
	GameController.change_scene("res://Scenes/Results/results_screen.tscn")


func _get_stage_changes() -> Array:
	var changes: Array = []
	for card in _session_cards:
		var before := int(_stage_before.get(card.vocab_id, ProgressMetrics.CardStage.NEW))
		var after := int(ProgressMetrics.get_card_stage(card))
		if after > before and after >= ProgressMetrics.CardStage.FAMILIAR:
			changes.append({
				"vocab_id": card.vocab_id,
				"display_text": _get_card_display_text(card),
				"stage": ProgressMetrics.get_stage_name(after as ProgressMetrics.CardStage),
			})
	return changes
