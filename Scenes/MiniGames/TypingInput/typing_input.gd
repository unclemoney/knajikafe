extends MiniGameBase
## typing_input.gd
##
## Typing Input mini-game.
## Shows the English meaning, player types the Hiragana/Romaji reading.
## Accepts either hiragana or romaji input. Case-insensitive for romaji.

@onready var prompt_label: Label = $GameArea/PromptLabel
@onready var word_hint_label: Label = $GameArea/WordHintLabel
@onready var input_field: LineEdit = $GameArea/InputField
@onready var submit_btn: Button = $GameArea/SubmitBtn
@onready var skip_btn: Button = $GameArea/ButtonRow/SkipBtn
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var cat_label: Label = $CatReaction/CatLabel

## Whether the player can currently submit.
var _is_answering: bool = false


func _ready() -> void:
	submit_btn.pressed.connect(_on_submit_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)
	input_field.text_submitted.connect(_on_text_submitted)

	feedback_label.text = ""
	cat_label.text = "🐱"
	_setup_session()


func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = "No words available!"
		return
	_show_question()


## Displays the current typing prompt.
func _show_question() -> void:
	_is_answering = true
	feedback_label.text = ""
	cat_label.text = "🐱"

	var word := _session_words[_current_index]
	progress_label.text = "%d / %d" % [_current_index + 1, _words_per_session]
	score_label.text = "Score: %d" % _correct_count

	prompt_label.text = word.get_primary_meaning()

	# Show kanji hint if available
	if word.kanji != "":
		word_hint_label.text = word.kanji
		word_hint_label.visible = true
	else:
		word_hint_label.visible = false

	input_field.text = ""
	input_field.editable = true
	input_field.placeholder_text = "Type reading..."
	submit_btn.disabled = false
	skip_btn.disabled = false
	input_field.grab_focus()


## Called when Enter is pressed in the input field.
func _on_text_submitted(_text: String) -> void:
	_on_submit_pressed()


## Checks the player's typed answer.
func _on_submit_pressed() -> void:
	if not _is_answering:
		return

	var typed := input_field.text.strip_edges()
	if typed == "":
		return

	_is_answering = false
	input_field.editable = false
	submit_btn.disabled = true
	skip_btn.disabled = true

	var word := _session_words[_current_index]
	var card := _session_cards[_current_index]

	# Check against hiragana, katakana, and romaji (case-insensitive for romaji)
	var is_correct := false
	if typed == word.hiragana:
		is_correct = true
	elif typed == word.katakana:
		is_correct = true
	elif typed.to_lower() == word.romaji.to_lower():
		is_correct = true

	if is_correct:
		feedback_label.text = "Correct! (%s)" % word.hiragana
		cat_label.text = "🐱 ✨"
		AudioManager.play_correct()

		var quality := SRSEngine.Quality.GOOD
		if card.repetitions == 0:
			quality = SRSEngine.Quality.EASY
		_report_correct(card, quality)
	else:
		var correct_reading := word.hiragana
		if correct_reading == "":
			correct_reading = word.katakana
		if word.romaji != "":
			correct_reading += "  (%s)" % word.romaji
		feedback_label.text = "Answer: %s" % correct_reading
		cat_label.text = "🐱 💦"
		AudioManager.play_wrong()
		_report_incorrect(card)

	await get_tree().create_timer(FEEDBACK_DELAY * 1.5).timeout
	_advance()


## Skips the current word (counts as wrong).
func _on_skip_pressed() -> void:
	if not _is_answering:
		return
	_is_answering = false
	input_field.editable = false
	submit_btn.disabled = true
	skip_btn.disabled = true

	var word := _session_words[_current_index]
	var card := _session_cards[_current_index]

	var correct_reading := word.hiragana
	if correct_reading == "":
		correct_reading = word.katakana
	if word.romaji != "":
		correct_reading += "  (%s)" % word.romaji
	feedback_label.text = "Skipped — %s" % correct_reading
	cat_label.text = "🐱 💦"
	_report_incorrect(card)

	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
