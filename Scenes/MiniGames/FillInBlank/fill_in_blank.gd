extends MiniGameBase
## fill_in_blank.gd
##
## Fill in the Blank mini-game.
## Shows a sentence with one word blanked out. Player picks
## the correct word from 4 choices. Falls back to a meaning-to-word
## format if no example sentences are available for a word.

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

## Whether the player can currently answer.
var _is_answering: bool = false

## The correct answer text for the current question.
var _correct_answer: String = ""


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))

	feedback_label.text = ""
	cat_label.text = "🐱"
	_setup_session()


func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = "No words available!"
		return
	_show_question()


## Displays the current fill-in-the-blank question.
func _show_question() -> void:
	_is_answering = true
	feedback_label.text = ""
	cat_label.text = "🐱"

	var word := _session_words[_current_index]
	progress_label.text = "%d / %d" % [_current_index + 1, _words_per_session]
	score_label.text = "Score: %d" % _correct_count

	# Try to use an example sentence
	var used_sentence := false
	if word.example_sentences.size() > 0:
		var sentence_pair: String = word.example_sentences[randi() % word.example_sentences.size()]
		var parts := sentence_pair.split("|")
		if parts.size() >= 2:
			var jp_sentence: String = parts[0]
			var en_sentence: String = parts[1]
			var display_text := word.get_display_text()
			if display_text in jp_sentence:
				var blanked := jp_sentence.replace(display_text, "______")
				sentence_label.text = blanked
				hint_label.text = en_sentence
				hint_label.visible = true
				_correct_answer = display_text
				used_sentence = true

	# Fallback: "Which word means [English]?"
	if not used_sentence:
		sentence_label.text = "Which word means: \"%s\"?" % word.get_primary_meaning()
		hint_label.visible = false
		_correct_answer = word.get_display_text()

	# Build answer choices
	var choices: Array[String] = [_correct_answer]

	var exclude := PackedStringArray([word.id])
	var distractors := VocabDatabase.get_random_words(10, exclude)
	distractors.shuffle()

	for d in distractors:
		if choices.size() >= 4:
			break
		var d_text := d.get_display_text()
		if d_text != "" and d_text != _correct_answer and d_text not in choices:
			choices.append(d_text)

	# Pad if needed
	var fallbacks: Array[String] = ["???", "...", "---"]
	var fi := 0
	while choices.size() < 4:
		choices.append(fallbacks[fi % fallbacks.size()])
		fi += 1

	choices.shuffle()
	for i in 4:
		answer_btns[i].text = choices[i]
		answer_btns[i].disabled = false
		answer_btns[i].modulate = Color.WHITE


## Called when an answer button is pressed.
func _on_answer_pressed(index: int) -> void:
	if not _is_answering:
		return
	_is_answering = false

	var card := _session_cards[_current_index]
	var chosen := answer_btns[index].text
	var is_correct := chosen == _correct_answer

	for btn in answer_btns:
		btn.disabled = true

	if is_correct:
		answer_btns[index].modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Correct!"
		cat_label.text = "🐱 ✨"
		AudioManager.play_correct()
		TweenFX.pop_in(feedback_label, 0.3)
		TweenFX.hop(cat_label, 0.4)

		var quality := SRSEngine.Quality.GOOD
		if card.repetitions == 0:
			quality = SRSEngine.Quality.EASY
		_report_correct(card, quality)
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		for btn in answer_btns:
			if btn.text == _correct_answer:
				btn.modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "It was: %s" % _correct_answer
		cat_label.text = "🐱 💦"
		_report_incorrect(card)
		AudioManager.play_wrong()
		TweenFX.shake(feedback_label, 0.3, 5.0)

	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
