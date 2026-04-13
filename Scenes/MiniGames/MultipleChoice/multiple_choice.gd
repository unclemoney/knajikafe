extends MiniGameBase
## multiple_choice.gd
##
## Multiple Choice Quiz mini-game.
## Shows a Japanese word and 4 English answer choices.
## Reports results to SRSEngine and calculates XP.

## Emitted when a question is answered. Used internally for timing.
signal question_answered(correct: bool)

@onready var vocab_display: VocabDisplay = $GameArea/WordDisplay
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var answer_btns: Array[Button] = [
	$GameArea/AnswerGrid/Answer1,
	$GameArea/AnswerGrid/Answer2,
	$GameArea/AnswerGrid/Answer3,
	$GameArea/AnswerGrid/Answer4,
]
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var cat_label: Label = $CatReaction/CatLabel

## Whether the player can currently answer.
var _is_answering: bool = false


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))

	feedback_label.text = ""
	cat_label.text = "🐱"
	_setup_session()


## Called when session setup completes — show the first question.
func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = "No words available!"
		return
	_show_question()


## Displays the current question.
func _show_question() -> void:
	_is_answering = true
	feedback_label.text = ""
	cat_label.text = "🐱"

	var word := _session_words[_current_index]

	# Display the word — hide English since that's what we're quizzing
	vocab_display.show_word(word, {"show_english": false})

	# Update progress
	progress_label.text = "%d / %d" % [_current_index + 1, _words_per_session]
	score_label.text = "Score: %d" % _correct_count

	# Generate answer choices
	var correct_meaning := word.get_primary_meaning()
	var choices: Array[String] = [correct_meaning]

	# Get 3 wrong answers from other words
	var exclude := PackedStringArray([word.id])
	var distractors := VocabDatabase.get_random_words(10, exclude)
	distractors.shuffle()

	for d in distractors:
		if choices.size() >= 4:
			break
		var meaning := d.get_primary_meaning()
		if meaning != "" and meaning != correct_meaning and meaning not in choices:
			choices.append(meaning)

	# Pad with fallback if not enough distractors
	var fallbacks: Array[String] = ["???", "...", "---"]
	var fi := 0
	while choices.size() < 4:
		choices.append(fallbacks[fi % fallbacks.size()])
		fi += 1

	# Shuffle choices and assign to buttons
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

	var word := _session_words[_current_index]
	var card := _session_cards[_current_index]
	var correct_meaning := word.get_primary_meaning()
	var chosen := answer_btns[index].text
	var is_correct := chosen == correct_meaning

	# Disable all buttons
	for btn in answer_btns:
		btn.disabled = true

	# Highlight correct/wrong
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
			if btn.text == correct_meaning:
				btn.modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Wrong! It was: %s" % correct_meaning
		cat_label.text = "🐱 💦"
		_report_incorrect(card)
		AudioManager.play_wrong()
		TweenFX.shake(feedback_label, 0.3, 5.0)

	question_answered.emit(is_correct)

	# Wait then advance
	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
