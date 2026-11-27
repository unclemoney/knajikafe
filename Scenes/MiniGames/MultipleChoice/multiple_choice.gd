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
		feedback_label.text = _get_empty_session_message("words")
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

	# Generate only real professional meanings as answer choices.
	var correct_meaning := word.get_primary_meaning()
	var choices: Array[String] = [correct_meaning]
	var exclude := PackedStringArray([word.id])
	var distractors := VocabDatabase.get_random_words(40, exclude, _get_distractor_filters(word))
	if distractors.size() < 8:
		distractors.append_array(VocabDatabase.get_random_words(40, exclude, {"require_meaning": true}))
	distractors.shuffle()
	for distractor in distractors:
		if choices.size() >= 4:
			break
		var meaning := distractor.get_primary_meaning()
		if meaning != "" and meaning != correct_meaning and meaning not in choices:
			choices.append(meaning)
	if choices.size() < 4:
		_is_answering = false
		feedback_label.text = "Not enough unique professional meanings for this question."
		for button in answer_btns:
			button.disabled = true
		return

	choices.shuffle()
	for i in 4:
		answer_btns[i].text = choices[i]
		answer_btns[i].disabled = false
		answer_btns[i].modulate = Color.WHITE


func _get_distractor_filters(word: VocabWord) -> Dictionary:
	var lesson := _get_target_lesson()
	if lesson == 0 or lesson not in word.lesson_ids:
		lesson = word.first_lesson
	var filters := {"lesson": lesson, "require_meaning": true}
	if word.jlpt_level > 0:
		filters["jlpt_level"] = word.jlpt_level
	else:
		filters["untagged_only"] = true
	if _get_difficulty() == "challenge":
		filters.erase("lesson")
		filters.erase("untagged_only")
	if _get_difficulty() == "relaxed" and word.part_of_speech != "":
		filters["part_of_speech"] = word.part_of_speech
	return filters


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
		MotionManager.pop_in(feedback_label, 0.3)
		MotionManager.hop(cat_label, 0.4)

		_report_correct(card, SRSEngine.Quality.GOOD, "meaning")
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		for btn in answer_btns:
			if btn.text == correct_meaning:
				btn.modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Wrong! It was: %s" % correct_meaning
		cat_label.text = "🐱 💦"
		_report_incorrect(card, "meaning")
		AudioManager.play_wrong()
		MotionManager.shake(feedback_label, 0.3, 5.0)

	question_answered.emit(is_correct)

	# Wait then advance
	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
