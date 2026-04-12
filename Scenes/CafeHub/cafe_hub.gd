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
