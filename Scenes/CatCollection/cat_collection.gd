extends Control
## cat_collection.gd
##
## Displays all cat companions with unlock status, personality info,
## and specialty game. Locked cats appear as silhouettes with unlock hints.

@onready var title_label: Label = $TopBar/TitleLabel
@onready var back_btn: Button = $TopBar/BackBtn
@onready var cat_grid: GridContainer = $ScrollContainer/CatGrid
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_name: Label = $DetailPanel/DetailVBox/DetailName
@onready var detail_personality: Label = $DetailPanel/DetailVBox/DetailPersonality
@onready var detail_specialty: Label = $DetailPanel/DetailVBox/DetailSpecialty
@onready var detail_dialogue: Label = $DetailPanel/DetailVBox/DetailDialogue

const CAT_DIR := "res://Resources/Cats/"

var _all_cats: Array = []


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_load_cats()
	_build_grid()
	detail_panel.visible = false


## Loads and sorts all cat resources.
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


## Sort comparator: default cats first, then by level.
func _compare_cats(a: CatCharacter, b: CatCharacter) -> bool:
	var a_key := 0
	var b_key := 0
	if a.unlock_condition.begins_with("level:"):
		a_key = int(a.unlock_condition.split(":")[1])
	if b.unlock_condition.begins_with("level:"):
		b_key = int(b.unlock_condition.split(":")[1])
	return a_key < b_key


## Builds the grid of cat cards.
func _build_grid() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	for cat in _all_cats:
		var is_unlocked := _is_unlocked(cat, profile)
		var card := _create_cat_card(cat, is_unlocked)
		cat_grid.add_child(card)


## Creates a single cat card (VBoxContainer with icon + name).
func _create_cat_card(cat: CatCharacter, is_unlocked: bool) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(90, 80)
	card.add_theme_constant_override("separation", 4)

	var icon := Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 24)
	if is_unlocked:
		icon.text = "🐱"
	else:
		icon.text = "❓"
		icon.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	card.add_child(icon)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	if is_unlocked:
		name_label.text = cat.cat_name
		name_label.add_theme_color_override("font_color", cat.accent_color)
	else:
		name_label.text = "???"
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	card.add_child(name_label)

	var hint_label := Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 7)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	if is_unlocked:
		hint_label.text = "Specialty: " + cat.specialty_game
	else:
		hint_label.text = _get_unlock_hint(cat.unlock_condition)
	card.add_child(hint_label)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 20)
	btn.add_theme_font_size_override("font_size", 7)
	if is_unlocked:
		btn.text = "View"
		btn.pressed.connect(_on_view_cat.bind(cat))
	else:
		btn.text = "Locked"
		btn.disabled = true
	card.add_child(btn)

	return card


## Returns a human-readable unlock hint.
func _get_unlock_hint(condition: String) -> String:
	if condition == "default":
		return "Always available"
	if condition.begins_with("level:"):
		return "Reach Lv. " + condition.split(":")[1]
	if condition.begins_with("achievement:"):
		return "Special unlock"
	return "Unknown"


## Checks if a cat is unlocked for the given profile.
func _is_unlocked(cat: CatCharacter, profile: PlayerProfile) -> bool:
	if cat.unlock_condition == "default":
		return true
	if cat.unlock_condition.begins_with("level:"):
		var req := int(cat.unlock_condition.split(":")[1])
		return profile.level >= req
	return false


## Shows the detail panel for a specific cat.
func _on_view_cat(cat: CatCharacter) -> void:
	detail_panel.visible = true
	detail_name.text = "🐱 " + cat.cat_name
	detail_name.add_theme_color_override("font_color", cat.accent_color)
	detail_personality.text = cat.personality
	detail_specialty.text = "Specialty: " + cat.specialty_game
	var idx := randi() % cat.dialogue_lines.size()
	detail_dialogue.text = "\"" + cat.dialogue_lines[idx] + "\""


## Returns to the cafe hub.
func _on_back_pressed() -> void:
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
