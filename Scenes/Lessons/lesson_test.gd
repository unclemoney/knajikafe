extends Control

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")

var _lesson := 1
var _questions: Array = []
var _index := 0
var _correct := 0
var _incorrect := 0
var _vocabulary_correct := 0
var _cloze_correct := 0
var _answering := false
var _progress: Label
var _prompt: Label
var _hint: Label
var _feedback: Label
var _answers: Array[Button] = []


func _ready() -> void:
	_lesson = LessonProgressManager.get_focus_lesson(GameController.session_data)
	if not LessonProgressManager.can_take_test(_lesson):
		GameController.change_scene("res://Scenes/Lessons/lessons_screen.tscn")
		return
	_questions = VocabDatabase.get_lesson_tests(_lesson).duplicate(true)
	_questions.shuffle()
	_build_ui()
	if _questions.size() != LessonProgressManager.TEST_QUESTION_COUNT:
		_prompt.text = "This lesson's test bank is incomplete. Return to Lessons and try another activity."
		return
	_show_question()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.1, 0.07, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	add_child(margin)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	margin.add_child(main)
	var top := HBoxContainer.new()
	main.add_child(top)
	var title := Label.new()
	title.text = "Lesson %d Test · 80%% to unlock" % _lesson
	title.add_theme_font_size_override("font_size", 13)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_progress = Label.new()
	top.add_child(_progress)
	_prompt = Label.new()
	_prompt.custom_minimum_size = Vector2(0, 86)
	_prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_override("font", JAPANESE_FONT)
	_prompt.add_theme_font_size_override("font_size", 17)
	main.add_child(_prompt)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 9)
	main.add_child(_hint)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	main.add_child(grid)
	for index in 4:
		var button := Button.new()
		button.custom_minimum_size = Vector2(290, 50)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_override("font", JAPANESE_FONT)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_answer.bind(index))
		grid.add_child(button)
		_answers.append(button)
	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", 10)
	main.add_child(_feedback)


func _show_question() -> void:
	_answering = true
	_feedback.text = ""
	var question: Dictionary = _questions[_index]
	_progress.text = "%d / 20 · Score %d" % [_index + 1, _correct]
	_prompt.text = question["prompt"]
	_hint.text = question.get("english", "")
	var choices: Array = question["choices"].duplicate()
	choices.shuffle()
	question["runtime_choices"] = choices
	for index in 4:
		_answers[index].text = choices[index]
		_answers[index].disabled = false
		_answers[index].modulate = Color.WHITE


func _answer(index: int) -> void:
	if not _answering:
		return
	_answering = false
	var question: Dictionary = _questions[_index]
	var correct_answer: String = question["choices"][int(question["answer_index"])]
	var is_correct: bool = question["runtime_choices"][index] == correct_answer
	for button in _answers:
		button.disabled = true
	if is_correct:
		_correct += 1
		if question["kind"] == "vocabulary":
			_vocabulary_correct += 1
		else:
			_cloze_correct += 1
		_answers[index].modulate = Color(0.4, 0.95, 0.45)
		_feedback.text = "Correct"
		AudioManager.play_correct()
	else:
		_incorrect += 1
		_answers[index].modulate = Color(0.95, 0.4, 0.4)
		for answer_index in 4:
			if question["runtime_choices"][answer_index] == correct_answer:
				_answers[answer_index].modulate = Color(0.4, 0.95, 0.45)
		_feedback.text = "Answer: %s · %s" % [correct_answer, question.get("explanation", "")]
		AudioManager.play_wrong()
	if _incorrect > 4:
		_feedback.text += " · 80% is no longer reachable."
	await get_tree().create_timer(1.1).timeout
	if _incorrect > 4:
		_finish(true)
		return
	_index += 1
	if _index >= _questions.size():
		_finish()
	else:
		_show_question()


func _finish(early_failure: bool = false) -> void:
	var answered := _index + 1 if early_failure else LessonProgressManager.TEST_QUESTION_COUNT
	var result := LessonProgressManager.record_test_result(_lesson, _correct, _vocabulary_correct, _cloze_correct, answered)
	result["result_kind"] = "lesson_test"
	result["game_type"] = "lesson_test"
	result["early_failure"] = early_failure
	result["words_reviewed"] = answered
	result["scene_path"] = "res://Scenes/Lessons/lesson_test.tscn"
	GameController.session_data = result
	GameController.change_scene("res://Scenes/Results/results_screen.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameController.change_scene("res://Scenes/Lessons/lessons_screen.tscn")
		get_viewport().set_input_as_handled()
