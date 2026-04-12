extends Control
## cafe_hub.gd
##
## Main hub scene — side-view cafe with clickable stations.
## Displays player info, cat mascot, and station buttons.

@onready var player_name_label: Label = $TopBar/PlayerInfo/NameLabel
@onready var level_label: Label = $TopBar/PlayerInfo/LevelLabel
@onready var xp_bar: ProgressBar = $TopBar/PlayerInfo/XPBar
@onready var due_label: Label = $TopBar/DueLabel
@onready var streak_label: Label = $TopBar/StreakLabel
@onready var cat_label: Label = $CatArea/CatLabel
@onready var cat_dialogue: Label = $CatArea/DialogueLabel
@onready var quiz_btn: Button = $Stations/QuizStation/QuizBtn
@onready var flashcard_btn: Button = $Stations/FlashcardStation/FlashcardBtn
@onready var matching_btn: Button = $Stations/MatchingStation/MatchingBtn
@onready var fill_blank_btn: Button = $Stations/FillBlankStation/FillBlankBtn
@onready var typing_btn: Button = $Stations/TypingStation/TypingBtn
@onready var orders_btn: Button = $Stations/OrdersStation/OrdersBtn
@onready var settings_btn: Button = $Stations/SettingsStation/SettingsBtn
@onready var logout_btn: Button = $TopBar/LogoutBtn

## Dialogue lines the mascot cat can say.
var _cat_dialogues: PackedStringArray = [
	"Nyaa~ Ready to study?",
	"Let's learn some kanji!",
	"I believe in you, nyaa~",
	"Coffee and kanji go great together!",
	"Try the quiz station, nyaa!",
]


func _ready() -> void:
	quiz_btn.pressed.connect(_on_quiz_pressed)
	flashcard_btn.pressed.connect(_on_flashcard_pressed)
	matching_btn.pressed.connect(_on_matching_pressed)
	fill_blank_btn.pressed.connect(_on_fill_blank_pressed)
	typing_btn.pressed.connect(_on_typing_pressed)
	orders_btn.pressed.connect(_on_orders_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	logout_btn.pressed.connect(_on_logout_pressed)
	_update_streak()
	_update_player_info()
	_update_due_count()
	_show_random_dialogue()


## Updates the player info display.
func _update_player_info() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	player_name_label.text = profile.player_name
	level_label.text = "Lv. %d" % profile.level
	xp_bar.value = profile.level_progress() * 100.0

	if profile.streak_days > 1:
		streak_label.text = "🔥 %d" % profile.streak_days
	elif profile.streak_days == 1:
		streak_label.text = "🔥 1"
	else:
		streak_label.text = ""


## Updates the due card count display.
func _update_due_count() -> void:
	var due_count := SRSEngine.get_due_count()
	var total := SRSEngine.get_total_card_count()
	if total == 0:
		due_label.text = "New player! Start a quiz to begin learning."
	elif due_count > 0:
		due_label.text = "%d cards due for review" % due_count
	else:
		due_label.text = "All caught up! Start a quiz for new words."


## Shows a random cat dialogue line.
func _show_random_dialogue() -> void:
	cat_label.text = "🐱 Mochi"
	var idx := randi() % _cat_dialogues.size()
	cat_dialogue.text = _cat_dialogues[idx]


## Starts the Multiple Choice Quiz.
func _on_quiz_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var words_per_session: int = profile.settings.get("words_per_session", 10)
	GameController.session_data = {
		"game_type": "multiple_choice",
		"words_per_session": words_per_session,
	}

	quiz_btn.disabled = true
	GameController.change_scene("res://Scenes/MiniGames/MultipleChoice/multiple_choice.tscn")


## Starts the Flashcard Review.
func _on_flashcard_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var words_per_session: int = profile.settings.get("words_per_session", 10)
	GameController.session_data = {
		"game_type": "flashcard_review",
		"words_per_session": words_per_session,
	}

	flashcard_btn.disabled = true
	GameController.change_scene("res://Scenes/MiniGames/FlashcardReview/flashcard_review.tscn")


## Starts the Kanji Matching game.
func _on_matching_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	GameController.session_data = {
		"game_type": "kanji_matching",
		"words_per_session": 6,
	}

	matching_btn.disabled = true
	GameController.change_scene("res://Scenes/MiniGames/KanjiMatching/kanji_matching.tscn")


## Starts the Fill in the Blank game.
func _on_fill_blank_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var words_per_session: int = profile.settings.get("words_per_session", 10)
	GameController.session_data = {
		"game_type": "fill_in_blank",
		"words_per_session": words_per_session,
	}

	fill_blank_btn.disabled = true
	GameController.change_scene("res://Scenes/MiniGames/FillInBlank/fill_in_blank.tscn")


## Starts the Typing Input game.
func _on_typing_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var words_per_session: int = profile.settings.get("words_per_session", 10)
	GameController.session_data = {
		"game_type": "typing_input",
		"words_per_session": words_per_session,
	}

	typing_btn.disabled = true
	GameController.change_scene("res://Scenes/MiniGames/TypingInput/typing_input.tscn")


## Starts the Cat Cafe Orders game.
func _on_orders_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var words_per_session: int = profile.settings.get("words_per_session", 10)
	GameController.session_data = {
		"game_type": "cafe_orders",
		"words_per_session": words_per_session,
	}

	orders_btn.disabled = true
	GameController.change_scene("res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn")


## Returns to profile select (logout).
func _on_logout_pressed() -> void:
	# Save current profile before leaving
	var profile := GameController.current_profile
	if profile:
		SRSEngine.save_cards_for_profile(profile)
		SaveManager.save_profile(profile)

	GameController.current_profile = null
	GameController.change_scene("res://Scenes/ProfileSelect/profile_select.tscn")


## Opens the settings screen.
func _on_settings_pressed() -> void:
	settings_btn.disabled = true
	GameController.change_scene("res://Scenes/Settings/settings.tscn")


## Updates the daily streak for the current profile.
func _update_streak() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return
	var today := GameController.get_current_date()
	profile.update_streak(today)
	SaveManager.save_profile(profile)
