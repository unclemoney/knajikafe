extends Control
## Purchase, own, and equip cafe decorations.

@onready var back_btn: Button = $TopBar/BackBtn
@onready var beans_label: Label = $TopBar/BeansLabel
@onready var decor_grid: GridContainer = $ScrollContainer/DecorGrid
@onready var preview_label: TextureRect = $PreviewPanel/PreviewVBox/PreviewIcon
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


func _load_decorations() -> void:
	var dir := DirAccess.open(DECOR_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var decor := load(DECOR_DIR + file_name.trim_suffix(".remap")) as CafeDecoration
			if decor != null:
				_all_decorations.append(decor)
		file_name = dir.get_next()
	dir.list_dir_end()
	_all_decorations.sort_custom(_compare_decor)
	var profile := GameController.current_profile
	if profile:
		beans_label.text = "Beans: %d" % profile.coffee_beans


func _compare_decor(a: CafeDecoration, b: CafeDecoration) -> bool:
	return _sort_key(a.unlock_condition) < _sort_key(b.unlock_condition)


func _sort_key(condition: String) -> int:
	if condition == "default":
		return 0
	if condition.begins_with("level:"):
		return int(condition.split(":")[1])
	return 999


func _build_grid() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return
	for child in decor_grid.get_children():
		child.queue_free()
	for decor in _all_decorations:
		var level_unlocked := CafeProgressManager.is_level_unlocked(decor, profile)
		var owned := CafeProgressManager.owns_decoration(decor.id)
		var equipped := profile.cafe_decorations.has(decor.id)
		decor_grid.add_child(_create_decor_card(decor, level_unlocked, owned, equipped))


func _create_decor_card(decor: CafeDecoration, level_unlocked: bool, owned: bool, equipped: bool) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(80, 70)
	card.add_theme_constant_override("separation", 2)
	var icon: Control = null
	if level_unlocked and decor.texture != null:
		var texture_icon := TextureRect.new()
		texture_icon.custom_minimum_size = Vector2(48, 48)
		texture_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_icon.texture = decor.texture
		icon = texture_icon
	else:
		var text_icon := Label.new()
		text_icon.custom_minimum_size = Vector2(48, 48)
		text_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_icon.add_theme_font_size_override("font_size", 20)
		text_icon.text = decor.icon_text if level_unlocked else "🔒"
		icon = text_icon
	card.add_child(icon)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 7)
	name_label.text = decor.display_name if level_unlocked else "???"
	if equipped:
		name_label.text += " ✓"
	card.add_child(name_label)

	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 6)
	if not level_unlocked:
		status.text = _get_unlock_hint(decor.unlock_condition)
	elif equipped:
		status.text = "Equipped"
	elif owned:
		status.text = "Owned"
	else:
		status.text = decor.slot
	card.add_child(status)

	var button := Button.new()
	button.custom_minimum_size = Vector2(70, 18)
	button.add_theme_font_size_override("font_size", 7)
	if not level_unlocked:
		button.text = "Locked"
		button.disabled = true
	elif owned:
		button.text = "Select"
	else:
		button.text = "%d Beans" % decor.cost
	button.pressed.connect(_on_select_decor.bind(decor))
	card.add_child(button)
	return card


func _get_unlock_hint(condition: String) -> String:
	if condition == "default":
		return "Available"
	if condition.begins_with("level:"):
		return "Lv. " + condition.split(":")[1]
	return "Special"


func _on_select_decor(decor: CafeDecoration) -> void:
	_selected_decor = decor
	var profile := GameController.current_profile
	if profile == null:
		return
	var owned := CafeProgressManager.owns_decoration(decor.id)
	var equipped := profile.cafe_decorations.has(decor.id)
	preview_label.texture = decor.texture
	preview_name.text = decor.display_name
	preview_desc.text = decor.description
	preview_slot.text = "Slot: %s · Cost: %d Beans" % [decor.slot, decor.cost]
	equip_btn.visible = true
	if equipped:
		equip_btn.text = "Unequip"
		equip_btn.disabled = false
	elif owned:
		equip_btn.text = "Equip"
		equip_btn.disabled = false
	else:
		equip_btn.text = "Buy %d Beans" % decor.cost
		var check := CafeProgressManager.can_purchase(decor)
		equip_btn.disabled = not check["allowed"]
		if not check["allowed"]:
			preview_slot.text += " · " + check["reason"]


func _on_equip_pressed() -> void:
	if _selected_decor == null:
		return
	var profile := GameController.current_profile
	if profile == null:
		return
	var decor_id := _selected_decor.id
	if profile.cafe_decorations.has(decor_id):
		var new_list := PackedStringArray()
		for id in profile.cafe_decorations:
			if id != decor_id:
				new_list.append(id)
		profile.cafe_decorations = new_list
	else:
		if not CafeProgressManager.owns_decoration(decor_id):
			var result := CafeProgressManager.purchase_decoration(_selected_decor)
			if not result["success"]:
				preview_slot.text = result["reason"]
				return
		var new_list := PackedStringArray()
		for owned_id in profile.cafe_decorations:
			var other := _find_decoration(owned_id)
			if other == null or other.slot != _selected_decor.slot:
				new_list.append(owned_id)
		new_list.append(decor_id)
		profile.cafe_decorations = new_list
	SaveManager.save_profile(profile)
	beans_label.text = "Beans: %d" % profile.coffee_beans
	_build_grid()
	_on_select_decor(_selected_decor)


func _find_decoration(decoration_id: String) -> CafeDecoration:
	for decor in _all_decorations:
		if decor.id == decoration_id:
			return decor
	return null


func _clear_preview() -> void:
	preview_label.texture = null
	preview_name.text = "Select a decoration"
	preview_desc.text = ""
	preview_slot.text = ""
	equip_btn.visible = false


func _on_back_pressed() -> void:
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
