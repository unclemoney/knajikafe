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
var _page := 0


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	search_field.text_changed.connect(_on_filters_changed)
	level_option.add_item("N5", 5)
	level_option.add_item("N4", 4)
	level_option.add_item("Mixed", 0)
	var profile := GameController.current_profile
	var target_level := int(profile.settings.get("target_jlpt_level", 5)) if profile else 5
	level_option.select(level_option.get_item_index(target_level))
	level_option.item_selected.connect(_on_filters_changed)
	topic_option.add_item("All topics")
	topic_option.set_item_metadata(0, "all")
	for category in VocabDatabase.get_categories():
		var index := topic_option.item_count
		topic_option.add_item(category.capitalize())
		topic_option.set_item_metadata(index, category)
	topic_option.item_selected.connect(_on_filters_changed)
	for value in [["All words", "all"], ["Introduced", "introduced"], ["Due", "due"], ["Needs Practice", "needs_practice"]]:
		var index := state_option.item_count
		state_option.add_item(value[0])
		state_option.set_item_metadata(index, value[1])
	state_option.item_selected.connect(_on_filters_changed)
	previous_btn.pressed.connect(_on_previous_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	_refresh_results()
	if profile == null:
		_add_detail_label("No profile loaded. Browsing works, but progress filters have no study data.", 9)
	else:
		_add_detail_label("Select a word to view readings, examples, progress, and audio.", 9)
	search_field.grab_focus()


func _on_filters_changed(_value) -> void:
	_page = 0
	_refresh_results()


func _refresh_results() -> void:
	_filtered_words = _get_filtered_words()
	_filtered_words.sort_custom(func(a: VocabWord, b: VocabWord) -> bool: return a.id < b.id)
	var page_count := maxi(1, int(ceil(float(_filtered_words.size()) / float(PAGE_SIZE))))
	_page = clampi(_page, 0, page_count - 1)
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()
	var start := _page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, _filtered_words.size())
	for i in range(start, end):
		var word := _filtered_words[i]
		var button := Button.new()
		button.text = "%s — %s" % [word.get_display_text(), word.get_primary_meaning()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 28)
		button.add_theme_font_override("font", JAPANESE_FONT)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_show_detail.bind(word))
		list_container.add_child(button)
	if _filtered_words.is_empty():
		result_label.text = "No words match these filters."
	else:
		result_label.text = "%d–%d of %d words" % [start + 1, end, _filtered_words.size()]
	page_label.text = "Page %d/%d" % [_page + 1, page_count]
	previous_btn.disabled = _page == 0
	next_btn.disabled = _page >= page_count - 1


func _get_filtered_words() -> Array[VocabWord]:
	var results: Array[VocabWord] = []
	var level := level_option.get_selected_id()
	var topic := str(topic_option.get_item_metadata(topic_option.selected))
	var state := str(state_option.get_item_metadata(state_option.selected))
	var query := search_field.text.strip_edges().to_lower()
	var cards: Dictionary = {}
	for card in SRSEngine.cards:
		cards[card.vocab_id] = card
	var needs_practice: Dictionary = {}
	if state == "needs_practice":
		for card in ProgressMetrics.get_needs_practice(SRSEngine.cards, GameController.get_current_date(), SRSEngine.cards.size()):
			needs_practice[card.vocab_id] = true
	for word in VocabDatabase.get_all_words():
		if level > 0 and word.jlpt_level != level:
			continue
		if topic != "all" and topic not in word.categories:
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
	var values: PackedStringArray = [word.get_display_text(), word.kanji, word.hiragana, word.katakana, word.romaji]
	values.append(" ".join(word.english_meanings))
	return " ".join(values).to_lower()


func _show_detail(word: VocabWord) -> void:
	AudioManager.stop_speech()
	for child in detail_container.get_children():
		detail_container.remove_child(child)
		child.queue_free()
	var display := _add_detail_label(word.get_display_text(), 28, true)
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var reading := word.hiragana if word.hiragana != "" else word.katakana
	_add_detail_label("Reading: %s" % reading, 12, true)
	if word.romaji != "":
		_add_detail_label("Romaji: %s" % word.romaji, 10)
	_add_detail_label("Meaning: %s" % "; ".join(word.english_meanings), 11)
	_add_detail_label("N%d · %s · %s" % [word.jlpt_level, word.part_of_speech, ", ".join(word.categories)], 8)
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
	audio_btn.disabled = not AudioManager.has_speech("vocab:" + word.id)
	audio_btn.pressed.connect(AudioManager.play_speech.bind("vocab:" + word.id))
	detail_container.add_child(audio_btn)
	if not word.example_sentences.is_empty():
		_add_detail_label("Examples", 11)
	for example in word.example_sentences:
		var parts := example.split("|")
		_add_detail_label(parts[0], 11, true)
		if parts.size() > 1:
			_add_detail_label(parts[1], 9)
	_add_detail_label("Progress estimates describe study activity, not JLPT certification.", 7)


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
