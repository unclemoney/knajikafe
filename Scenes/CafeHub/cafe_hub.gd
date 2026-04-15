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

@onready var cat_world: Node2D = $CatWorld
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
const CAFE_CAT_SCENE := preload("res://Scenes/CafeHub/Cats/cafe_cat.tscn")
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
var _spawned_cats: Array[CafeCat] = []
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
	_display_cafe_cats()
	_display_decorations()
	AudioManager.play_cafe_bgm()
	AchievementManager.check_achievements()
	_animate_hub_entrance()
	_check_tutorial()


# ── Tutorial ────────────────────────────────────────

const TUTORIAL_SCENE := preload("res://Scenes/Tutorial/tutorial.tscn")


## Shows the tutorial overlay for first-time players.
func _check_tutorial() -> void:
	var profile := GameController.current_profile
	if profile and not profile.has_completed_tutorial:
		var tut := TUTORIAL_SCENE.instantiate()
		add_child(tut)


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


## Populates the cafe with animated CafeCat instances for each unlocked cat.
func _display_cafe_cats() -> void:
	# Clear any previously spawned cats
	for cat_node in _spawned_cats:
		if is_instance_valid(cat_node):
			cat_node.queue_free()
	_spawned_cats.clear()

	_check_cat_unlocks()

	# Spawn each unlocked cat at a random floor position
	var spawn_spacing := 80.0
	var start_x := 120.0
	var furniture_targets: Array[Vector2] = [
		Vector2(320.0, 196.0),  # Counter surface
		Vector2(90.0, 136.0),   # Shelf left surface
		Vector2(550.0, 136.0),  # Shelf right surface
	]
	for i in range(_unlocked_cats.size()):
		var cat_data: CatCharacter = _unlocked_cats[i]
		var cat_node: CafeCat = CAFE_CAT_SCENE.instantiate()
		cat_node.cat_data = cat_data
		var spawn_x := start_x + i * spawn_spacing + randf_range(-20.0, 20.0)
		spawn_x = clampf(spawn_x, 32.0, 608.0)
		cat_node.position = Vector2(spawn_x, 270.0)
		cat_node.jump_targets = furniture_targets
		cat_node.cat_clicked.connect(_on_cafe_cat_clicked)
		cat_world.add_child(cat_node)
		_spawned_cats.append(cat_node)

	if _unlocked_cats.size() > 0:
		_active_cat = _unlocked_cats[randi() % _unlocked_cats.size()]


## Handles clicking on an animated CafeCat in the world.
func _on_cafe_cat_clicked(cat: CafeCat) -> void:
	if cat.cat_data:
		_active_cat = cat.cat_data


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


## Animates UI elements on hub entrance using TweenFX.
func _animate_hub_entrance() -> void:
	# Pop in the station buttons with a stagger
	var stations := [quiz_btn, flashcard_btn, matching_btn, fill_blank_btn, typing_btn, orders_btn]
	for i in stations.size():
		var btn: Button = stations[i]
		btn.modulate.a = 0.0
		btn.scale = Vector2.ZERO
		var tween := create_tween()
		tween.tween_interval(0.1 * i)
		tween.tween_property(btn, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
