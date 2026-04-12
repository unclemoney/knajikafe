extends Control
## cafe_hub.gd
##
## Main hub scene — layered cafe interior with wandering cats,
## decoration slots, and clickable game stations.

# ── Node references ─────────────────────────────────

@onready var player_name_label: Label = $TopBar/PlayerInfo/NameLabel
@onready var level_label: Label = $TopBar/PlayerInfo/LevelLabel
@onready var xp_bar: ProgressBar = $TopBar/PlayerInfo/XPBar
@onready var due_label: Label = $TopBar/DueLabel
@onready var streak_label: Label = $TopBar/StreakLabel

@onready var stats_btn: Button = $TopBar/StatsBtn
@onready var cats_btn: Button = $TopBar/CatsBtn
@onready var decor_btn: Button = $TopBar/DecorBtn
@onready var logout_btn: Button = $TopBar/LogoutBtn

@onready var cat_display: HBoxContainer = $CatDisplay
@onready var cat_name_label: Label = $DialogueBox/CatNameLabel
@onready var dialogue_label: Label = $DialogueBox/DialogueLabel
@onready var decoration_layer: Control = $DecorationLayer

@onready var quiz_btn: Button = $Stations/QuizStation/QuizBtn
@onready var flashcard_btn: Button = $Stations/FlashcardStation/FlashcardBtn
@onready var matching_btn: Button = $Stations/MatchingStation/MatchingBtn
@onready var fill_blank_btn: Button = $Stations/FillBlankStation/FillBlankBtn
@onready var typing_btn: Button = $Stations/TypingStation/TypingBtn
@onready var orders_btn: Button = $Stations/OrdersStation/OrdersBtn
@onready var settings_btn: Button = $Stations/SettingsStation/SettingsBtn

# ── Constants ───────────────────────────────────────

const CAT_DIR := "res://Resources/Cats/"
const DECOR_DIR := "res://Resources/Decorations/"
const DECOR_SLOTS := {
	"wall": "WallSlot",
	"counter": "CounterSlot",
	"table": "TableSlot",
	"window": "WindowSlot",
	"floor": "FloorSlot",
}

# ── State ───────────────────────────────────────────

var _all_cats: Array = []
var _unlocked_cats: Array = []
var _active_cat: CatCharacter = null
var _all_decorations: Array = []


func _ready() -> void:
	quiz_btn.pressed.connect(_on_quiz_pressed)
	flashcard_btn.pressed.connect(_on_flashcard_pressed)
	matching_btn.pressed.connect(_on_matching_pressed)
	fill_blank_btn.pressed.connect(_on_fill_blank_pressed)
	typing_btn.pressed.connect(_on_typing_pressed)
	orders_btn.pressed.connect(_on_orders_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	stats_btn.pressed.connect(_on_stats_pressed)
	cats_btn.pressed.connect(_on_cats_pressed)
	decor_btn.pressed.connect(_on_decor_pressed)
	logout_btn.pressed.connect(_on_logout_pressed)
	_load_cats()
	_load_decorations()
	_update_streak()
	_update_player_info()
	_update_due_count()
	_check_cat_unlocks()
	_display_cafe_cats()
	_display_decorations()


# ── Cat System ──────────────────────────────────────


## Loads all cat resources from the Cats directory.
func _load_cats() -> void:
	var dir := DirAccess.open(CAT_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var cat := load(CAT_DIR + file_name) as CatCharacter
			if cat != null:
				_all_cats.append(cat)
		file_name = dir.get_next()
	dir.list_dir_end()
	_all_cats.sort_custom(_compare_cats)


## Sort comparator: default cats first, then by level requirement.
func _compare_cats(a: CatCharacter, b: CatCharacter) -> bool:
	return _unlock_sort_key(a.unlock_condition) < _unlock_sort_key(b.unlock_condition)


## Returns a numeric sort key for an unlock condition string.
func _unlock_sort_key(condition: String) -> int:
	if condition == "default":
		return 0
	if condition.begins_with("level:"):
		return int(condition.split(":")[1])
	return 999


## Checks which cats should be unlocked based on the player's progress.
func _check_cat_unlocks() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return
	_unlocked_cats.clear()
	var newly_unlocked := false
	for cat in _all_cats:
		if _is_condition_met(cat.unlock_condition, profile):
			_unlocked_cats.append(cat)
			if not profile.unlocked_cats.has(cat.cat_id):
				profile.unlocked_cats.append(cat.cat_id)
				newly_unlocked = true
	if newly_unlocked:
		SaveManager.save_profile(profile)


## Returns true if an unlock condition string is satisfied by the profile.
func _is_condition_met(condition: String, profile: PlayerProfile) -> bool:
	if condition == "default":
		return true
	if condition.begins_with("level:"):
		var req := int(condition.split(":")[1])
		return profile.level >= req
	return false


## Populates the CatDisplay with buttons for unlocked cats and placeholders for locked ones.
func _display_cafe_cats() -> void:
	for child in cat_display.get_children():
		child.queue_free()
	var show_count := mini(_unlocked_cats.size(), 4)
	for i in range(show_count):
		var cat: CatCharacter = _unlocked_cats[i]
		var btn := Button.new()
		btn.text = "🐱 " + cat.cat_name
		btn.custom_minimum_size = Vector2(72, 22)
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(_on_cat_clicked.bind(cat))
		cat_display.add_child(btn)
	var locked_count := _all_cats.size() - _unlocked_cats.size()
	for i in range(mini(locked_count, 3)):
		var lbl := Label.new()
		lbl.text = "❓"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3, 1))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(30, 22)
		cat_display.add_child(lbl)
	if _unlocked_cats.size() > 0:
		_active_cat = _unlocked_cats[randi() % _unlocked_cats.size()]
		_show_cat_dialogue(_active_cat)


## Handles clicking on a cat button — selects that cat and shows dialogue.
func _on_cat_clicked(cat: CatCharacter) -> void:
	_active_cat = cat
	_show_cat_dialogue(cat)


## Shows a random dialogue line from the given cat.
func _show_cat_dialogue(cat: CatCharacter) -> void:
	cat_name_label.text = "🐱 " + cat.cat_name
	cat_name_label.add_theme_color_override("font_color", cat.accent_color)
	var idx := randi() % cat.dialogue_lines.size()
	dialogue_label.text = "\"" + cat.dialogue_lines[idx] + "\""


# ── Decoration System ───────────────────────────────


## Loads all decoration resources from the Decorations directory.
func _load_decorations() -> void:
	var dir := DirAccess.open(DECOR_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var decor := load(DECOR_DIR + file_name) as CafeDecoration
			if decor != null:
				_all_decorations.append(decor)
		file_name = dir.get_next()
	dir.list_dir_end()


## Displays active decorations in their respective slots.
func _display_decorations() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return
	var active_by_slot := {}
	for decor in _all_decorations:
		if profile.cafe_decorations.has(decor.id):
			active_by_slot[decor.slot] = decor
	for slot_name in DECOR_SLOTS:
		var node_name: String = DECOR_SLOTS[slot_name]
		var slot_node := decoration_layer.get_node_or_null(node_name) as Label
		if slot_node == null:
			continue
		if active_by_slot.has(slot_name):
			var decor: CafeDecoration = active_by_slot[slot_name]
			slot_node.text = decor.icon_text
			slot_node.visible = true
		else:
			slot_node.text = ""
			slot_node.visible = false


# ── UI Updates ──────────────────────────────────────


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
		due_label.text = "New player! Start a quiz."
	elif due_count > 0:
		due_label.text = "%d cards due" % due_count
	else:
		due_label.text = "All caught up!"


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


# ── Navigation ──────────────────────────────────────


## Opens the stats/progress screen.
func _on_stats_pressed() -> void:
	stats_btn.disabled = true
	GameController.change_scene("res://Scenes/Stats/stats_screen.tscn")


## Opens the cat collection screen.
func _on_cats_pressed() -> void:
	cats_btn.disabled = true
	GameController.change_scene("res://Scenes/CatCollection/cat_collection.tscn")


## Opens the decoration shop screen.
func _on_decor_pressed() -> void:
	decor_btn.disabled = true
	GameController.change_scene("res://Scenes/DecorationShop/decoration_shop.tscn")


## Updates the daily streak for the current profile.
func _update_streak() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return
	var today := GameController.get_current_date()
	profile.update_streak(today)
	SaveManager.save_profile(profile)
