extends MiniGameBase
## Short contextual reading with target-vocabulary SRS integration.

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
var _is_answering := false
var _assisted := false


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))
	assist_btn.pressed.connect(_on_assist_pressed)
	_setup_session()


func _get_item_label() -> String:
	return "Passages"


func _populate_session(_config: Dictionary) -> void:
	var used: Dictionary = {}
	var desired := mini(5, _words_per_session)
	var filters := _get_curriculum_filters()
	var due_filters := filters.duplicate(true)
	due_filters.erase("jlpt_level")
	var due := SRSEngine.get_due_cards()
	for card in due:
		for passage in VocabDatabase.reading_passages:
			if _session_passages.size() >= desired:
				break
			if passage.get("target_vocab_id", "") != card.vocab_id or used.has(passage["id"]):
				continue
			var word := VocabDatabase.get_word_by_id(card.vocab_id)
			if word != null and VocabDatabase.word_matches_filters(word, due_filters):
				_add_passage(passage, card)
				used[passage["id"]] = true
	var remaining := VocabDatabase.reading_passages.duplicate(true)
	remaining.shuffle()
	var new_count := 0
	var new_card_limit := _get_new_card_limit()
	for passage in remaining:
		if _session_passages.size() >= desired:
			break
		if used.has(passage["id"]):
			continue
		var vocab_id: String = passage["target_vocab_id"]
		var word := VocabDatabase.get_word_by_id(vocab_id)
		if word == null or not VocabDatabase.word_matches_filters(word, filters):
			continue
		var card := SRSEngine.get_card_for_vocab(vocab_id)
		if card != null or new_count >= new_card_limit:
			continue
		new_count += 1
		_add_passage(passage, null)
		used[passage["id"]] = true
	_session_item_count = _session_passages.size()


func _add_passage(passage: Dictionary, existing_card: SRSCard) -> void:
	var vocab_id: String = passage["target_vocab_id"]
	var word := VocabDatabase.get_word_by_id(vocab_id)
	if word == null:
		return
	var card := existing_card
	if card == null:
		var created := SRSEngine.add_new_cards(PackedStringArray([vocab_id]))
		if created.is_empty():
			return
		card = created[0]
	_session_passages.append(passage)
	_session_words.append(word)
	_session_cards.append(card)


func _on_session_ready() -> void:
	if _session_passages.is_empty():
		question_label.text = _get_empty_session_message("passages")
		assist_btn.disabled = true
		return
	_show_question()


func _show_question() -> void:
	_is_answering = true
	_assisted = false
	feedback_label.text = ""
	translation_label.visible = false
	assist_btn.disabled = false
	var passage: Dictionary = _session_passages[_current_index]
	progress_label.text = "Passage %d / %d" % [_current_index + 1, _session_passages.size()]
	score_label.text = "Score: %d" % _correct_count
	passage_label.text = "\n".join(passage["japanese_lines"])
	translation_label.text = "\n".join(passage["english_lines"])
	question_label.text = passage["question"]
	for i in 4:
		answer_btns[i].text = passage["choices"][i]
		answer_btns[i].disabled = false
		answer_btns[i].modulate = Color.WHITE


func _on_assist_pressed() -> void:
	if not _is_answering:
		return
	_assisted = true
	translation_label.visible = true
	assist_btn.disabled = true


func _on_answer_pressed(index: int) -> void:
	if not _is_answering:
		return
	_is_answering = false
	assist_btn.disabled = true
	var passage: Dictionary = _session_passages[_current_index]
	var card := _session_cards[_current_index]
	var correct_index := int(passage["answer_index"])
	var correct := index == correct_index
	for button in answer_btns:
		button.disabled = true
	answer_btns[correct_index].modulate = Color(0.3, 0.8, 0.35)
	var skill := "meaning" if _assisted else "context"
	if _assisted:
		_register_assist()
	if correct:
		_report_correct(card, SRSEngine.Quality.GOOD, skill)
		feedback_label.text = "Correct. " + passage["explanation"]
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		_report_incorrect(card, skill)
		feedback_label.text = "Answer: %s. %s" % [passage["choices"][correct_index], passage["explanation"]]
	translation_label.visible = true
	await get_tree().create_timer(2.4).timeout
	_advance()
