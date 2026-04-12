extends MiniGameBase
## kanji_matching.gd
##
## Memory card matching mini-game.
## A 4×3 grid of face-down cards: 6 kanji cards and 6 meaning cards.
## Flip two at a time — match a kanji to its English meaning.
## Matched pairs are removed. XP awarded per match.

## Number of pairs in the grid.
const PAIR_COUNT: int = 6

## Grid columns.
const GRID_COLS: int = 4

@onready var card_grid: GridContainer = $GameArea/CardGrid
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var feedback_label: Label = $GameArea/FeedbackLabel
@onready var cat_label: Label = $CatReaction/CatLabel

## Card data: array of dictionaries with "word_index", "is_kanji", "text".
var _card_data: Array[Dictionary] = []

## Button references for the grid.
var _card_buttons: Array[Button] = []

## State for flipping.
var _first_flip: int = -1
var _second_flip: int = -1
var _is_checking: bool = false
var _matches_found: int = 0


func _ready() -> void:
	feedback_label.text = ""
	cat_label.text = "🐱"

	# Override: we only need PAIR_COUNT words for matching
	var config := GameController.session_data
	config["words_per_session"] = PAIR_COUNT
	GameController.session_data = config
	_setup_session()


func _on_session_ready() -> void:
	if _words_per_session == 0:
		feedback_label.text = "No words available!"
		return
	_build_grid()


## Builds the card grid with shuffled kanji/meaning pairs.
func _build_grid() -> void:
	# Create card data: one kanji card + one meaning card per word
	_card_data.clear()
	for i in _session_words.size():
		var word := _session_words[i]
		_card_data.append({
			"word_index": i,
			"is_kanji": true,
			"text": word.get_display_text(),
		})
		_card_data.append({
			"word_index": i,
			"is_kanji": false,
			"text": word.get_primary_meaning(),
		})

	# Shuffle the cards
	_card_data.shuffle()

	# Create buttons
	card_grid.columns = GRID_COLS
	for i in _card_data.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(92, 44)
		btn.add_theme_font_size_override("font_size", 10)
		btn.text = "?"
		btn.pressed.connect(_on_card_pressed.bind(i))
		card_grid.add_child(btn)
		_card_buttons.append(btn)

	progress_label.text = "Matches: 0 / %d" % PAIR_COUNT
	feedback_label.text = "Find matching pairs!"


## Called when a card button is pressed.
func _on_card_pressed(index: int) -> void:
	if _is_checking:
		return
	if _card_buttons[index].disabled:
		return
	# Don't allow clicking the same card twice
	if index == _first_flip:
		return

	# Flip the card: show its text
	_card_buttons[index].text = _card_data[index]["text"]

	if _first_flip == -1:
		# First card of the pair
		_first_flip = index
	else:
		# Second card — check for match
		_second_flip = index
		_is_checking = true
		_check_match()


## Checks if the two flipped cards match.
func _check_match() -> void:
	var data_a := _card_data[_first_flip]
	var data_b := _card_data[_second_flip]

	var is_match := false
	# Match if same word_index and one is kanji, other is meaning
	if data_a["word_index"] == data_b["word_index"]:
		if data_a["is_kanji"] != data_b["is_kanji"]:
			is_match = true

	if is_match:
		_matches_found += 1
		var word_idx: int = data_a["word_index"]
		var card := _session_cards[word_idx]
		_report_correct(card)
		AudioManager.play_correct()

		# Disable matched cards
		_card_buttons[_first_flip].disabled = true
		_card_buttons[_first_flip].modulate = Color(0.3, 0.7, 0.3, 0.5)
		_card_buttons[_second_flip].disabled = true
		_card_buttons[_second_flip].modulate = Color(0.3, 0.7, 0.3, 0.5)

		feedback_label.text = "Match! 🎉"
		cat_label.text = "🐱 ✨"
		progress_label.text = "Matches: %d / %d" % [_matches_found, PAIR_COUNT]

		_first_flip = -1
		_second_flip = -1
		_is_checking = false

		# Check if all matched
		if _matches_found >= PAIR_COUNT:
			await get_tree().create_timer(0.8).timeout
			_finish_session()
	else:
		feedback_label.text = "Not a match!"
		cat_label.text = "🐱 💦"
		AudioManager.play_wrong()

		# Flip cards back after delay
		await get_tree().create_timer(1.0).timeout
		_card_buttons[_first_flip].text = "?"
		_card_buttons[_second_flip].text = "?"
		_first_flip = -1
		_second_flip = -1
		_is_checking = false
		feedback_label.text = "Find matching pairs!"
		cat_label.text = "🐱"
