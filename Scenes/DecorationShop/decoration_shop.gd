extends Control
## decoration_shop.gd
##
## Lets the player browse, unlock, and equip cafe decorations.
## Decorations are cosmetic items placed in slots on the cafe hub background.

@onready var back_btn: Button = $TopBar/BackBtn
@onready var decor_grid: GridContainer = $ScrollContainer/DecorGrid
@onready var preview_label: Label = $PreviewPanel/PreviewVBox/PreviewIcon
@onready var preview_name: Label = $PreviewPanel/PreviewVBox/PreviewName
@onready var preview_desc: Label = $PreviewPanel/PreviewVBox/PreviewDesc
@onready var preview_slot: Label = $PreviewPanel/PreviewVBox/PreviewSlot
@onready var equip_btn: Button = $PreviewPanel/PreviewVBox/EquipBtn

const DECOR_DIR := "res://Resources/Decorations/"

var _all_decorations: Array = []
var _selected_decor: CafeDecoration = null


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)
	_load_decorations()
	_build_grid()
	_clear_preview()


## Loads all decoration resources.
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
	_all_decorations.sort_custom(_compare_decor)


## Sort by unlock condition level.
func _compare_decor(a: CafeDecoration, b: CafeDecoration) -> bool:
	return _sort_key(a.unlock_condition) < _sort_key(b.unlock_condition)


## Numeric sort key from unlock condition.
func _sort_key(condition: String) -> int:
	if condition == "default":
		return 0
	if condition.begins_with("level:"):
		return int(condition.split(":")[1])
	return 999


## Builds the decoration grid with cards.
func _build_grid() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	for decor in _all_decorations:
		var is_unlocked := _is_unlocked(decor, profile)
		var is_equipped := profile.cafe_decorations.has(decor.id)
		var card := _create_decor_card(decor, is_unlocked, is_equipped)
		decor_grid.add_child(card)


## Creates a single decoration card.
func _create_decor_card(decor: CafeDecoration, is_unlocked: bool, is_equipped: bool) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(80, 70)
	card.add_theme_constant_override("separation", 2)

	var icon := Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 20)
	if is_unlocked:
		icon.text = decor.icon_text
	else:
		icon.text = "🔒"
		icon.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	card.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 7)
	if is_unlocked:
		name_lbl.text = decor.display_name
		if is_equipped:
			name_lbl.text += " ✓"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6, 1))
	else:
		name_lbl.text = "???"
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	card.add_child(name_lbl)

	var slot_lbl := Label.new()
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_size_override("font_size", 6)
	slot_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	if is_unlocked:
		slot_lbl.text = decor.slot
	else:
		slot_lbl.text = _get_unlock_hint(decor.unlock_condition)
	card.add_child(slot_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 18)
	btn.add_theme_font_size_override("font_size", 7)
	if is_unlocked:
		btn.text = "Select"
		btn.pressed.connect(_on_select_decor.bind(decor))
	else:
		btn.text = "Locked"
		btn.disabled = true
	card.add_child(btn)

	return card


## Returns a hint string for a lock condition.
func _get_unlock_hint(condition: String) -> String:
	if condition == "default":
		return "Available"
	if condition.begins_with("level:"):
		return "Lv. " + condition.split(":")[1]
	return "Special"


## Checks if a decoration is unlocked.
func _is_unlocked(decor: CafeDecoration, profile: PlayerProfile) -> bool:
	if decor.unlock_condition == "default":
		return true
	if decor.unlock_condition.begins_with("level:"):
		var req := int(decor.unlock_condition.split(":")[1])
		return profile.level >= req
	return false


## Selects a decoration and shows its preview.
func _on_select_decor(decor: CafeDecoration) -> void:
	_selected_decor = decor
	var profile := GameController.current_profile
	var is_equipped := false
	if profile:
		is_equipped = profile.cafe_decorations.has(decor.id)

	preview_label.text = decor.icon_text
	preview_name.text = decor.display_name
	preview_desc.text = decor.description
	preview_slot.text = "Slot: " + decor.slot

	if is_equipped:
		equip_btn.text = "Unequip"
	else:
		equip_btn.text = "Equip"
	equip_btn.disabled = false
	equip_btn.visible = true


## Equips or unequips the selected decoration.
func _on_equip_pressed() -> void:
	if _selected_decor == null:
		return
	var profile := GameController.current_profile
	if profile == null:
		return

	var decor_id := _selected_decor.id
	if profile.cafe_decorations.has(decor_id):
		# Unequip: remove from active decorations
		var new_list := PackedStringArray()
		for d in profile.cafe_decorations:
			if d != decor_id:
				new_list.append(d)
		profile.cafe_decorations = new_list
		equip_btn.text = "Equip"
	else:
		# Unequip any existing decoration in the same slot first
		var new_list := PackedStringArray()
		for d_id in profile.cafe_decorations:
			var is_same_slot := false
			for other_decor in _all_decorations:
				if other_decor.id == d_id:
					if other_decor.slot == _selected_decor.slot:
						is_same_slot = true
					break
			if not is_same_slot:
				new_list.append(d_id)
		new_list.append(decor_id)
		profile.cafe_decorations = new_list
		equip_btn.text = "Unequip"

	SaveManager.save_profile(profile)
	# Rebuild grid to reflect changes
	for child in decor_grid.get_children():
		child.queue_free()
	_build_grid()


## Clears the preview panel.
func _clear_preview() -> void:
	preview_label.text = ""
	preview_name.text = "Select a decoration"
	preview_desc.text = ""
	preview_slot.text = ""
	equip_btn.visible = false


## Returns to the cafe hub.
func _on_back_pressed() -> void:
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
