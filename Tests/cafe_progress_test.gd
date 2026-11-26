extends Control

var _passes := 0
var _failures := 0
const PROFILE_NAME := "__cafe_progress_test__"


func _ready() -> void:
	var saved_profile := GameController.current_profile
	var profile := PlayerProfile.new()
	profile.player_name = PROFILE_NAME
	profile.level = 2
	profile.unlocked_cats = PackedStringArray(["mochi", "sushi"])
	profile.cafe_decorations = PackedStringArray(["plant_bonsai"])
	GameController.current_profile = profile
	SaveManager._apply_profile_defaults(profile)
	_check("Equipped items migrate to ownership", profile.owned_decorations.has("plant_bonsai"))
	_check("Café defaults start empty", profile.coffee_beans == 0 and profile.total_beans_earned == 0 and profile.cat_bonds.is_empty())

	var first := {"timestamp": "2026-01-01T08:00", "game_type": "multiple_choice", "words_reviewed": 6, "correct_count": 5, "skill_results": {"meaning": {"correct": 5, "attempts": 5}}}
	var reward := CafeProgressManager.apply_session(first)
	_check("Base reward includes session and correct answers", reward["base_beans"] == 10 and profile.coffee_beans == 25)
	_check("Duplicate session gives no reward", CafeProgressManager.apply_session(first)["total_beans"] == 0 and profile.coffee_beans == 25)

	var second := {"timestamp": "2026-01-01T08:05", "game_type": "typing_input", "words_reviewed": 4, "correct_count": 5, "skill_results": {"meaning": {"correct": 5, "attempts": 5}}}
	reward = CafeProgressManager.apply_session(second)
	_check("All daily goals claim once", reward["quest_beans"] == 35 and profile.quest_claimed.size() == 3)
	_check("Daily reward accounting", profile.coffee_beans == 70 and profile.total_beans_earned == 70)
	_check("Daily skill is deterministic", CafeProgressManager.get_daily_quests()[1]["title"] == CafeProgressManager.get_daily_quests()[1]["title"])

	profile.quest_date = "2000-01-01"
	var old_beans := profile.coffee_beans
	CafeProgressManager.get_daily_quests()
	_check("Date rollover resets only quests", profile.quest_claimed.is_empty() and profile.coffee_beans == old_beans)

	var teapot := load("res://Resources/Decorations/table_teapot.tres") as CafeDecoration
	profile.coffee_beans = 0
	_check("Insufficient funds blocks purchase", not CafeProgressManager.can_purchase(teapot)["allowed"] and profile.owned_decorations.size() == 1)
	profile.coffee_beans = 100
	_check("Purchase deducts exact cost", CafeProgressManager.purchase_decoration(teapot)["success"] and profile.coffee_beans == 60 and profile.owned_decorations.has("table_teapot"))
	_check("Repeat purchase does not deduct", not CafeProgressManager.purchase_decoration(teapot)["success"] and profile.coffee_beans == 60)
	var lantern := load("res://Resources/Decorations/lantern_paper.tres") as CafeDecoration
	_check("Level requirement remains enforced", not CafeProgressManager.can_purchase(lantern)["allowed"])

	_check("Pet bond is capped daily", CafeProgressManager.pet_cat("mochi") == 1 and CafeProgressManager.pet_cat("mochi") == 0)
	_check("Specialty bond is capped daily", CafeProgressManager.apply_specialty_bond("multiple_choice") == 0 and profile.cat_bonds["mochi"] == 3)
	profile.cat_bonds["mochi"] = 10
	_check("Dialogue threshold unlocks", CafeProgressManager.get_dialogue_stage("mochi") == 10 and CafeProgressManager.get_next_bond_threshold("mochi") == 25 and not CafeProgressManager.get_dialogue_lines("mochi").is_empty())

	profile.settings["speech_volume"] = 0.4
	profile.settings["sfx_volume"] = 0.3
	AudioManager.apply_profile_settings(profile)
	_check("Speech volume is independent", AudioManager.speech_volume == 0.4 and AudioManager.sfx_volume == 0.3)
	_check("Missing audio uses fallback", AudioManager._load_optional_audio("res://missing.ogg", AudioManager._sfx_correct) == AudioManager._sfx_correct)
	_check("Two BGM players support crossfade", AudioManager._bgm_players.size() == 2)
	_check("Invalid session has no reward", CafeProgressManager.apply_session({"words_reviewed": 0})["total_beans"] == 0)

	SaveManager.delete_profile(PROFILE_NAME)
	GameController.current_profile = saved_profile
	AudioManager.stop_bgm(0.0)
	for player in AudioManager._sfx_players:
		player.stop()
	AudioManager.stop_speech()
	await get_tree().create_timer(0.1).timeout
	print("Café progress tests: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
