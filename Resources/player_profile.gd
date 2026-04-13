extends Resource
class_name PlayerProfile
## PlayerProfile
##
## Stores all persistent player data: identity, progress, settings, and unlocks.
## Saved per-profile to user://profiles/<name>/profile.tres.

## Display name chosen by the player.
@export var player_name: String = ""

## ISO 8601 date string when the profile was created.
@export var created_date: String = ""

## Total accumulated experience points.
@export var xp: int = 0

## Current player level (derived from XP thresholds).
@export var level: int = 1

## Current consecutive-day streak count.
@export var streak_days: int = 0

## ISO 8601 date string of the last play session.
@export var last_played: String = ""

## IDs of unlocked cat companions.
@export var unlocked_cats: PackedStringArray = []

## IDs of purchased/unlocked cafe decorations.
@export var cafe_decorations: PackedStringArray = []

## IDs of unlocked achievements.
@export var unlocked_achievements: PackedStringArray = []

## Whether the player has completed the tutorial.
@export var has_completed_tutorial: bool = false

## Player settings stored as a flat dictionary.
## Keys: "show_kanji", "show_furigana", "show_romaji", "show_english",
##        "bgm_volume", "sfx_volume", "words_per_session"
@export var settings: Dictionary = {
	"show_kanji": true,
	"show_furigana": true,
	"show_romaji": false,
	"show_english": true,
	"bgm_volume": 0.8,
	"sfx_volume": 0.8,
	"words_per_session": 10,
}


## Maximum streak bonus multiplier (e.g., 1.5 = +50% XP at max streak).
const MAX_STREAK_MULTIPLIER: float = 1.5

## Number of streak days to reach maximum bonus.
const STREAK_CAP_DAYS: int = 30

## XP thresholds for each level. Index = level, value = cumulative XP needed.
const LEVEL_THRESHOLDS: Array[int] = [
	0,     # Level 1 (starting)
	100,   # Level 2
	300,   # Level 3
	600,   # Level 4
	1000,  # Level 5
	1500,  # Level 6
	2100,  # Level 7
	2800,  # Level 8
	3600,  # Level 9
	4500,  # Level 10
	5500,  # Level 11
	6600,  # Level 12
	7800,  # Level 13
	9100,  # Level 14
	10500, # Level 15
]


## Adds XP and returns true if the player leveled up.
func add_xp(amount: int) -> bool:
	xp += amount
	var old_level := level
	_recalculate_level()
	return level > old_level


## Recalculates level from current XP.
func _recalculate_level() -> void:
	for i in range(LEVEL_THRESHOLDS.size() - 1, -1, -1):
		if xp >= LEVEL_THRESHOLDS[i]:
			level = i + 1
			return


## Returns XP needed for next level, or 0 if at max level.
func xp_to_next_level() -> int:
	if level >= LEVEL_THRESHOLDS.size():
		return 0
	return LEVEL_THRESHOLDS[level] - xp


## Returns progress toward next level as a float 0.0–1.0.
func level_progress() -> float:
	if level >= LEVEL_THRESHOLDS.size():
		return 1.0
	var current_threshold := LEVEL_THRESHOLDS[level - 1]
	var next_threshold := LEVEL_THRESHOLDS[level]
	var range_size := next_threshold - current_threshold
	if range_size <= 0:
		return 1.0
	return float(xp - current_threshold) / float(range_size)


## Updates the daily streak based on the current date.
## Call this once per session (e.g., when entering Cafe Hub).
## Returns true if the streak increased.
func update_streak(current_date: String) -> bool:
	if last_played == "":
		# First ever session
		streak_days = 1
		last_played = current_date
		return true

	if last_played == current_date:
		# Already played today — no change
		return false

	var yesterday := _subtract_days(current_date, 1)
	if last_played == yesterday:
		# Consecutive day — increment streak
		streak_days += 1
		last_played = current_date
		return true
	else:
		# Missed a day — reset streak
		streak_days = 1
		last_played = current_date
		return false


## Returns the XP multiplier based on current streak.
## Ranges from 1.0 (no streak) to MAX_STREAK_MULTIPLIER.
func get_streak_multiplier() -> float:
	if streak_days <= 1:
		return 1.0
	var progress := minf(float(streak_days) / float(STREAK_CAP_DAYS), 1.0)
	return 1.0 + progress * (MAX_STREAK_MULTIPLIER - 1.0)


## Subtracts days from an ISO date string and returns the new date.
func _subtract_days(date_str: String, days: int) -> String:
	var parts := date_str.split("-")
	if parts.size() != 3:
		return date_str
	var dict := {
		"year": parts[0].to_int(),
		"month": parts[1].to_int(),
		"day": parts[2].to_int(),
		"hour": 0,
		"minute": 0,
		"second": 0,
	}
	var unix := Time.get_unix_time_from_datetime_dict(dict)
	unix -= days * 86400
	var new_dict := Time.get_date_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [new_dict["year"], new_dict["month"], new_dict["day"]]
