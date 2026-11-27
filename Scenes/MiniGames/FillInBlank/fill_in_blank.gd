extends MiniGameBase

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")

@onready var sentence_label: Label = $GameArea/SentenceLabel
@onready var hint_label: Label = $GameArea/HintLabel
@onready var answer_btns: Array[Button] = [
	$GameArea/AnswerGrid/Answer1,
	$GameArea/AnswerGrid/Answer2,
	$GameArea/AnswerGrid/Answer3,
	$GameArea/AnswerGrid/Answer4,
]
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var cat_label: Label = $CatReaction/CatLabel

var _is_answering: bool = false
var _correct_answer: String = ""


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].add_theme_font_override("font", JAPANESE_FONT)
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))
	feedback_label.text = ""
	feedback_label.add_theme_font_override("font", JAPANESE_FONT)
	cat_label.text = "🐱"
	_setup_session()


func _get_session_filters() -> Dictionary:
	return {"require_cloze": true}


func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = _get_empty_session_message("professional cloze questions")
		return
	_show_question()


func _show_question() -> void:
	_is_answering = false
	feedback_label.text = ""
	cat_label.text = "🐱"
	var word := _session_words[_current_index]
	progress_label.text = "%d / %d" % [_current_index + 1, _words_per_session]
	score_label.text = "Score: %d" % _correct_count
	sentence_label.add_theme_font_override("font", JAPANESE_FONT)
	hint_label.visible = false

	var authored := VocabDatabase.get_exercises_for_word(word.id)
	if not authored.is_empty():
		var exercise: Dictionary = authored[randi() % authored.size()]
		_correct_answer = exercise["choices"][int(exercise["answer_index"])]
		_set_question(exercise["prompt"], exercise["english"], exercise["choices"])
		return

	var sentences := VocabDatabase.get_sentences_for_word(word.id)
	if not sentences.is_empty():
		var sentence: Dictionary = sentences[randi() % sentences.size()]
		var japanese: String = sentence["japanese"]
		var target: String = word.source_word
		var occurrence := japanese.find(target)
		if occurrence >= 0:
			var blanked := japanese.substr(0, occurrence) + "______" + japanese.substr(occurrence + target.length())
			var choices := _word_choices(word, int(sentence["lesson"]))
			if choices.size() == 4:
				_correct_answer = target
				_set_question(blanked, sentence["english"], choices)
				return

	feedback_label.text = "No unambiguous professional cloze is available for this word."
	for button in answer_btns:
		button.disabled = true


func _set_question(prompt: String, english: String, source_choices: Array) -> void:
	var choices: Array = source_choices.duplicate()
	choices.shuffle()
	sentence_label.text = prompt
	hint_label.text = english
	hint_label.visible = english.strip_edges() != ""
	for i in 4:
		answer_btns[i].text = str(choices[i])
		answer_btns[i].disabled = false
		answer_btns[i].modulate = Color.WHITE
	_is_answering = true


func _word_choices(word: VocabWord, lesson: int) -> Array:
	var choices: Array = [word.source_word]
	var exclude := PackedStringArray([word.id])
	var filters := {"lesson": lesson, "require_meaning": true}
	if word.part_of_speech != "":
		filters["part_of_speech"] = word.part_of_speech
	var distractors := VocabDatabase.get_random_words(40, exclude, filters)
	if distractors.size() < 8:
		distractors.append_array(VocabDatabase.get_random_words(40, exclude, {"lesson": lesson, "require_meaning": true}))
	if distractors.size() < 8:
		distractors.append_array(VocabDatabase.get_random_words(40, exclude, {"require_meaning": true}))
	distractors.shuffle()
	for distractor in distractors:
		if choices.size() >= 4:
			break
		if distractor.source_word != "" and distractor.source_word not in choices:
			choices.append(distractor.source_word)
	return choices


func _on_answer_pressed(index: int) -> void:
	if not _is_answering:
		return
	_is_answering = false
	var card := _session_cards[_current_index]
	var chosen := answer_btns[index].text
	var is_correct := chosen == _correct_answer
	for button in answer_btns:
		button.disabled = true
	if is_correct:
		answer_btns[index].modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Correct!"
		cat_label.text = "🐱 ✨"
		AudioManager.play_correct()
		MotionManager.pop_in(feedback_label, 0.3)
		MotionManager.hop(cat_label, 0.4)
		_report_correct(card, SRSEngine.Quality.GOOD, "context")
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		for button in answer_btns:
			if button.text == _correct_answer:
				button.modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "It was: %s" % _correct_answer
		cat_label.text = "🐱 💦"
		_report_incorrect(card, "context")
		AudioManager.play_wrong()
		MotionManager.shake(feedback_label, 0.3, 5.0)
	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
