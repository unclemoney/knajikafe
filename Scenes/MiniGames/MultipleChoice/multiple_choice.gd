extends Control
## multiple_choice.gd
##
## Multiple Choice Quiz mini-game.
## Shows a Japanese word and 4 English answer choices.
## Reports results to SRSEngine and calculates XP.

## Emitted when a question is answered. Used internally for timing.
signal question_answered(correct: bool)

## Base XP per correct answer.
const BASE_XP: int = 10

## Bonus XP for answering quickly or easily.
const EASY_BONUS_XP: int = 5

## Delay after showing feedback before next question (seconds).
const FEEDBACK_DELAY: float = 1.2

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

## Session configuration.
var _words_per_session: int = 10

## Quiz state.
var _session_words: Array[VocabWord] = []
var _session_cards: Array[SRSCard] = []
var _current_index: int = 0
var _correct_count: int = 0
var _total_xp: int = 0
var _is_answering: bool = false


func _ready() -> void:
	for i in answer_btns.size():
		answer_btns[i].pressed.connect(_on_answer_pressed.bind(i))

	feedback_label.text = ""
	cat_label.text = "🐱"
	_setup_session()
	_show_question()


## Prepares the quiz session: get due/new cards, resolve to VocabWords.
func _setup_session() -> void:
	var config := GameController.session_data
	_words_per_session = config.get("words_per_session", 10)

	# Get cards: due cards first, then add new if needed
	var due := SRSEngine.get_due_cards()
	var needed := _words_per_session

	for card in due:
		if _session_cards.size() >= needed:
			break
		var word := VocabDatabase.get_word_by_id(card.vocab_id)
		if word != null:
			_session_cards.append(card)
			_session_words.append(word)

	# If not enough due cards, add new words
	if _session_cards.size() < needed:
		var remaining := needed - _session_cards.size()
		var existing_ids: PackedStringArray = []
		for card in SRSEngine.cards:
			existing_ids.append(card.vocab_id)

		var new_words := VocabDatabase.get_random_words(remaining, existing_ids)
		if new_words.size() > 0:
			var new_ids: PackedStringArray = []
			for w in new_words:
				new_ids.append(w.id)
			var new_cards := SRSEngine.add_new_cards(new_ids)
			for j in new_cards.size():
				_session_cards.append(new_cards[j])
				_session_words.append(new_words[j])

	# If still not enough (database smaller than session size), cap it
	_words_per_session = _session_words.size()

	if _words_per_session == 0:
		feedback_label.text = "No words available!"


## Displays the current question.
func _show_question() -> void:
	if _current_index >= _words_per_session:
		_finish_session()
		return

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
		_correct_count += 1
		AudioManager.play_correct()

		# Report quality based on card history
		var quality := SRSEngine.Quality.GOOD
		if card.repetitions == 0:
			quality = SRSEngine.Quality.EASY
		SRSEngine.review_card(card, quality)
		_total_xp += BASE_XP
		if quality == SRSEngine.Quality.EASY:
			_total_xp += EASY_BONUS_XP
	else:
		answer_btns[index].modulate = Color(0.9, 0.3, 0.3)
		# Highlight the correct answer
		for btn in answer_btns:
			if btn.text == correct_meaning:
				btn.modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Wrong! It was: %s" % correct_meaning
		cat_label.text = "🐱 💦"
		SRSEngine.review_card(card, SRSEngine.Quality.WRONG)
		AudioManager.play_wrong()

	question_answered.emit(is_correct)

	# Wait then show next question
	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_current_index += 1
	_show_question()


## Ends the quiz session, saves data, transitions to results.
func _finish_session() -> void:
	var profile := GameController.current_profile
	if profile:
		# Apply streak bonus multiplier
		var streak_mult := profile.get_streak_multiplier()
		var final_xp := int(_total_xp * streak_mult)

		var leveled_up := profile.add_xp(final_xp)
		SRSEngine.save_cards_for_profile(profile)
		SaveManager.save_profile(profile)

		if leveled_up:
			GameController.show_level_up(profile.level)
			AudioManager.play_level_up()

		GameController.session_data = {
			"words_reviewed": _words_per_session,
			"correct_count": _correct_count,
			"base_xp": _total_xp,
			"streak_multiplier": streak_mult,
			"xp_earned": final_xp,
			"leveled_up": leveled_up,
			"new_level": profile.level,
			"streak_days": profile.streak_days,
		}

	GameController.change_scene("res://Scenes/Results/results_screen.tscn")
