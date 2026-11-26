extends MiniGameBase
## N5 kanji meaning, reading, and form practice with independent SRS cards.

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")

@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var kanji_label: Label = $GameArea/KanjiLabel
@onready var meta_label: Label = $GameArea/MetaLabel
@onready var prompt_label: Label = $GameArea/PromptLabel
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var answer_btns: Array[Button] = [
	$GameArea/AnswerGrid/Answer1,
	$GameArea/AnswerGrid/Answer2,
	$GameArea/AnswerGrid/Answer3,
	$GameArea/AnswerGrid/Answer4,
]

var _session_entries: Array[KanjiEntry] = []
var _session_exercises: Array[String] = []
var _correct_answer := ""
var _current_skill := "meaning"
var _is_answering := false
var _forced_exercise := ""


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))
	_setup_session()


func _get_item_label() -> String:
	return "Kanji"


func _get_card_display_text(card: SRSCard) -> String:
	return card.character if card is KanjiCard else card.vocab_id


func _populate_session(_config: Dictionary) -> void:
	var desired := mini(8, _words_per_session)
	var used: Dictionary = {}
	for card in SRSEngine.get_due_kanji_cards():
		if _session_entries.size() >= desired:
			break
		var entry := VocabDatabase.get_kanji(card.character)
		if entry:
			_add_entry(entry, card)
			used[entry.character] = true
	var candidates := VocabDatabase.get_kanji_by_jlpt(5)
	candidates.shuffle()
	var new_count := 0
	for entry in candidates:
		if _session_entries.size() >= desired or new_count >= 3:
			break
		if used.has(entry.character) or SRSEngine.get_kanji_card(entry.character):
			continue
		var created := SRSEngine.add_new_kanji_cards(PackedStringArray([entry.character]))
		if not created.is_empty():
			_add_entry(entry, created[0])
			used[entry.character] = true
			new_count += 1
	_session_item_count = _session_entries.size()


func _add_entry(entry: KanjiEntry, card: KanjiCard) -> void:
	_session_entries.append(entry)
	_session_cards.append(card)


func _on_session_ready() -> void:
	if _session_entries.is_empty():
		prompt_label.text = "No N5 kanji available."
		return
	_show_question()


func _show_question() -> void:
	_is_answering = true
	feedback_label.text = ""
	var entry := _session_entries[_current_index]
	kanji_label.text = entry.character
	meta_label.text = "%d strokes · Radical %s" % [entry.stroke_count, entry.radical]
	progress_label.text = "Kanji %d / %d" % [_current_index + 1, _session_entries.size()]
	score_label.text = "Score: %d" % _correct_count
	var kinds: Array[String] = ["meaning", "reading"]
	if not entry.components.is_empty():
		kinds.append("form")
	var kind := _forced_exercise if _forced_exercise in kinds else kinds[randi() % kinds.size()]
	_session_exercises.append(kind)
	_build_question(entry, kind)
	for button in answer_btns:
		button.disabled = false
		button.modulate = Color.WHITE


func _build_question(entry: KanjiEntry, kind: String) -> void:
	var choices: Array[String] = []
	match kind:
		"meaning":
			_current_skill = "meaning"
			prompt_label.text = "Choose the meaning of this kanji."
			_correct_answer = entry.get_primary_meaning()
			choices.append(_correct_answer)
			for other in VocabDatabase.get_kanji_by_jlpt(5):
				var meaning := other.get_primary_meaning()
				if meaning != _correct_answer and meaning not in choices:
					choices.append(meaning)
				if choices.size() == 4:
					break
			_set_answer_font(false)
		"reading":
			_current_skill = "reading"
			prompt_label.text = "Choose a valid on or kun reading."
			var valid := entry.get_all_readings()
			_correct_answer = valid[randi() % valid.size()]
			choices.append(_correct_answer)
			for other in VocabDatabase.get_kanji_by_jlpt(5):
				for reading in other.get_all_readings():
					if reading not in valid and reading not in choices:
						choices.append(reading)
					if choices.size() == 4:
						break
				if choices.size() == 4:
					break
			_set_answer_font(true)
		"form":
			_current_skill = "kanji_form"
			prompt_label.text = "Which component appears in this kanji?"
			_correct_answer = entry.components[0]
			choices.append(_correct_answer)
			for other in VocabDatabase.get_kanji_by_jlpt(5):
				var candidates: Array = other.components.duplicate()
				candidates.append(other.radical)
				for component in candidates:
					if component != _correct_answer and component not in entry.components and component not in choices:
						choices.append(component)
					if choices.size() == 4:
						break
				if choices.size() == 4:
					break
			_set_answer_font(true)
	while choices.size() > 4:
		choices.remove_at(choices.size() - 1)
	choices.shuffle()
	for i in 4:
		answer_btns[i].text = choices[i]


func _set_answer_font(japanese: bool) -> void:
	for button in answer_btns:
		if japanese:
			button.add_theme_font_override("font", JAPANESE_FONT)
		else:
			button.remove_theme_font_override("font")


func _on_answer_pressed(index: int) -> void:
	if not _is_answering:
		return
	_is_answering = false
	var card := _session_cards[_current_index]
	var entry := _session_entries[_current_index]
	var correct := answer_btns[index].text == _correct_answer
	for button in answer_btns:
		button.disabled = true
		if button.text == _correct_answer:
			button.modulate = Color(0.3, 0.8, 0.35)
	if correct:
		_report_correct(card, SRSEngine.Quality.GOOD, _current_skill)
		feedback_label.text = "Correct. " + _entry_summary(entry)
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		_report_incorrect(card, _current_skill)
		feedback_label.text = "Answer: %s. %s" % [_correct_answer, _entry_summary(entry)]
	await get_tree().create_timer(1.8).timeout
	_advance()


func _entry_summary(entry: KanjiEntry) -> String:
	return "%s · Readings: %s" % [entry.get_primary_meaning(), ", ".join(entry.get_all_readings())]
