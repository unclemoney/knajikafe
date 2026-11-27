extends MiniGameBase

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")

@onready var prompt_label: Label = $GameArea/PromptLabel
@onready var answer_label: Label = $GameArea/AnswerLabel
@onready var meaning_label: Label = $GameArea/MeaningLabel
@onready var input_field: LineEdit = $GameArea/InputField
@onready var replay_btn: Button = $GameArea/ControlRow/ReplayBtn
@onready var assist_btn: Button = $GameArea/ControlRow/AssistBtn
@onready var submit_btn: Button = $GameArea/SubmitRow/SubmitBtn
@onready var skip_btn: Button = $GameArea/SubmitRow/SkipBtn
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel

var _kana_keyboard: KanaKeyboard = null
var _is_answering := false
var _assisted := false


func _ready() -> void:
	replay_btn.pressed.connect(_on_replay_pressed)
	assist_btn.pressed.connect(_on_assist_pressed)
	submit_btn.pressed.connect(_on_submit_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	_kana_keyboard = KanaKeyboard.new()
	_kana_keyboard.key_pressed.connect(_on_kana_key)
	_kana_keyboard.submit_pressed.connect(_on_submit_pressed)
	_kana_keyboard.backspace_pressed.connect(_on_kana_backspace)
	_kana_keyboard.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_kana_keyboard.offset_top = -170
	_kana_keyboard.offset_left = 8
	_kana_keyboard.offset_right = -8
	_kana_keyboard.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_kana_keyboard)
	_setup_session()


func _get_session_filters() -> Dictionary:
	return {"require_audio": true}


func _on_session_ready() -> void:
	if _session_words.is_empty():
		prompt_label.text = "No listening entries available."
		feedback_label.text = "Check level/topic, New cards, and audio availability."
		input_field.editable = false
		replay_btn.disabled = true
		assist_btn.disabled = true
		submit_btn.disabled = true
		skip_btn.disabled = true
		return
	_show_question()


func _show_question() -> void:
	_is_answering = true
	_assisted = false
	var word := _session_words[_current_index]
	progress_label.text = "%d / %d" % [_current_index + 1, _session_words.size()]
	score_label.text = "Score: %d" % _correct_count
	prompt_label.text = "Listen and type the reading"
	answer_label.visible = false
	meaning_label.visible = false
	feedback_label.text = ""
	input_field.text = ""
	input_field.editable = true
	input_field.placeholder_text = "Kana or romaji..."
	replay_btn.disabled = false
	assist_btn.disabled = false
	submit_btn.disabled = false
	skip_btn.disabled = false
	input_field.grab_focus()
	_play_word_audio(word)


func _play_word_audio(word: VocabWord) -> void:
	if not AudioManager.play_speech("vocab:" + word.id):
		if _is_answering:
			_activate_assist("Audio unavailable — assisted Reading practice.")
		else:
			feedback_label.text = "Audio unavailable."


func _on_replay_pressed() -> void:
	if _current_index < _session_words.size():
		_play_word_audio(_session_words[_current_index])


func _on_assist_pressed() -> void:
	if _is_answering:
		_activate_assist("Assisted: this attempt records Reading, not Listening.")


func _activate_assist(message: String) -> void:
	if _assisted:
		return
	_assisted = true
	AudioManager.stop_speech()
	var word := _session_words[_current_index]
	answer_label.text = _answer_text(word)
	answer_label.visible = true
	meaning_label.text = word.get_primary_meaning()
	meaning_label.visible = true
	feedback_label.text = message
	assist_btn.disabled = true


func _on_text_submitted(_text: String) -> void:
	_on_submit_pressed()


func _on_submit_pressed() -> void:
	if not _is_answering or input_field.text.strip_edges() == "":
		return
	_finish_answer(false)


func _on_skip_pressed() -> void:
	if _is_answering:
		_finish_answer(true)


func _finish_answer(skipped: bool) -> void:
	if not _is_answering:
		return
	_is_answering = false
	AudioManager.stop_speech()
	var word := _session_words[_current_index]
	var card := _session_cards[_current_index]
	var correct := not skipped and JapaneseAnswerNormalizer.matches(word, input_field.text)
	var skill := "reading" if _assisted else "listening"
	if _assisted:
		_register_assist()
	if correct:
		_report_correct(card, SRSEngine.Quality.GOOD, skill)
		feedback_label.text = "Correct!"
		AudioManager.play_correct()
	else:
		_report_incorrect(card, skill)
		feedback_label.text = "Skipped." if skipped else "Not quite. Review the reading."
		AudioManager.play_wrong()
	answer_label.text = _answer_text(word)
	answer_label.visible = true
	meaning_label.text = word.get_primary_meaning()
	meaning_label.visible = true
	input_field.editable = false
	assist_btn.disabled = true
	submit_btn.disabled = true
	skip_btn.disabled = true
	replay_btn.disabled = false
	await get_tree().create_timer(1.8).timeout
	_advance()


func _answer_text(word: VocabWord) -> String:
	var reading := word.hiragana if word.hiragana != "" else word.katakana
	var text := "%s · %s" % [word.get_display_text(), reading]
	if word.romaji != "":
		text += " · " + word.romaji
	return text


func _on_kana_key(character: String) -> void:
	if _is_answering:
		input_field.text += character
		input_field.caret_column = input_field.text.length()


func _on_kana_backspace() -> void:
	if _is_answering and input_field.text.length() > 0:
		input_field.text = input_field.text.substr(0, input_field.text.length() - 1)
		input_field.caret_column = input_field.text.length()


func _exit_tree() -> void:
	AudioManager.stop_speech()
