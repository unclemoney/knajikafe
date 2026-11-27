extends MiniGameBase
## Audio-first café listening with explicit assisted fallbacks.

@onready var cat_speech_label: Label = $GameArea/SpeechBubble/SpeechLabel
@onready var order_meaning_label: Label = $GameArea/SpeechBubble/MeaningLabel
@onready var replay_btn: Button = $GameArea/ControlRow/ReplayBtn
@onready var assist_btn: Button = $GameArea/ControlRow/AssistBtn
@onready var timer_bar: ProgressBar = $GameArea/TimerBar
@onready var item_btns: Array[Button] = [
	$GameArea/ShelfGrid/Item1,
	$GameArea/ShelfGrid/Item2,
	$GameArea/ShelfGrid/Item3,
	$GameArea/ShelfGrid/Item4,
]
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var score_label: Label = $TopBar/ScoreLabel

var _session_menu: Array = []
var _choices: Array = []
var _correct_btn_index := 0
var _time_remaining := 0.0
var _timer_active := false
var _audio_active := false
var _is_answering := false
var _assisted := false
var _replay_count := 0


func _ready() -> void:
	for i in item_btns.size():
		item_btns[i].pressed.connect(_on_item_pressed.bind(i))
	replay_btn.pressed.connect(_on_replay_pressed)
	assist_btn.pressed.connect(_on_assist_pressed)
	AudioManager.speech_finished.connect(_on_speech_finished)
	_setup_session()


func _get_item_label() -> String:
	return "Orders"


func _populate_session(_config: Dictionary) -> void:
	var desired := mini(10, _words_per_session)
	var used: Dictionary = {}
	for card in SRSEngine.get_due_cards():
		if _session_menu.size() >= desired:
			break
		var item := VocabDatabase.get_menu_item(card.vocab_id)
		var word := VocabDatabase.get_cafe_word_by_id(card.vocab_id)
		if not item.is_empty() and word != null:
			_add_menu_item(item, card)
			used[card.vocab_id] = true
	var candidates := VocabDatabase.cafe_menu.duplicate(true)
	candidates.shuffle()
	var new_count := 0
	var new_card_limit := _get_new_card_limit()
	for item in candidates:
		if _session_menu.size() >= desired or new_count >= new_card_limit:
			break
		var vocab_id: String = item["vocab_id"]
		var word := VocabDatabase.get_cafe_word_by_id(vocab_id)
		if used.has(vocab_id) or SRSEngine.get_card_for_vocab(vocab_id):
			continue
		if word == null:
			continue
		var created := SRSEngine.add_new_cards(PackedStringArray([vocab_id]))
		if not created.is_empty():
			_add_menu_item(item, created[0])
			used[vocab_id] = true
			new_count += 1
	_session_item_count = _session_menu.size()


func _add_menu_item(item: Dictionary, card: SRSCard) -> void:
	var word := VocabDatabase.get_cafe_word_by_id(item["vocab_id"])
	if word:
		_session_menu.append(item)
		_session_words.append(word)
		_session_cards.append(card)


func _on_session_ready() -> void:
	if _session_menu.is_empty():
		feedback_label.text = _get_empty_session_message("café orders")
		return
	_show_question()


func _process(delta: float) -> void:
	if not _timer_active or _audio_active:
		return
	_time_remaining -= delta
	timer_bar.value = _time_remaining
	if _time_remaining <= 0.0:
		_finish_answer(-1)


func _show_question() -> void:
	_is_answering = true
	_assisted = false
	_audio_active = false
	_timer_active = false
	_replay_count = 0
	_time_remaining = _get_order_time()
	timer_bar.max_value = _time_remaining
	feedback_label.text = ""
	cat_speech_label.text = "Listen to the order"
	order_meaning_label.visible = false
	assist_btn.disabled = false
	replay_btn.disabled = false
	progress_label.text = "Order %d / %d" % [_current_index + 1, _session_menu.size()]
	score_label.text = "Score: %d" % _correct_count
	_build_choices()
	_play_order()


func _build_choices() -> void:
	var correct: Dictionary = _session_menu[_current_index]
	_choices = [correct]
	var candidates := VocabDatabase.cafe_menu.duplicate(true)
	candidates.shuffle()
	for item in candidates:
		if item["vocab_id"] != correct["vocab_id"] and _choices.size() < 4:
			_choices.append(item)
	_choices.shuffle()
	_correct_btn_index = _choices.find(correct)
	for i in 4:
		item_btns[i].text = ""
		item_btns[i].icon = load(_choices[i]["texture"])
		item_btns[i].icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_btns[i].disabled = false
		item_btns[i].modulate = Color.WHITE
		item_btns[i].tooltip_text = ""


func _play_order() -> void:
	if not _is_answering:
		return
	var item: Dictionary = _session_menu[_current_index]
	if AudioManager.play_speech(item["order_clip"]):
		_audio_active = true
		_timer_active = false
		cat_speech_label.text = "Listen…" if not _assisted else item.get("order_text", "")
	else:
		_activate_assist("Audio unavailable — assisted Meaning practice.")


func _on_speech_finished(clip_id: String) -> void:
	if not _is_answering:
		return
	var item: Dictionary = _session_menu[_current_index]
	if clip_id == item["order_clip"]:
		_audio_active = false
		_start_timer()


func _start_timer() -> void:
	if not _is_answering or _audio_active:
		return
	if _time_remaining <= 0.0:
		_time_remaining = _get_order_time()
	timer_bar.value = _time_remaining
	_timer_active = true


func _get_order_time() -> float:
	match _get_difficulty():
		"relaxed":
			return 15.0
		"challenge":
			return 8.0
		_:
			return 12.0


func _on_replay_pressed() -> void:
	if _is_answering:
		_replay_count += 1
		_play_order()


func _on_assist_pressed() -> void:
	if _is_answering:
		_activate_assist("Assisted: this attempt records Meaning, not Listening.")


func _activate_assist(message: String) -> void:
	if _assisted:
		return
	_assisted = true
	AudioManager.stop_speech()
	_audio_active = false
	var word := _session_words[_current_index]
	cat_speech_label.text = word.get_display_text()
	order_meaning_label.text = word.get_primary_meaning()
	order_meaning_label.visible = true
	feedback_label.text = message
	assist_btn.disabled = true
	_start_timer()


func _on_item_pressed(index: int) -> void:
	if _is_answering:
		_finish_answer(index)


func _finish_answer(index: int) -> void:
	if not _is_answering:
		return
	_is_answering = false
	_timer_active = false
	_audio_active = false
	AudioManager.stop_speech()
	var card := _session_cards[_current_index]
	var word := _session_words[_current_index]
	var correct := index == _correct_btn_index
	for button in item_btns:
		button.disabled = true
	for i in 4:
		item_btns[i].text = _choices[i]["label"]
		item_btns[i].tooltip_text = _choices[i]["label"]
	item_btns[_correct_btn_index].modulate = Color(0.35, 0.85, 0.4)
	var skill := "meaning" if _assisted else "listening"
	if _assisted:
		_register_assist()
	if correct:
		_report_correct(card, SRSEngine.Quality.GOOD, skill)
		feedback_label.text = "Correct order!"
	else:
		if index >= 0:
			item_btns[index].modulate = Color(0.9, 0.3, 0.3)
		_report_incorrect(card, skill)
		feedback_label.text = "Time's up." if index < 0 else "Wrong item."
	cat_speech_label.text = word.get_display_text()
	order_meaning_label.text = word.get_primary_meaning()
	order_meaning_label.visible = true
	replay_btn.disabled = true
	assist_btn.disabled = true
	await get_tree().create_timer(1.8).timeout
	_advance()


func _exit_tree() -> void:
	AudioManager.stop_speech()
