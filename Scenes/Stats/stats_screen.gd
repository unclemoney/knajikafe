extends Control
## stats_screen.gd
##
## Displays comprehensive player statistics: words learned, review history,
## JLPT progress, cat collection count, and overall performance.

@onready var back_btn: Button = $TopBar/BackBtn
@onready var stats_container: VBoxContainer = $ScrollContainer/StatsVBox

const CAT_DIR := "res://Resources/Cats/"


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_build_stats()


## Builds all stats sections dynamically.
func _build_stats() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	_add_section_header("📊 Player Overview")
	_add_stat_row("Name", profile.player_name)
	_add_stat_row("Level", str(profile.level))
	_add_stat_row("Total XP", str(profile.xp))
	_add_stat_row("XP to Next Level", str(profile.xp_to_next_level()))
	_add_progress_bar("Level Progress", profile.level_progress())
	_add_spacer()

	_add_section_header("🔥 Streak")
	_add_stat_row("Current Streak", str(profile.streak_days) + " days")
	var mult := profile.get_streak_multiplier()
	_add_stat_row("Streak Bonus", "x%.2f" % mult)
	_add_spacer()

	_add_section_header("📚 Review Stats")
	var total_cards := SRSEngine.get_total_card_count()
	var due_cards := SRSEngine.get_due_count()
	_add_stat_row("Total Cards", str(total_cards))
	_add_stat_row("Cards Due", str(due_cards))
	if total_cards > 0:
		var mastered := total_cards - due_cards
		var mastery_pct := float(mastered) / float(total_cards)
		_add_progress_bar("Mastery", mastery_pct)
	_add_spacer()

	_add_section_header("🐱 Cat Collection")
	var total_cats := _count_total_cats()
	var unlocked := profile.unlocked_cats.size()
	_add_stat_row("Cats Unlocked", str(unlocked) + " / " + str(total_cats))
	if total_cats > 0:
		_add_progress_bar("Collection", float(unlocked) / float(total_cats))
	_add_spacer()

	_add_section_header("🎨 Decorations")
	_add_stat_row("Active Decorations", str(profile.cafe_decorations.size()))
	_add_spacer()

	_add_section_header("📅 Account")
	_add_stat_row("Created", profile.created_date)
	_add_stat_row("Last Played", profile.last_played)


## Counts total cat .tres files in the Cats directory.
func _count_total_cats() -> int:
	var count := 0
	var dir := DirAccess.open(CAT_DIR)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


## Adds a section header label.
func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.87, 0.7, 1))
	stats_container.add_child(lbl)


## Adds a key-value stat row.
func _add_stat_row(key: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.add_theme_font_size_override("font_size", 8)
	key_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 1))
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 8)
	val_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65, 1))
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	stats_container.add_child(row)


## Adds a progress bar with a label.
func _add_progress_bar(label_text: String, progress: float) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 1))
	lbl.custom_minimum_size = Vector2(80, 0)
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(120, 10)
	bar.max_value = 100.0
	bar.value = progress * 100.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	var pct_lbl := Label.new()
	pct_lbl.text = "%d%%" % int(progress * 100.0)
	pct_lbl.add_theme_font_size_override("font_size", 7)
	pct_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6, 1))
	pct_lbl.custom_minimum_size = Vector2(32, 0)
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(pct_lbl)

	stats_container.add_child(row)


## Adds vertical spacing between sections.
func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	stats_container.add_child(spacer)


## Returns to the cafe hub.
func _on_back_pressed() -> void:
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
