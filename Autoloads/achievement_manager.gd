extends Node
## AchievementManager (Autoload)
##
## Manages achievement definitions, checking unlock conditions,
## and displaying popup notifications. Registered as an autoload singleton.

## Emitted when an achievement is unlocked.
signal achievement_unlocked(achievement: AchievementDef)

## All loaded achievement definitions, keyed by id.
var _achievements: Dictionary = {}

## Popup notification overlay.
var _popup: AchievementPopup = null

## Path to achievement definition resources.
const ACHIEVEMENT_DIR := "res://Resources/Achievements/"


func _ready() -> void:
	_load_achievements()
	_setup_popup()


## Checks all achievements against the current profile and session data.
## Call after quiz completion, level-up, cat unlock, etc.
func check_achievements() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var newly_unlocked: Array[AchievementDef] = []
	for achievement in _achievements.values():
		if achievement is AchievementDef:
			if profile.unlocked_achievements.has(achievement.id):
				continue
			if _is_condition_met(achievement.unlock_condition, profile):
				profile.unlocked_achievements.append(achievement.id)
				newly_unlocked.append(achievement)

	if newly_unlocked.size() > 0:
		SaveManager.save_profile(profile)
		for ach in newly_unlocked:
			achievement_unlocked.emit(ach)
			_show_popup(ach)


## Returns all achievement definitions.
func get_all_achievements() -> Array[AchievementDef]:
	var results: Array[AchievementDef] = []
	for ach in _achievements.values():
		if ach is AchievementDef:
			results.append(ach)
	return results


## Returns true if the given achievement is unlocked for the current profile.
func is_unlocked(achievement_id: String) -> bool:
	var profile := GameController.current_profile
	if profile == null:
		return false
	return profile.unlocked_achievements.has(achievement_id)


## Returns the count of unlocked achievements.
func get_unlocked_count() -> int:
	var profile := GameController.current_profile
	if profile == null:
		return 0
	return profile.unlocked_achievements.size()


## Returns total number of achievements.
func get_total_count() -> int:
	return _achievements.size()


## Evaluates a condition string against the player profile.
func _is_condition_met(condition: String, profile: PlayerProfile) -> bool:
	if condition == "":
		return false
	var parts := condition.split(":")
	if parts.size() < 2:
		return false

	var cond_type := parts[0]
	var cond_value := parts[1].to_int()

	if cond_type == "level":
		return profile.level >= cond_value
	elif cond_type == "streak":
		return profile.streak_days >= cond_value
	elif cond_type == "cats_unlocked":
		return profile.unlocked_cats.size() >= cond_value
	elif cond_type == "words_learned":
		return SRSEngine.get_total_card_count() >= cond_value
	elif cond_type == "quiz_count":
		return SRSEngine.get_total_card_count() >= 1
	elif cond_type == "decorations":
		return profile.cafe_decorations.size() >= cond_value
	elif cond_type == "achievements":
		return profile.unlocked_achievements.size() >= cond_value
	elif cond_type == "xp":
		return profile.xp >= cond_value
	return false


## Loads all achievement .tres files from the Achievements directory.
func _load_achievements() -> void:
	var dir := DirAccess.open(ACHIEVEMENT_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var ach := load(ACHIEVEMENT_DIR + file_name) as AchievementDef
			if ach != null and ach.id != "":
				_achievements[ach.id] = ach
		file_name = dir.get_next()
	dir.list_dir_end()
	print("AchievementManager: Loaded %d achievements." % _achievements.size())


## Creates the popup overlay.
func _setup_popup() -> void:
	_popup = AchievementPopup.new()
	add_child(_popup)


## Shows the achievement unlock popup.
func _show_popup(achievement: AchievementDef) -> void:
	if _popup:
		AudioManager.play_achievement()
		_popup.show_achievement(achievement)
