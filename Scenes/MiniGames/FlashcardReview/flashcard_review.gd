extends MiniGameBase
## flashcard_review.gd
##
## Flashcard Review mini-game.
## Shows a word's kanji/kana on the front. Player taps to flip and
## reveal readings + meaning. Then self-rates: Again, Hard, Good, Easy.
## Ratings map to SM-2 quality values for SRS scheduling.

@onready var vocab_display: VocabDisplay = $GameArea/CardFront
@onready var back_panel: VBoxContainer = $GameArea/CardBack
@onready var back_reading_label: Label = $GameArea/CardBack/ReadingLabel
@onready var back_meaning_label: Label = $GameArea/CardBack/MeaningLabel
@onready var flip_btn: Button = $GameArea/FlipBtn
@onready var rating_box: HBoxContainer = $GameArea/RatingBox
@onready var again_btn: Button = $GameArea/RatingBox/AgainBtn
@onready var hard_btn: Button = $GameArea/RatingBox/HardBtn
@onready var good_btn: Button = $GameArea/RatingBox/GoodBtn
@onready var easy_btn: Button = $GameArea/RatingBox/EasyBtn
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var cat_label: Label = $CatReaction/CatLabel


func _ready() -> void:
	flip_btn.pressed.connect(_on_flip_pressed)
	again_btn.pressed.connect(_on_rate_pressed.bind(SRSEngine.Quality.WRONG))
	hard_btn.pressed.connect(_on_rate_pressed.bind(SRSEngine.Quality.HARD))
	good_btn.pressed.connect(_on_rate_pressed.bind(SRSEngine.Quality.GOOD))
	easy_btn.pressed.connect(_on_rate_pressed.bind(SRSEngine.Quality.EASY))

	feedback_label.text = ""
	cat_label.text = "🐱"
	back_panel.visible = false
	rating_box.visible = false
	_setup_session()


func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = "No words available!"
		return
	_show_question()


## Shows the front of the current flashcard.
func _show_question() -> void:
	var word := _session_words[_current_index]

	# Show front: word display without English (that's the answer)
	vocab_display.show_word(word, {"show_english": false})
	vocab_display.visible = true
	back_panel.visible = false
	flip_btn.visible = true
	flip_btn.disabled = false
	rating_box.visible = false
	feedback_label.text = "Tap to flip"
	cat_label.text = "🐱"

	progress_label.text = "%d / %d" % [_current_index + 1, _words_per_session]


## Flips the card to reveal the back.
func _on_flip_pressed() -> void:
	var word := _session_words[_current_index]

	flip_btn.visible = false

	# Show back: readings + meaning
	var reading := word.hiragana
	if reading == "":
		reading = word.katakana
	if word.romaji != "":
		reading += "  (%s)" % word.romaji
	back_reading_label.text = reading
	back_meaning_label.text = word.get_primary_meaning()
	back_panel.visible = true
	rating_box.visible = true
	feedback_label.text = "How well did you know this?"
	cat_label.text = "🐱 ❓"


## Handles self-rating button press.
func _on_rate_pressed(quality: int) -> void:
	var card := _session_cards[_current_index]

	# Disable rating buttons
	again_btn.disabled = true
	hard_btn.disabled = true
	good_btn.disabled = true
	easy_btn.disabled = true

	if quality >= SRSEngine.Quality.HARD:
		_report_correct(card, quality)
		feedback_label.text = "Nice! 📚"
		cat_label.text = "🐱 ✨"
		AudioManager.play_correct()
	else:
		_report_incorrect(card)
		feedback_label.text = "Keep studying! 💪"
		cat_label.text = "🐱 💦"
		AudioManager.play_wrong()

	await get_tree().create_timer(FEEDBACK_DELAY).timeout
	_advance()
