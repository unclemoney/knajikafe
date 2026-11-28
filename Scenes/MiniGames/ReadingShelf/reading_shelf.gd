extends MiniGameBase
## Professional lesson reading with optional authored comprehension questions.

@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var passage_label: Label = $GameArea/PassageLabel
@onready var translation_label: Label = $GameArea/TranslationLabel
@onready var question_label: Label = $GameArea/QuestionLabel
@onready var assist_btn: Button = $GameArea/AssistBtn
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var answer_btns: Array[Button] = [
	$GameArea/AnswerGrid/Answer1,
	$GameArea/AnswerGrid/Answer2,
	$GameArea/AnswerGrid/Answer3,
	$GameArea/AnswerGrid/Answer4,
]

var _session_passages: Array = []
var _question_cards: Dictionary = {}
var _is_answering := false
var _assisted := false
var _current_card: SRSCard = null


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))
	assist_btn.pressed.connect(_on_assist_pressed)
	_setup_passage_scroll()
	_setup_session()


func _setup_passage_scroll() -> void:
	var game_area := $GameArea
	var scroll := ScrollContainer.new()
	scroll.name = "ProfessionalPassageScroll"
	scroll.custom_minimum_size = Vector2(0, 145)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_area.remove_child(passage_label)
	game_area.add_child(scroll)
	game_area.move_child(scroll, 0)
	scroll.add_child(passage_label)
	passage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	passage_label.custom_minimum_size = Vector2(490, 0)
	passage_label.add_theme_font_size_override("font_size", 10)


func _get_item_label() -> String:
	return "Readings"


func _populate_session(config: Dictionary) -> void:
	_session_passages = LessonSessionPlanner.get_reading_passages(config, mini(5, _words_per_session))
	_session_item_count = _session_passages.size()


func _on_session_ready() -> void:
	if _session_passages.is_empty():
		question_label.text = _get_empty_session_message("professional readings")
		assist_btn.disabled = true
		for button in answer_btns:
			button.visible = false
		return
	_show_question()


func _show_question() -> void:
	_is_answering = false
	_assisted = false
	_current_card = null
	feedback_label.text = ""
	translation_label.visible = false
	var passage: Dictionary = _session_passages[_current_index]
	progress_label.text = "Reading %d / %d" % [_current_index + 1, _session_passages.size()]
	score_label.text = "Score: %d" % _correct_count
	passage_label.text = "\n".join(passage["japanese_lines"])
	translation_label.text = "\n".join(passage.get("english_lines", []))
	assist_btn.disabled = passage.get("english_lines", []).is_empty()
	for button in answer_btns:
		button.visible = true
		button.disabled = false
		button.modulate = Color.WHITE

	if str(passage.get("question", "")) == "":
		question_label.text = "%s · Professional source text (unscored)" % passage.get("title", "Lesson reading")
		for i in range(1, 4):
			answer_btns[i].visible = false
		answer_btns[0].text = "Finish Reading" if _current_index + 1 == _session_passages.size() else "Next Passage"
		return

	_is_answering = true
	question_label.text = passage["question"]
	_current_card = _card_for_passage(passage)
	for i in 4:
		answer_btns[i].text = passage["choices"][i]


func _card_for_passage(passage: Dictionary) -> SRSCard:
	var passage_id := str(passage["id"])
	if _question_cards.has(passage_id):
		return _question_cards[passage_id] as SRSCard
	var word := VocabDatabase.get_word_by_id(str(passage.get("target_vocab_id", "")))
	if word == null:
		return null
	var card := SRSEngine.get_card_for_vocab(word.id)
	if card == null:
		var created := SRSEngine.add_new_cards(PackedStringArray([word.id]))
		card = created[0] if not created.is_empty() else null
	if card != null:
		_question_cards[passage_id] = card
		_session_cards.append(card)
		_session_words.append(word)
	return card


func _on_assist_pressed() -> void:
	if not _is_answering or translation_label.text == "":
		return
	_assisted = true
	translation_label.visible = true
	assist_btn.disabled = true


func _on_answer_pressed(index: int) -> void:
	var passage: Dictionary = _session_passages[_current_index]
	if str(passage.get("question", "")) == "":
		if _current_index + 1 >= _session_passages.size():
			GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
			return
		_current_index += 1
		_show_question()
		return
	if not _is_answering or _current_card == null:
		return
	_is_answering = false
	assist_btn.disabled = true
	var correct_index := int(passage["answer_index"])
	var correct := index == correct_index
	for button in answer_btns:
		button.disabled = true
	answer_btns[correct_index].modulate = Color(0.3, 0.8, 0.35)
	var skill := "meaning" if _assisted else "context"
	if _assisted:
		_register_assist()
	if correct:
		_report_correct(_current_card, SRSEngine.Quality.GOOD, skill)
		feedback_label.text = "Correct. " + passage.get("explanation", "")
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		_report_incorrect(_current_card, skill)
		feedback_label.text = "Answer: %s. %s" % [passage["choices"][correct_index], passage.get("explanation", "")]
	translation_label.visible = translation_label.text != ""
	await get_tree().create_timer(2.4).timeout
	_advance()
