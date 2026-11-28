extends Control

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")

var _selected_lesson := 1
var _lesson_list: VBoxContainer
var _content_list: VBoxContainer
var _detail: VBoxContainer
var _summary: Label
var _search: LineEdit
var _mode_option: OptionButton
var _practice_btn: Button
var _test_btn: Button


func _ready() -> void:
	_selected_lesson = LessonProgressManager.get_current_lesson()
	_build_ui()
	_refresh_lessons()
	_refresh_content()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.1, 0.07, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 6)
	margin.add_child(main)
	var top := HBoxContainer.new()
	main.add_child(top)
	var back := Button.new()
	back.text = "← Café"
	back.custom_minimum_size = Vector2(60, 26)
	back.pressed.connect(_on_back)
	top.add_child(back)
	var title := _label("Lessons", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(60, 0)
	top.add_child(spacer)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	main.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(150, 0)
	left.add_theme_constant_override("separation", 5)
	body.add_child(left)
	left.add_child(_label("Lesson journey", 11))
	var lesson_scroll := ScrollContainer.new()
	lesson_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(lesson_scroll)
	_lesson_list = VBoxContainer.new()
	_lesson_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_scroll.add_child(_lesson_list)
	_practice_btn = Button.new()
	_practice_btn.text = "Practice Lesson"
	_practice_btn.custom_minimum_size = Vector2(0, 28)
	_practice_btn.pressed.connect(_open_practice)
	left.add_child(_practice_btn)
	_test_btn = Button.new()
	_test_btn.text = "Take Lesson Test"
	_test_btn.custom_minimum_size = Vector2(0, 28)
	_test_btn.pressed.connect(_start_test)
	left.add_child(_test_btn)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 5)
	body.add_child(right)
	_summary = _label("", 10)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(0, 34)
	right.add_child(_summary)
	var filters := HBoxContainer.new()
	right.add_child(filters)
	_mode_option = OptionButton.new()
	_mode_option.add_item("Vocabulary")
	_mode_option.add_item("Grammar")
	_mode_option.item_selected.connect(func(_index: int) -> void: _refresh_content())
	filters.add_child(_mode_option)
	_search = LineEdit.new()
	_search.placeholder_text = "Search this lesson..."
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_text: String) -> void: _refresh_content())
	filters.add_child(_search)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(content)
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(225, 0)
	content.add_child(list_scroll)
	_content_list = VBoxContainer.new()
	_content_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(_content_list)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(detail_scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_detail)


func _refresh_lessons() -> void:
	LessonDetailRenderer.clear(_lesson_list)
	for lesson in VocabDatabase.get_lessons():
		var number := int(lesson["number"])
		var state := LessonProgressManager.get_lesson_state(number)
		var button := Button.new()
		button.text = "L%02d · %s" % [number, state.capitalize()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 23)
		button.add_theme_font_size_override("font_size", 8)
		button.disabled = state == "locked"
		if number == _selected_lesson:
			button.modulate = Color(1.0, 0.9, 0.65)
		button.pressed.connect(_select_lesson.bind(number))
		_lesson_list.add_child(button)


func _select_lesson(number: int) -> void:
	if not LessonProgressManager.is_unlocked(number):
		return
	_selected_lesson = number
	_refresh_lessons()
	_refresh_content()


func _refresh_content() -> void:
	if _content_list == null:
		return
	LessonDetailRenderer.clear(_content_list)
	LessonDetailRenderer.clear(_detail)
	var lesson := VocabDatabase.get_lesson(_selected_lesson)
	var words := VocabDatabase.get_words_by_lesson(_selected_lesson)
	var grammar := VocabDatabase.get_grammar_points(_selected_lesson)
	var record := LessonProgressManager.get_test_record(_selected_lesson)
	var score := "No test attempts" if record.is_empty() else "Best test: %d/20 · Attempts: %d" % [int(record.get("best_score", 0)), int(record.get("attempts", 0))]
	_summary.text = "Lesson %02d · %s\n%d vocabulary · %d grammar · %s" % [_selected_lesson, lesson.get("stage", ""), words.size(), grammar.size(), score]
	_test_btn.disabled = _selected_lesson != LessonProgressManager.get_current_lesson() or not LessonProgressManager.can_take_test(_selected_lesson)
	if _selected_lesson != LessonProgressManager.get_current_lesson():
		_test_btn.text = "Review mode"
	elif not LessonProgressManager.can_take_test(_selected_lesson):
		_test_btn.text = "Practice to Retry"
	else:
		_test_btn.text = "Take Lesson Test"
	var query := _search.text.strip_edges().to_lower()
	if _mode_option.selected == 0:
		for word in words:
			var searchable := (word.get_display_text() + " " + word.get_reading() + " " + word.romaji + " " + " ".join(word.english_meanings)).to_lower()
			if query != "" and query not in searchable:
				continue
			var button := Button.new()
			button.text = "%s — %s" % [word.get_display_text(), word.get_primary_meaning()]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_override("font", JAPANESE_FONT)
			button.add_theme_font_size_override("font_size", 9)
			button.pressed.connect(LessonDetailRenderer.show_word.bind(_detail, word))
			_content_list.add_child(button)
	else:
		for point in grammar:
			var searchable := (str(point["title"]) + " " + str(point["category"]) + " " + "\n".join(point["body_lines"])).to_lower()
			if query != "" and query not in searchable:
				continue
			var button := Button.new()
			button.text = point["title"]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_override("font", JAPANESE_FONT)
			button.add_theme_font_size_override("font_size", 9)
			button.pressed.connect(LessonDetailRenderer.show_grammar.bind(_detail, point))
			_content_list.add_child(button)
	if _content_list.get_child_count() == 0:
		LessonDetailRenderer.add_label(_content_list, "No matching content in this lesson.", 9)
	if _selected_lesson < LessonProgressManager.get_current_lesson():
		LessonDetailRenderer.add_label(_detail, "Review mode: practice focuses this lesson and earlier review without changing your current lesson.", 9)


func _open_practice() -> void:
	var options: Array = []
	for activity in ActivityCatalog.ACTIVITIES:
		if activity.get("require_menu", false):
			continue
		var option := ActivityCatalog.get_option(activity["game_type"], GameController.current_profile)
		option["config"]["lesson_number"] = _selected_lesson
		options.append(option)
	var picker := StationModePicker.new()
	add_child(picker)
	picker.mode_selected.connect(_launch_activity)
	picker.open("Lesson %d Practice" % _selected_lesson, options)


func _launch_activity(config: Dictionary) -> void:
	config["lesson_number"] = _selected_lesson
	GameController.session_data = config.duplicate(true)
	GameController.change_scene(config["scene_path"])


func _start_test() -> void:
	if _selected_lesson != LessonProgressManager.get_current_lesson() or not LessonProgressManager.can_take_test(_selected_lesson):
		return
	GameController.session_data = {"game_type": "lesson_test", "lesson_number": _selected_lesson}
	GameController.change_scene("res://Scenes/Lessons/lesson_test.tscn")


func _on_back() -> void:
	AudioManager.stop_speech()
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	AudioManager.stop_speech()
