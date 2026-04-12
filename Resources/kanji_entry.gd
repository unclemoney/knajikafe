extends Resource
class_name KanjiEntry
## KanjiEntry
##
## A single kanji character with readings, meanings, and metadata.

## The kanji character itself (e.g., "食").
@export var character: String = ""

## English meanings for this kanji.
@export var meanings: PackedStringArray = []

## On'yomi (Chinese-origin) readings in katakana.
@export var on_readings: PackedStringArray = []

## Kun'yomi (Japanese-origin) readings in hiragana.
@export var kun_readings: PackedStringArray = []

## Number of brush strokes.
@export_range(1, 30) var stroke_count: int = 1

## JLPT level: 5 = N5, 4 = N4, 0 = custom/unclassified.
@export_range(0, 5) var jlpt_level: int = 5

## The radical this kanji belongs to.
@export var radical: String = ""

## Component kanji/radicals that make up this character.
@export var components: PackedStringArray = []


## Returns all readings combined (on + kun).
func get_all_readings() -> PackedStringArray:
	var readings: PackedStringArray = []
	readings.append_array(on_readings)
	readings.append_array(kun_readings)
	return readings


## Returns the primary meaning, or empty string.
func get_primary_meaning() -> String:
	if meanings.size() > 0:
		return meanings[0]
	return ""
