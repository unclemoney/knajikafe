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
	topic_option.add_item("All lessons", 0)
	for lesson in VocabDatabase.get_lessons():
		topic_option.add_item("Lesson %02d" % lesson["number"], lesson["number"])
		topic_option.set_item_tooltip(topic_option.item_count - 1, "%s · %s" % [lesson["stage"], lesson["source_file"]])
	var profile := GameController.current_profile
	var target_level := int(profile.settings.get("target_jlpt_level", 0)) if profile else 0
	var target_lesson := int(profile.settings.get("target_lesson", 1)) if profile else 1
	level_option.select(level_option.get_item_index(target_level))
	topic_option.select(topic_option.get_item_index(target_lesson))
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
		_add_detail_label("No profile loaded. Professional lessons remain browsable; progress filters need a profile.", 9)
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
	AudioManager.stop_speech()
	_clear_details()
	var display := _add_detail_label(word.get_display_text(), 28, true)
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_detail_label("Reading: %s" % (word.get_reading() if word.get_reading() != "" else "Not supplied"), 12, true)
	if word.romaji != "":
		_add_detail_label("Derived romaji: %s" % word.romaji, 10)
	_add_detail_label("Meaning: %s" % ("; ".join(word.english_meanings) if word.has_meaning() else "Unavailable in extraction"), 11)
	var level := "N%d" % word.jlpt_level if word.jlpt_level > 0 else "JLPT untagged"
	var pos := word.source_pos if word.source_pos != "" else word.part_of_speech
	_add_detail_label("%s · %s · %s" % [level, pos, word.pitch], 8, true)
	var lessons := PackedStringArray()
	for lesson in word.lesson_ids:
		lessons.append(str(lesson))
	_add_detail_label("Professional lessons: %s · %s" % [", ".join(lessons), word.stage], 9, true)
	_add_detail_label("Source sections: %s" % ", ".join(word.source_sections), 8, true)
	var card := SRSEngine.get_card_for_vocab(word.id)
	if card:
		var stage := ProgressMetrics.get_stage_name(ProgressMetrics.get_card_stage(card))
		var review := card.next_review_date if card.next_review_date != "" else "New / unscheduled"
		_add_detail_label("Learning: %s · %d/%d correct" % [stage, card.correct_reviews, card.total_reviews], 9)
		_add_detail_label("Next review: %s" % review, 9)
	else:
		_add_detail_label("Learning: Not introduced", 9)
	var audio_btn := Button.new()
	audio_btn.text = "Play pronunciation"
	audio_btn.custom_minimum_size = Vector2(0, 28)
	audio_btn.disabled = word.get_reading() == "" or not AudioManager.has_speech("vocab:" + word.id)
	audio_btn.pressed.connect(AudioManager.play_speech.bind("vocab:" + word.id))
	detail_container.add_child(audio_btn)
	if not word.example_sentences.is_empty():
		_add_detail_label("Professional examples", 11)
	for example in word.example_sentences:
		var parts := example.split("|")
		_add_detail_label(parts[0], 11, true)
		if parts.size() > 1:
			_add_detail_label(parts[1], 9)
	_add_detail_label("Source: markdown/%s" % word.source_file, 7)
	_add_detail_label("Progress estimates describe study activity, not JLPT certification.", 7)


func _show_grammar_detail(grammar: Dictionary) -> void:
	AudioManager.stop_speech()
	_clear_details()
	_add_detail_label(grammar["title"], 18, true)
	_add_detail_label("Lesson %d · %s · %s" % [grammar["lesson"], grammar["stage"], grammar["kind"]], 9, true)
	if grammar.get("category", "") != "":
		_add_detail_label("Category: %s" % grammar["category"], 9, true)
	_add_detail_label("Professional explanation", 11)
	for line in grammar["body_lines"]:
		_add_detail_label(line, 9, true)
	_add_detail_label("Source: markdown/%s · line %d · page %d" % [grammar["source_file"], grammar["source_line"], grammar["source_page"]], 7)


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
