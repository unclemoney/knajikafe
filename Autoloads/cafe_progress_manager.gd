extends Node
## CafeProgressManager
## Coffee Beans, daily goals, decoration ownership, and cat bonds.

const DAILY_SKILLS: Array[String] = ["meaning", "reading", "context", "listening", "kanji_form"]
var _dialogue: Dictionary = {}

const SPECIALTY_CATS := {
	"multiple_choice": "mochi",
	"kanji_matching": "sushi",
	"flashcard_review": "matcha",
	"fill_in_blank": "sakura",
	"typing_input": "kinako",
	"cafe_orders": "azuki",
	"reading_shelf": "sakura",
	"kanji_workshop": "sushi",
}


func _ready() -> void:
	var file := FileAccess.open("res://Resources/Dialogue/cat_dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			_dialogue = parsed


func apply_session(summary: Dictionary) -> Dictionary:
	var profile := GameController.current_profile
	if profile == null or summary.get("words_reviewed", 0) <= 0:
		return {"base_beans": 0, "quest_beans": 0, "total_beans": 0, "completed_goals": [], "bond_gain": 0}
	var today := GameController.get_current_date()
	_ensure_quest_state(profile, today)
	var signature := "%s|%s|%s" % [summary.get("timestamp", ""), summary.get("game_type", ""), summary.get("correct_count", 0)]
	if profile.quest_progress.get("last_reward_signature", "") == signature:
		return {"base_beans": 0, "quest_beans": 0, "total_beans": 0, "completed_goals": [], "bond_gain": 0}
	profile.quest_progress["last_reward_signature"] = signature

	var base_beans := 5 + int(summary.get("correct_count", 0))
	profile.coffee_beans += base_beans
	profile.total_beans_earned += base_beans
	profile.quest_progress["items"] = int(profile.quest_progress.get("items", 0)) + int(summary["words_reviewed"])
	profile.quest_progress["activities"][summary["game_type"]] = true
	var skill_results: Dictionary = summary.get("skill_results", {})
	for skill in skill_results:
		var current := int(profile.quest_progress["skills"].get(skill, 0))
		profile.quest_progress["skills"][skill] = current + int(skill_results[skill].get("correct", 0))

	var quest_beans := 0
	var completed: Array = []
	for quest in get_daily_quests():
		if not quest["claimed"] and int(quest["progress"]) >= int(quest["target"]):
			quest_beans += int(quest["reward"])
			completed.append(quest["title"])
			profile.quest_claimed[quest["id"]] = true
	profile.coffee_beans += quest_beans
	profile.total_beans_earned += quest_beans
	var bond_gain := apply_specialty_bond(summary.get("game_type", ""))
	return {
		"base_beans": base_beans,
		"quest_beans": quest_beans,
		"total_beans": base_beans + quest_beans,
		"completed_goals": completed,
		"bond_gain": bond_gain,
	}


func get_daily_quests() -> Array:
	var profile := GameController.current_profile
	if profile == null:
		return []
	var today := GameController.get_current_date()
	_ensure_quest_state(profile, today)
	var skill: String = profile.quest_progress["focus_skill"]
	return [
		{"id": "daily_review", "title": "Daily Review", "description": "Complete 10 reviewed items", "target": 10, "reward": 20, "progress": mini(int(profile.quest_progress["items"]), 10), "claimed": profile.quest_claimed.has("daily_review")},
		{"id": "skill_focus", "title": "Skill Focus: " + skill.capitalize(), "description": "Get 5 correct %s answers" % skill, "target": 5, "reward": 15, "progress": mini(int(profile.quest_progress["skills"].get(skill, 0)), 5), "claimed": profile.quest_claimed.has("skill_focus")},
		{"id": "cafe_variety", "title": "Café Variety", "description": "Complete 2 different activities", "target": 2, "reward": 15, "progress": mini(profile.quest_progress["activities"].size(), 2), "claimed": profile.quest_claimed.has("cafe_variety")},
	]


func _ensure_quest_state(profile: PlayerProfile, today: String) -> void:
	if profile.quest_date == today and profile.quest_progress.has("focus_skill"):
		return
	profile.quest_date = today
	profile.quest_progress = {"items": 0, "skills": {}, "activities": {}, "focus_skill": DAILY_SKILLS[int(abs(hash(profile.player_name + today))) % DAILY_SKILLS.size()]}
	profile.quest_claimed = {}


func owns_decoration(decoration_id: String) -> bool:
	var profile := GameController.current_profile
	return profile != null and profile.owned_decorations.has(decoration_id)


func can_purchase(decor: CafeDecoration) -> Dictionary:
	var profile := GameController.current_profile
	if profile == null:
		return {"allowed": false, "reason": "No profile"}
	if owns_decoration(decor.id):
		return {"allowed": false, "reason": "Owned"}
	if not is_level_unlocked(decor, profile):
		return {"allowed": false, "reason": "Level locked"}
	if profile.coffee_beans < decor.cost:
		return {"allowed": false, "reason": "Need %d Beans" % (decor.cost - profile.coffee_beans)}
	return {"allowed": true, "reason": ""}


func purchase_decoration(decor: CafeDecoration) -> Dictionary:
	var check := can_purchase(decor)
	if not check["allowed"]:
		return {"success": false, "reason": check["reason"]}
	var profile := GameController.current_profile
	profile.coffee_beans -= decor.cost
	profile.owned_decorations[decor.id] = true
	SaveManager.save_profile(profile)
	return {"success": true, "reason": ""}


func is_level_unlocked(decor: CafeDecoration, profile: PlayerProfile) -> bool:
	if decor.unlock_condition == "default":
		return true
	if decor.unlock_condition.begins_with("level:"):
		return profile.level >= int(decor.unlock_condition.split(":")[1])
	return false


func pet_cat(cat_id: String) -> int:
	var profile := GameController.current_profile
	if profile == null or not profile.unlocked_cats.has(cat_id):
		return 0
	var today := GameController.get_current_date()
	var key := "pet:" + cat_id
	if profile.cat_bond_dates.get(key, "") == today:
		return 0
	profile.cat_bond_dates[key] = today
	profile.cat_bonds[cat_id] = int(profile.cat_bonds.get(cat_id, 0)) + 1
	return 1


func apply_specialty_bond(game_type: String) -> int:
	var profile := GameController.current_profile
	if profile == null or not SPECIALTY_CATS.has(game_type):
		return 0
	var cat_id: String = SPECIALTY_CATS[game_type]
	if not profile.unlocked_cats.has(cat_id):
		return 0
	var today := GameController.get_current_date()
	var key := "session:" + cat_id
	if profile.cat_bond_dates.get(key, "") == today:
		return 0
	profile.cat_bond_dates[key] = today
	profile.cat_bonds[cat_id] = int(profile.cat_bonds.get(cat_id, 0)) + 2
	return 2


func get_dialogue_lines(cat_id: String) -> Array:
	var stage := str(get_dialogue_stage(cat_id))
	if _dialogue.has(cat_id) and _dialogue[cat_id].has(stage):
		return _dialogue[cat_id][stage]
	return []


func get_specialty_dialogue(game_type: String) -> String:
	if not SPECIALTY_CATS.has(game_type):
		return ""
	var lines := get_dialogue_lines(SPECIALTY_CATS[game_type])
	if lines.is_empty():
		return ""
	return lines[randi() % lines.size()]


func get_dialogue_stage(cat_id: String) -> int:
	var profile := GameController.current_profile
	if profile == null:
		return 0
	var bond := int(profile.cat_bonds.get(cat_id, 0))
	var stage := 0
	for threshold in [50, 25, 10]:
		if bond >= threshold:
			stage = threshold
			break
	return stage


func get_next_bond_threshold(cat_id: String) -> int:
	var profile := GameController.current_profile
	if profile == null:
		return 0
	var bond := int(profile.cat_bonds.get(cat_id, 0))
	for threshold in [10, 25, 50]:
		if bond < threshold:
			return threshold
	return 0
