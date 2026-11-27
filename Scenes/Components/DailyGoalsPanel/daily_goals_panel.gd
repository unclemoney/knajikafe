extends Control
class_name DailyGoalsPanel

var _rows_box: VBoxContainer
var _previous_focus: Control


func _ready() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.025, 0.02, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_top = -145
	panel.offset_right = 220
	panel.offset_bottom = 145
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Daily Goals"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_rows_box)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 28)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)
	refresh()
	close_btn.grab_focus()


func refresh() -> void:
	for child in _rows_box.get_children():
		child.queue_free()
	for quest in CafeProgressManager.get_daily_quests():
		var panel := PanelContainer.new()
		var row := VBoxContainer.new()
		panel.add_child(row)
		var title := Label.new()
		title.text = quest["title"] + (" ✓" if quest["claimed"] else "")
		title.add_theme_font_size_override("font_size", 10)
		row.add_child(title)
		var description := Label.new()
		description.text = quest["description"]
		description.add_theme_font_size_override("font_size", 8)
		row.add_child(description)
		var progress := ProgressBar.new()
		progress.max_value = quest["target"]
		progress.value = quest["progress"]
		progress.show_percentage = false
		progress.custom_minimum_size = Vector2(300, 10)
		row.add_child(progress)
		var status := Label.new()
		status.text = "%d/%d · +%d Beans%s" % [quest["progress"], quest["target"], quest["reward"], " · Claimed" if quest["claimed"] else ""]
		status.add_theme_font_size_override("font_size", 8)
		row.add_child(status)
		_rows_box.add_child(panel)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		var close_btn := find_children("*", "Button", true, false)
		if not close_btn.is_empty():
			close_btn[0].grab_focus()
			get_viewport().set_input_as_handled()


func _close() -> void:
	if is_instance_valid(_previous_focus):
		_previous_focus.call_deferred("grab_focus")
	queue_free()
