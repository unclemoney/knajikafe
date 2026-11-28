extends RefCounted
class_name LessonDetailRenderer

const JAPANESE_FONT = preload("res://Themes/japanese_font.tres")


static func show_word(container: VBoxContainer, word: VocabWord) -> void:
	AudioManager.stop_speech()
	clear(container)
	var display := add_label(container, word.get_display_text(), 28, true)
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_label(container, "Reading: %s" % (word.get_reading() if word.get_reading() != "" else "Not supplied"), 12, true)
	if word.romaji != "":
		add_label(container, "Derived romaji: %s" % word.romaji, 10)
	add_label(container, "Meaning: %s" % ("; ".join(word.english_meanings) if word.has_meaning() else "Unavailable in extraction"), 11)
	var level := "N%d" % word.jlpt_level if word.jlpt_level > 0 else "JLPT untagged"
	var pos := word.source_pos if word.source_pos != "" else word.part_of_speech
	add_label(container, "%s · %s · %s" % [level, pos, word.pitch], 8, true)
	var lessons := PackedStringArray()
	for lesson in word.lesson_ids:
		lessons.append(str(lesson))
	add_label(container, "Professional lessons: %s · %s" % [", ".join(lessons), word.stage], 9, true)
	add_label(container, "Source sections: %s" % ", ".join(word.source_sections), 8, true)
	var card := SRSEngine.get_card_for_vocab(word.id)
	if card:
		var stage := ProgressMetrics.get_stage_name(ProgressMetrics.get_card_stage(card))
		var review := card.next_review_date if card.next_review_date != "" else "New / unscheduled"
		add_label(container, "Learning: %s · %d/%d correct" % [stage, card.correct_reviews, card.total_reviews], 9)
		add_label(container, "Next review: %s" % review, 9)
	else:
		add_label(container, "Learning: Not introduced", 9)
	var audio_btn := Button.new()
	audio_btn.text = "Play pronunciation"
	audio_btn.custom_minimum_size = Vector2(0, 28)
	audio_btn.disabled = word.get_reading() == "" or not AudioManager.has_speech("vocab:" + word.id)
	audio_btn.pressed.connect(AudioManager.play_speech.bind("vocab:" + word.id))
	container.add_child(audio_btn)
	if not word.example_sentences.is_empty():
		add_label(container, "Professional examples", 11)
	for example in word.example_sentences:
		var parts := example.split("|")
		add_label(container, parts[0], 11, true)
		if parts.size() > 1:
			add_label(container, parts[1], 9)
	add_label(container, "Source: markdown/%s" % word.source_file, 7)


static func show_grammar(container: VBoxContainer, grammar: Dictionary) -> void:
	AudioManager.stop_speech()
	clear(container)
	add_label(container, grammar["title"], 18, true)
	add_label(container, "Lesson %d · %s · %s" % [grammar["lesson"], grammar["stage"], grammar["kind"]], 9, true)
	if grammar.get("category", "") != "":
		add_label(container, "Category: %s" % grammar["category"], 9, true)
	add_label(container, "Professional explanation", 11)
	for line in grammar["body_lines"]:
		add_label(container, line, 9, true)
	add_label(container, "Source: markdown/%s · line %d · page %d" % [grammar["source_file"], grammar["source_line"], grammar["source_page"]], 7)


static func clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


static func add_label(container: VBoxContainer, text: String, font_size: int, japanese: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	if japanese:
		label.add_theme_font_override("font", JAPANESE_FONT)
	container.add_child(label)
	return label
