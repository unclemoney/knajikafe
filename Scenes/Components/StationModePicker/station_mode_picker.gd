extends Control
class_name StationModePicker

signal mode_selected(config: Dictionary)

var _title_label: Label
var _options_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.025, 0.02, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -180
	panel.offset_top = -125
	panel.offset_right = 180
	panel.offset_bottom = 125
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_title_label)
	_options_box = VBoxContainer.new()
	_options_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_options_box)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 28)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.pressed.connect(queue_free)
	vbox.add_child(cancel_btn)


func open(title: String, options: Array) -> void:
	_title_label.text = title
	for option in options:
		var button := Button.new()
		button.text = "%s\n%s" % [option["name"], option["description"]]
		button.custom_minimum_size = Vector2(320, 54)
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_select_option.bind(option))
		_options_box.add_child(button)
	if _options_box.get_child_count() > 0:
		_options_box.get_child(0).grab_focus()


func _select_option(option: Dictionary) -> void:
	mode_selected.emit(option["config"])
	queue_free()
