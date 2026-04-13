extends CanvasLayer
class_name AchievementPopup
## AchievementPopup
##
## Animated popup notification that displays when an achievement is unlocked.
## Shows the achievement title and description with a slide-in/fade animation.

var _panel: PanelContainer = null
var _title_label: Label = null
var _desc_label: Label = null
var _queue: Array[AchievementDef] = []
var _is_showing: bool = false


func _ready() -> void:
	layer = 98
	_build_ui()


## Queues an achievement to display. Shows immediately if nothing is showing.
func show_achievement(achievement: AchievementDef) -> void:
	_queue.append(achievement)
	if not _is_showing:
		_show_next()


## Shows the next achievement in the queue.
func _show_next() -> void:
	if _queue.size() == 0:
		_is_showing = false
		return

	_is_showing = true
	var ach: AchievementDef = _queue.pop_front()
	_title_label.text = "🏆 " + ach.title
	_desc_label.text = ach.description
	_panel.visible = true
	_panel.modulate = Color(1, 1, 1, 0)
	_panel.position.y = -60.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(_panel, "position:y", 8.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(2.5)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_panel.set.bind("visible", false))
	tween.tween_callback(_show_next)


## Builds the popup UI programmatically.
func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.anchors_preset = Control.PRESET_CENTER_TOP
	_panel.offset_top = 8.0
	_panel.offset_left = -140.0
	_panel.offset_right = 140.0
	_panel.offset_bottom = 60.0

	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.12, 0.08, 0.95)
	stylebox.border_color = Color(0.9, 0.75, 0.2, 1.0)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(4)
	stylebox.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", stylebox)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	_title_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
	_desc_label.add_theme_font_size_override("font_size", 9)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_desc_label)

	_panel.add_child(vbox)
	add_child(_panel)
