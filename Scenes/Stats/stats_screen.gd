extends Control
## Displays evidence-based vocabulary, skill, and collection progress.

const CAT_DIR := "res://Resources/Cats/"
const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")

@onready var back_btn: Button = $TopBar/BackBtn
@onready var stats_container: VBoxContainer = $ScrollContainer/StatsVBox


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_build_stats()


func _build_stats() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	_add_section_header("Player Level & XP")
	_add_note("Engagement rewards, separate from Japanese learning evidence.")
	_add_stat_row("Name", profile.player_name)
	_add_stat_row("Level", str(profile.level))
	_add_stat_row("Total XP", str(profile.xp))
	_add_stat_row("XP to Next Level", str(profile.xp_to_next_level()))
	_add_progress_bar("Level Progress", profile.level_progress())
	_add_spacer()

	var level_summary := ProgressMetrics.get_level_summary(
		SRSEngine.cards,
		VocabDatabase.get_all_words(),
		VocabDatabase.get_kanji_by_jlpt(5),
		5
	)
	_add_section_header("N5 Vocabulary")
	_add_progress_bar("Coverage %d/120" % level_summary["introduced"], level_summary["coverage"])
	_add_progress_bar("Retained %d/120" % level_summary["retained"], level_summary["retained_ratio"])
	var stages: Dictionary = level_summary["stage_counts"]
	_add_stat_row("Learning Stages", "New %d  |  Learning %d  |  Familiar %d  |  Retained %d" % [stages["New"], stages["Learning"], stages["Familiar"], stages["Retained"]])
	_add_note("Familiar: 2 successes, 6-day interval, 60% success. Retained: 3 successes, 14-day interval, 80% success.")
	_add_spacer()

	_add_section_header("Learning Skills")
	var skill_summary := ProgressMetrics.get_skill_summary(SRSEngine.cards, SRSEngine.kanji_cards)
	var empty_hints := {
		"meaning": "No data yet — play Quiz or Flashcards.",
		"reading": "No data yet — play Typing.",
		"context": "No data yet — play Fill Blank or Reading Shelf.",
		"listening": "No data yet — play Café Orders without text assist.",
		"kanji_form": "No data yet — play Kanji Workshop.",
	}
	for skill in ProgressMetrics.SKILL_IDS:
		var data: Dictionary = skill_summary[skill]
		if data["has_data"]:
			_add_stat_row(skill.capitalize(), "%d/%d correct  (%d%%), %d attempts" % [data["correct"], data["attempts"], int(data["success_rate"] * 100.0), data["attempts"]])
		else:
			_add_stat_row(skill.capitalize(), empty_hints[skill])
	_add_note("Flashcard ratings are self-reported; other activities use answered results.")
	_add_spacer()

	_add_section_header("N5 Kanji")
	var kanji_ratio := float(level_summary["kanji_encountered"]) / float(level_summary["total_kanji"])
	_add_progress_bar("Exposure %d/100" % level_summary["kanji_encountered"], kanji_ratio)
	var kanji_summary := ProgressMetrics.get_kanji_summary(SRSEngine.kanji_cards, VocabDatabase.get_kanji_by_jlpt(5), GameController.get_current_date())
	_add_progress_bar("Practiced %d/100" % kanji_summary["introduced"], kanji_summary["coverage"])
	_add_progress_bar("Retained %d/100" % kanji_summary["retained"], kanji_summary["retained_ratio"])
	_add_stat_row("Kanji Due", str(kanji_summary["due"]))
	_add_note("Exposure comes from vocabulary. Practiced and Retained come from Kanji Workshop.")
	_add_spacer()

	_add_section_header("Needs Practice")
	var practice_cards := ProgressMetrics.get_needs_practice(SRSEngine.cards, GameController.get_current_date())
	if practice_cards.is_empty():
		_add_note("Complete a review to reveal words that need practice.")
	for card in practice_cards:
		_add_practice_row(card)
	_add_spacer()
	_add_section_header("Kanji to Review")
	var kanji_practice := ProgressMetrics.get_kanji_needs_practice(SRSEngine.kanji_cards, GameController.get_current_date())
	if kanji_practice.is_empty():
		_add_note("Complete Kanji Workshop to reveal characters that need practice.")
	for card in kanji_practice:
		_add_kanji_practice_row(card)
	_add_spacer()

	_add_section_header("Recent Sessions")
	var history := SRSEngine.sessions.duplicate(true)
	history.reverse()
	if history.is_empty():
		_add_note("No completed learning sessions yet.")
	for i in mini(5, history.size()):
		var session: Dictionary = history[i]
		var timestamp: String = session.get("timestamp", "")
		var date := timestamp.left(10) if timestamp.length() >= 10 else "Recent"
		var game_name: String = session.get("game_type", "Session").replace("_", " ").capitalize()
		_add_stat_row("%s · %s" % [date, game_name], "%d/%d correct · +%d XP" % [session.get("correct_count", 0), session.get("words_reviewed", 0), session.get("xp_earned", 0)])
	_add_spacer()

	_add_section_header("Review Schedule")
	var total_cards := SRSEngine.get_total_card_count()
	var due_cards := SRSEngine.get_due_count()
	_add_stat_row("Introduced Cards", str(total_cards))
	_add_stat_row("Due Now", str(due_cards))
	_add_stat_row("Scheduled / Not Due", str(total_cards - due_cards))
	_add_spacer()

	_add_section_header("Cat Collection")
	var total_cats := _count_total_cats()
	var unlocked := profile.unlocked_cats.size()
	_add_stat_row("Cats Unlocked", str(unlocked) + " / " + str(total_cats))
	if total_cats > 0:
		_add_progress_bar("Collection", float(unlocked) / float(total_cats))
	_add_spacer()
	_add_section_header("Decorations & Account")
	_add_stat_row("Active Decorations", str(profile.cafe_decorations.size()))
	_add_stat_row("Created", profile.created_date)
	_add_stat_row("Last Played", profile.last_played)


func _add_practice_row(card: SRSCard) -> void:
	var word := VocabDatabase.get_word_by_id(card.vocab_id)
	if word == null:
		return
	var row := HBoxContainer.new()
	var japanese := Label.new()
	japanese.text = word.get_display_text()
	japanese.add_theme_font_override("font", JAPANESE_FONT)
	japanese.add_theme_font_size_override("font_size", 13)
	japanese.custom_minimum_size = Vector2(110, 0)
	row.add_child(japanese)
	var meaning := Label.new()
	meaning.text = word.get_primary_meaning()
	meaning.add_theme_font_size_override("font_size", 8)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(meaning)
	var due_text := "Due now" if card.is_due(GameController.get_current_date()) else card.next_review_date
	var evidence := Label.new()
	evidence.text = "%d/%d · %s" % [card.correct_reviews, card.total_reviews, due_text]
	evidence.add_theme_font_size_override("font_size", 8)
	row.add_child(evidence)
	stats_container.add_child(row)


func _add_kanji_practice_row(card: KanjiCard) -> void:
	var entry := VocabDatabase.get_kanji(card.character)
	if entry == null:
		return
	var row := HBoxContainer.new()
	var character := Label.new()
	character.text = card.character
	character.add_theme_font_override("font", JAPANESE_FONT)
	character.add_theme_font_size_override("font_size", 14)
	character.custom_minimum_size = Vector2(50, 0)
	row.add_child(character)
	var meaning := Label.new()
	meaning.text = entry.get_primary_meaning()
	meaning.add_theme_font_size_override("font_size", 8)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(meaning)
	var evidence := Label.new()
	evidence.text = "%d/%d · %s" % [card.correct_reviews, card.total_reviews, "Due now" if card.is_due(GameController.get_current_date()) else card.next_review_date]
	evidence.add_theme_font_size_override("font_size", 8)
	row.add_child(evidence)
	stats_container.add_child(row)


func _count_total_cats() -> int:
	var count := 0
	var dir := DirAccess.open(CAT_DIR)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.7, 1))
	stats_container.add_child(label)


func _add_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(0.65, 0.58, 0.48, 1))
	stats_container.add_child(label)


func _add_stat_row(key: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var key_label := Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 8)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 1))
	key_label.custom_minimum_size = Vector2(130, 0)
	row.add_child(key_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 8)
	value_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65, 1))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_label)
	stats_container.add_child(row)


func _add_progress_bar(label_text: String, progress: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 1))
	label.custom_minimum_size = Vector2(130, 0)
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(120, 10)
	bar.max_value = 100.0
	bar.value = clampf(progress, 0.0, 1.0) * 100.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	var percent := Label.new()
	percent.text = "%d%%" % int(progress * 100.0)
	percent.add_theme_font_size_override("font_size", 7)
	percent.custom_minimum_size = Vector2(32, 0)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(percent)
	stats_container.add_child(row)


func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	stats_container.add_child(spacer)


func _on_back_pressed() -> void:
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
