extends Control

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")
const PAGE_SIZE := 20

@onready var back_btn: Button = $TopBar/BackBtn
@onready var search_field: LineEdit = $FilterBar/SearchField
@onready var level_option: OptionButton = $FilterBar/LevelOption
@onready var topic_option: OptionButton = $FilterBar/TopicOption
@onready var state_option: OptionButton = $FilterBar/StateOption
@onready var result_label: Label = $MainArea/ListPanel/ListVBox/ResultLabel
@onready var list_container: VBoxContainer = $MainArea/ListPanel/ListVBox/ResultScroll/ResultList
@onready var previous_btn: Button = $MainArea/ListPanel/ListVBox/PageRow/PreviousBtn
@onready var page_label: Label = $MainArea/ListPanel/ListVBox/PageRow/PageLabel
@onready var next_btn: Button = $MainArea/ListPanel/ListVBox/PageRow/NextBtn
@onready var detail_container: VBoxContainer = $MainArea/DetailPanel/DetailScroll/DetailVBox

var _filtered_words: Array[VocabWord] = []
var _filtered_grammar: Array = []
var _mode_option: OptionButton
var _page := 0


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	search_field.text_changed.connect(_on_filters_changed)
	level_option.add_item("All JLPT", 0)
	for level in [5, 4, 3, 2, 1]:
		level_option.add_item("N%d" % level, level)
	topic_option.add_item("All unlocked lessons", 0)
	for lesson in VocabDatabase.get_lessons():
		if not LessonProgressManager.is_unlocked(lesson["number"]):
			continue
		topic_option.add_item("Lesson %02d" % lesson["number"], lesson["number"])
		topic_option.set_item_tooltip(topic_option.item_count - 1, "%s · %s" % [lesson["stage"], lesson["source_file"]])
	var profile := GameController.current_profile
	var target_level := int(profile.settings.get("target_jlpt_level", 0)) if profile else 0
	var target_lesson := LessonProgressManager.get_focus_lesson(GameController.session_data) if profile else 0
	level_option.select(level_option.get_item_index(target_level))
	topic_option.select(maxi(0, topic_option.get_item_index(target_lesson)))
	level_option.item_selected.connect(_on_filters_changed)
	topic_option.item_selected.connect(_on_filters_changed)
	for value in [["All words", "all"], ["Introduced", "introduced"], ["Due", "due"], ["Needs Practice", "needs_practice"]]:
		var index := state_option.item_count
		state_option.add_item(value[0])
		state_option.set_item_metadata(index, value[1])
	state_option.item_selected.connect(_on_filters_changed)
	_mode_option = OptionButton.new()
	_mode_option.name = "ModeOption"
	_mode_option.custom_minimum_size = Vector2(72, 0)
	_mode_option.add_theme_font_size_override("font_size", 8)
	_mode_option.add_item("Words")
	_mode_option.add_item("Grammar")
	_mode_option.item_selected.connect(_on_filters_changed)
	$FilterBar.add_child(_mode_option)
	previous_btn.pressed.connect(_on_previous_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	_refresh_results()
	if profile == null:
		_add_detail_label("No profile loaded. Select a profile to browse unlocked lessons.", 9)
	else:
		_add_detail_label("Select a professional word or grammar point to view its source and study progress.", 9)
	search_field.grab_focus()


func _on_filters_changed(_value) -> void:
	_page = 0
	state_option.disabled = _is_grammar_mode()
	_refresh_results()


func _is_grammar_mode() -> bool:
	return _mode_option != null and _mode_option.selected == 1


func _refresh_results() -> void:
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()
	if _is_grammar_mode():
		_refresh_grammar_results()
		return
	_filtered_words = _get_filtered_words()
	_filtered_words.sort_custom(func(a: VocabWord, b: VocabWord) -> bool:
		if a.first_lesson == b.first_lesson:
			return a.id < b.id
		return a.first_lesson < b.first_lesson
	)
	var page_count := maxi(1, int(ceil(float(_filtered_words.size()) / float(PAGE_SIZE))))
	_page = clampi(_page, 0, page_count - 1)
	var start := _page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, _filtered_words.size())
	for i in range(start, end):
		var word := _filtered_words[i]
		var button := Button.new()
		button.text = "%s — %s" % [word.get_display_text(), word.get_primary_meaning() if word.has_meaning() else "Meaning unavailable in extraction"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 28)
		button.add_theme_font_override("font", JAPANESE_FONT)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_show_detail.bind(word))
		list_container.add_child(button)
	_update_result_controls(_filtered_words.size(), start, end, page_count, "words")


func _refresh_grammar_results() -> void:
	_filtered_grammar = VocabDatabase.get_grammar_points(topic_option.get_selected_id(), search_field.text)
	_filtered_grammar = _filtered_grammar.filter(func(grammar: Dictionary) -> bool: return LessonProgressManager.is_unlocked(int(grammar["lesson"])))
	var page_count := maxi(1, int(ceil(float(_filtered_grammar.size()) / float(PAGE_SIZE))))
	_page = clampi(_page, 0, page_count - 1)
	var start := _page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, _filtered_grammar.size())
	for i in range(start, end):
		var grammar: Dictionary = _filtered_grammar[i]
		var button := Button.new()
		button.text = "L%02d · %s" % [grammar["lesson"], grammar["title"]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 28)
		button.add_theme_font_override("font", JAPANESE_FONT)
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_show_grammar_detail.bind(grammar))
		list_container.add_child(button)
	_update_result_controls(_filtered_grammar.size(), start, end, page_count, "grammar points")


func _update_result_controls(total: int, start: int, end: int, page_count: int, label: String) -> void:
	if total == 0:
		result_label.text = "No professional %s match these filters." % label
	else:
		result_label.text = "%d–%d of %d %s" % [start + 1, end, total, label]
	page_label.text = "Page %d/%d" % [_page + 1, page_count]
	previous_btn.disabled = _page <= 0
	next_btn.disabled = _page >= page_count - 1


func _get_filtered_words() -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	var level := level_option.get_selected_id()
	var lesson := topic_option.get_selected_id()
	var state := str(state_option.get_item_metadata(state_option.selected))
	var query := search_field.text.strip_edges().to_lower()
	var cards: Dictionary = {}
	for card in SRSEngine.cards:
		cards[card.vocab_id] = card
	var needs_practice: Dictionary = {}
	if state == "needs_practice":
		for card in ProgressMetrics.get_needs_practice(SRSEngine.cards, GameController.get_current_date(), SRSEngine.cards.size()):
			needs_practice[card.vocab_id] = card
	for word in VocabDatabase.get_all_words():
		if not LessonProgressManager.is_unlocked(word.first_lesson):
			continue
		if level > 0 and word.jlpt_level != level:
			continue
		if lesson > 0 and lesson not in word.lesson_ids:
			continue
		var card := cards.get(word.id) as SRSCard
		if state == "introduced" and card == null:
			continue
		if state == "due" and (card == null or not card.is_due(GameController.get_current_date())):
			continue
		if state == "needs_practice" and not needs_practice.has(word.id):
			continue
		if query != "" and query not in _search_text(word):
			continue
		results.append(word)
	return results


func _search_text(word: VocabWord) -> String:
	var values := PackedStringArray([word.get_display_text(), word.kanji, word.hiragana, word.katakana, word.romaji, word.stage, word.source_pos])
	values.append(" ".join(word.english_meanings))
	return " ".join(values).to_lower()


func _show_detail(word: VocabWord) -> void:
	LessonDetailRenderer.show_word(detail_container, word)
	_add_detail_label("Progress estimates describe study activity, not JLPT certification.", 7)


func _show_grammar_detail(grammar: Dictionary) -> void:
	LessonDetailRenderer.show_grammar(detail_container, grammar)


func _clear_details() -> void:
	for child in detail_container.get_children():
		detail_container.remove_child(child)
		child.queue_free()


func _add_detail_label(text: String, font_size: int, japanese: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	if japanese:
		label.add_theme_font_override("font", JAPANESE_FONT)
	detail_container.add_child(label)
	return label


func _on_previous_pressed() -> void:
	_page -= 1
	_refresh_results()


func _on_next_pressed() -> void:
	_page += 1
	_refresh_results()


func _on_back_pressed() -> void:
	AudioManager.stop_speech()
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")


func _exit_tree() -> void:
	AudioManager.stop_speech()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
