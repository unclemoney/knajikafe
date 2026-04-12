extends CanvasLayer
class_name LevelUpNotification
## LevelUpNotification
##
## A reusable popup overlay that shows a level-up notification.
## Can be added as a child of GameController to display on any scene.

var _panel: PanelContainer = null
var _label: Label = null


func _ready() -> void:
	layer = 99
	_build_ui()


## Shows the level-up notification with the new level.
func show_level_up(new_level: int) -> void:
	_label.text = "⭐ Level Up! Level %d! ⭐" % new_level
	_panel.visible = true
	_panel.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_panel.set.bind("visible", false))


## Builds the notification UI programmatically.
func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.anchors_preset = Control.PRESET_CENTER_TOP
	_panel.offset_top = 16.0
	_panel.offset_left = -120.0
	_panel.offset_right = 120.0
	_panel.offset_bottom = 52.0

	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.15, 0.1, 0.95)
	stylebox.border_color = Color(1.0, 0.9, 0.3, 1.0)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(4)
	stylebox.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", stylebox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	_label.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_label)

	add_child(_panel)
