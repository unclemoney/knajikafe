extends PanelContainer
class_name KanaKeyboard
## kana_keyboard.gd
##
## On-screen hiragana keyboard with dakuten/handakuten and small kana toggles.
## Emits key_pressed(character) when a kana button is tapped.
## Includes backspace and submit buttons.

signal key_pressed(character: String)
signal submit_pressed
signal backspace_pressed

## Base hiragana grid (5 columns × 10 rows + n)
const KANA_GRID: Array = [
	["あ", "い", "う", "え", "お"],
	["か", "き", "く", "け", "こ"],
	["さ", "し", "す", "せ", "そ"],
	["た", "ち", "つ", "て", "と"],
	["な", "に", "ぬ", "ね", "の"],
	["は", "ひ", "ふ", "へ", "ほ"],
	["ま", "み", "む", "め", "も"],
	["や", "", "ゆ", "", "よ"],
	["ら", "り", "る", "れ", "ろ"],
	["わ", "", "を", "", "ん"],
]

## Dakuten variants (゛)
const DAKUTEN_GRID: Array = [
	["あ", "い", "う", "え", "お"],
	["が", "ぎ", "ぐ", "げ", "ご"],
	["ざ", "じ", "ず", "ぜ", "ぞ"],
	["だ", "ぢ", "づ", "で", "ど"],
	["な", "に", "ぬ", "ね", "の"],
	["ば", "び", "ぶ", "べ", "ぼ"],
	["ま", "み", "む", "め", "も"],
	["や", "", "ゆ", "", "よ"],
	["ら", "り", "る", "れ", "ろ"],
	["わ", "", "を", "", "ん"],
]

## Handakuten variants (゜)
const HANDAKUTEN_GRID: Array = [
	["あ", "い", "う", "え", "お"],
	["か", "き", "く", "け", "こ"],
	["さ", "し", "す", "せ", "そ"],
	["た", "ち", "つ", "て", "と"],
	["な", "に", "ぬ", "ね", "の"],
	["ぱ", "ぴ", "ぷ", "ぺ", "ぽ"],
	["ま", "み", "む", "め", "も"],
	["や", "", "ゆ", "", "よ"],
	["ら", "り", "る", "れ", "ろ"],
	["わ", "", "を", "", "ん"],
]

## Small kana row
const SMALL_KANA: Array = ["ゃ", "ゅ", "ょ", "っ", "ー"]

## Current mode: "base", "dakuten", "handakuten"
var _mode: String = "base"

## The grid container holding kana buttons
var _grid: GridContainer = null

## The main content VBox (hidden when minimized)
var _content_vbox: VBoxContainer = null

## Toggle buttons
var _dakuten_btn: Button = null
var _handakuten_btn: Button = null
var _small_btn: Button = null
var _showing_small: bool = false

## Minimize state
var _minimized: bool = false
var _minimize_btn: Button = null


func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.07, 0.95)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.border_width_top = 2
	style.border_color = Color(0.6, 0.5, 0.35, 1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 2)
	add_child(outer_vbox)

	# Minimize/expand bar
	var min_row := HBoxContainer.new()
	min_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_child(min_row)

	_minimize_btn = Button.new()
	_minimize_btn.text = "▼ Hide Keyboard"
	_minimize_btn.custom_minimum_size = Vector2(120, 20)
	_minimize_btn.add_theme_font_size_override("font_size", 9)
	_minimize_btn.pressed.connect(_on_minimize_toggled)
	min_row.add_child(_minimize_btn)

	# Content container (hidden when minimized)
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 2)
	outer_vbox.add_child(_content_vbox)

	# Toggle row
	var toggle_row := HBoxContainer.new()
	toggle_row.add_theme_constant_override("separation", 4)
	toggle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_vbox.add_child(toggle_row)

	_dakuten_btn = _make_toggle_btn("゛")
	_dakuten_btn.pressed.connect(_on_dakuten_toggled)
	toggle_row.add_child(_dakuten_btn)

	_handakuten_btn = _make_toggle_btn("゜")
	_handakuten_btn.pressed.connect(_on_handakuten_toggled)
	toggle_row.add_child(_handakuten_btn)

	_small_btn = _make_toggle_btn("小")
	_small_btn.pressed.connect(_on_small_toggled)
	toggle_row.add_child(_small_btn)

	var backspace_btn := _make_toggle_btn("⌫")
	backspace_btn.pressed.connect(func(): backspace_pressed.emit())
	toggle_row.add_child(backspace_btn)

	var submit_btn := _make_toggle_btn("✓")
	submit_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 1))
	submit_btn.pressed.connect(func(): submit_pressed.emit())
	toggle_row.add_child(submit_btn)

	# Kana grid
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	_content_vbox.add_child(_grid)

	_rebuild_grid()


## Rebuilds the kana grid based on the current mode.
func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	if _showing_small:
		for kana in SMALL_KANA:
			_grid.add_child(_make_kana_btn(kana))
		return

	var grid: Array = KANA_GRID
	if _mode == "dakuten":
		grid = DAKUTEN_GRID
	elif _mode == "handakuten":
		grid = HANDAKUTEN_GRID

	for row in grid:
		for kana in row:
			if kana == "":
				var spacer := Control.new()
				spacer.custom_minimum_size = Vector2(28, 24)
				_grid.add_child(spacer)
			else:
				_grid.add_child(_make_kana_btn(kana))


## Creates a kana button.
func _make_kana_btn(kana: String) -> Button:
	var btn := Button.new()
	btn.text = kana
	btn.custom_minimum_size = Vector2(28, 24)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(_on_kana_pressed.bind(kana))

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.16, 0.12, 1)
	style_normal.corner_radius_top_left = 2
	style_normal.corner_radius_top_right = 2
	style_normal.corner_radius_bottom_left = 2
	style_normal.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.28, 0.2, 1)
	style_hover.corner_radius_top_left = 2
	style_hover.corner_radius_top_right = 2
	style_hover.corner_radius_bottom_left = 2
	style_hover.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.5, 0.4, 0.3, 1)
	style_pressed.corner_radius_top_left = 2
	style_pressed.corner_radius_top_right = 2
	style_pressed.corner_radius_bottom_left = 2
	style_pressed.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("pressed", style_pressed)

	return btn


## Creates a toggle/action button for the top row.
func _make_toggle_btn(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(40, 22)
	btn.add_theme_font_size_override("font_size", 10)
	return btn


func _on_kana_pressed(kana: String) -> void:
	key_pressed.emit(kana)
	AudioManager.play_card_flip()


## Toggles keyboard visibility between minimized and expanded.
func _on_minimize_toggled() -> void:
	_minimized = not _minimized
	_content_vbox.visible = not _minimized
	if _minimized:
		_minimize_btn.text = "▲ Show Keyboard"
		custom_minimum_size = Vector2(320, 28)
		offset_top = -32
	else:
		_minimize_btn.text = "▼ Hide Keyboard"
		custom_minimum_size = Vector2(320, 180)
		offset_top = -185


func _on_dakuten_toggled() -> void:
	if _mode == "dakuten":
		_mode = "base"
	else:
		_mode = "dakuten"
	_showing_small = false
	_update_toggle_visuals()
	_rebuild_grid()


func _on_handakuten_toggled() -> void:
	if _mode == "handakuten":
		_mode = "base"
	else:
		_mode = "handakuten"
	_showing_small = false
	_update_toggle_visuals()
	_rebuild_grid()


func _on_small_toggled() -> void:
	_showing_small = not _showing_small
	if _showing_small:
		_mode = "base"
	_update_toggle_visuals()
	_rebuild_grid()


## Updates toggle button appearance to show active state.
func _update_toggle_visuals() -> void:
	var active_color := Color(0.9, 0.75, 0.2, 1)
	var inactive_color := Color(0.8, 0.8, 0.8, 1)

	_dakuten_btn.add_theme_color_override("font_color", active_color if _mode == "dakuten" else inactive_color)
	_handakuten_btn.add_theme_color_override("font_color", active_color if _mode == "handakuten" else inactive_color)
	_small_btn.add_theme_color_override("font_color", active_color if _showing_small else inactive_color)
