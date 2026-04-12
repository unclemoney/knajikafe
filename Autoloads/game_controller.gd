extends Node
## GameController (Autoload)
##
## Global state machine managing scene transitions, current profile,
## and game-wide state. Registered as an autoload singleton.

## Emitted when the active profile changes.
signal profile_changed(profile: PlayerProfile)

## Emitted when a scene transition begins.
signal scene_changing(new_scene: String)

## Emitted when a scene transition completes.
signal scene_changed(new_scene: String)

## The currently loaded player profile. Null if none selected.
var current_profile: PlayerProfile = null

## The currently active scene path.
var current_scene_path: String = ""

## Reference to the scene tree's current scene node.
var current_scene_node: Node = null

## Generic dictionary for passing data between scenes (e.g., quiz results).
var session_data: Dictionary = {}

## Transition overlay for fade effects.
var _transition_rect: ColorRect = null

## Level-up notification overlay.
var _level_up_notification: LevelUpNotification = null


func _ready() -> void:
	_setup_transition_overlay()
	_setup_level_up_notification()
	current_scene_node = get_tree().current_scene


## Sets the active player profile and emits profile_changed.
func set_profile(profile: PlayerProfile) -> void:
	current_profile = profile
	profile_changed.emit(profile)


## Changes to a new scene with a fade transition.
## scene_path: full resource path (e.g., "res://Scenes/CafeHub/cafe_hub.tscn").
func change_scene(scene_path: String) -> void:
	scene_changing.emit(scene_path)
	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().tree_changed
	current_scene_node = get_tree().current_scene
	current_scene_path = scene_path
	await _fade_in()
	scene_changed.emit(scene_path)


## Returns the current date as an ISO 8601 string (YYYY-MM-DD).
func get_current_date() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


## Creates a fullscreen ColorRect used for fade transitions.
func _setup_transition_overlay() -> void:
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color(0, 0, 0, 0)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.anchors_preset = Control.PRESET_FULL_RECT
	_transition_rect.z_index = 100
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(_transition_rect)
	add_child(canvas_layer)


## Fades the screen to black over 0.3 seconds.
func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_transition_rect, "color:a", 1.0, 0.3)
	await tween.finished


## Fades the screen from black over 0.3 seconds.
func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_transition_rect, "color:a", 0.0, 0.3)
	await tween.finished


## Shows the level-up notification overlay.
func show_level_up(new_level: int) -> void:
	if _level_up_notification:
		_level_up_notification.show_level_up(new_level)


## Creates the level-up notification overlay.
func _setup_level_up_notification() -> void:
	_level_up_notification = LevelUpNotification.new()
	add_child(_level_up_notification)
