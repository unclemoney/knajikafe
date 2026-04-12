extends MiniGameBase
## cafe_orders.gd
##
## Cat Cafe Orders mini-game.
## A customer cat appears with a Japanese food/drink order in a speech bubble.
## Player selects the correct item from a shelf of 4 choices.
## Timed rounds — countdown per order. Faster correct answers earn bonus XP.

## Time in seconds per order.
const ORDER_TIME: float = 10.0

@onready var cat_speech_label: Label = $GameArea/SpeechBubble/SpeechLabel
@onready var order_meaning_label: Label = $GameArea/SpeechBubble/MeaningLabel
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
@onready var cat_label: Label = $CatReaction/CatLabel

## Timer state.
var _time_remaining: float = 0.0
var _timer_active: bool = false
var _is_answering: bool = false

## Correct answer index in item_btns.
var _correct_btn_index: int = 0


func _ready() -> void:
	for i in item_btns.size():
		item_btns[i].pressed.connect(_on_item_pressed.bind(i))

	feedback_label.text = ""
	cat_label.text = "🐱"
	timer_bar.max_value = ORDER_TIME
	timer_bar.value = ORDER_TIME
	_setup_session()


func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = "No words available!"
		return
	_show_question()


func _process(delta: float) -> void:
	if not _timer_active:
		return
	_time_remaining -= delta
	timer_bar.value = _time_remaining
	if _time_remaining <= 0.0:
		_timer_active = false
		_on_time_up()


## Displays the current order.
func _show_question() -> void:
	_is_answering = true
	feedback_label.text = ""
	cat_label.text = "🐱 💬"
	order_meaning_label.visible = false

	var word := _session_words[_current_index]
	progress_label.text = "Order %d / %d" % [_current_index + 1, _words_per_session]
	score_label.text = "Score: %d" % _correct_count

	# Cat says the word in Japanese
	cat_speech_label.text = word.get_display_text()

	# Build choices
	var correct_text := word.get_primary_meaning()
	var choices: Array[String] = [correct_text]

	var exclude := PackedStringArray([word.id])
	var distractors := VocabDatabase.get_random_words(10, exclude)
	distractors.shuffle()

	for d in distractors:
		if choices.size() >= 4:
			break
		var m := d.get_primary_meaning()
		if m != "" and m != correct_text and m not in choices:
			choices.append(m)

	# Pad if needed
	var fallbacks: Array[String] = ["???", "...", "---"]
	var fi := 0
	while choices.size() < 4:
		choices.append(fallbacks[fi % fallbacks.size()])
		fi += 1

	choices.shuffle()
	_correct_btn_index = choices.find(correct_text)

	for i in 4:
		item_btns[i].text = choices[i]
		item_btns[i].disabled = false
		item_btns[i].modulate = Color.WHITE

	# Start timer
	_time_remaining = ORDER_TIME
	timer_bar.value = ORDER_TIME
	_timer_active = true


## Called when a shelf item is pressed.
func _on_item_pressed(index: int) -> void:
	if not _is_answering:
		return
	_is_answering = false
	_timer_active = false

	var card := _session_cards[_current_index]
	var word := _session_words[_current_index]

	for btn in item_btns:
		btn.disabled = true

	if index == _correct_btn_index:
		item_btns[index].modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Correct order! 🍵"
		cat_label.text = "🐱 ✨"
		AudioManager.play_correct()

		# Faster answers = better quality
		var quality := SRSEngine.Quality.GOOD
		if _time_remaining > ORDER_TIME * 0.7:
			quality = SRSEngine.Quality.EASY
		_report_correct(card, quality)
	else:
		item_btns[index].modulate = Color(0.9, 0.3, 0.3)
		item_btns[_correct_btn_index].modulate = Color(0.3, 0.9, 0.3)
		feedback_label.text = "Wrong! It was: %s" % word.get_primary_meaning()
		cat_label.text = "🐱 💢"
		AudioManager.play_wrong()
		_report_incorrect(card)

	order_meaning_label.text = "(%s)" % word.get_primary_meaning()
	order_meaning_label.visible = true

	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()


## Called when the timer runs out.
func _on_time_up() -> void:
	if not _is_answering:
		return
	_is_answering = false

	var card := _session_cards[_current_index]
	var word := _session_words[_current_index]

	for btn in item_btns:
		btn.disabled = true

	item_btns[_correct_btn_index].modulate = Color(0.3, 0.9, 0.3)
	feedback_label.text = "Time's up! It was: %s" % word.get_primary_meaning()
	cat_label.text = "🐱 💤"
	AudioManager.play_wrong()
	_report_incorrect(card)

	order_meaning_label.text = "(%s)" % word.get_primary_meaning()
	order_meaning_label.visible = true

	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
