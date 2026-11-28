extends Node

const TEST_QUESTION_COUNT := 20
const PASS_CORRECT_COUNT := 16


func is_unlocked(lesson: int, profile: PlayerProfile = null) -> bool:
	if profile == null:
		profile = GameController.current_profile
	if profile == null or lesson < 1 or lesson > VocabDatabase.get_lessons().size():
		return false
	return lesson <= profile.highest_unlocked_lesson


func is_passed(lesson: int, profile: PlayerProfile = null) -> bool:
	if profile == null:
		profile = GameController.current_profile
	if profile == null:
		return false
	return bool(get_test_record(lesson, profile).get("passed", false))


func get_current_lesson(profile: PlayerProfile = null) -> int:
	if profile == null:
		profile = GameController.current_profile
	if profile == null:
		return 1
	return clampi(profile.current_lesson, 1, profile.highest_unlocked_lesson)


func get_focus_lesson(config: Dictionary) -> int:
	var lesson := int(config.get("lesson_number", 0))
	if lesson > 0 and is_unlocked(lesson):
		return lesson
	return get_current_lesson()


func can_take_test(lesson: int, profile: PlayerProfile = null) -> bool:
	if profile == null:
		profile = GameController.current_profile
	if profile == null or not is_unlocked(lesson, profile):
		return false
	return not bool(profile.lesson_test_practice_required.get("lesson_%02d" % lesson, false))


func record_practice_session(profile: PlayerProfile = null) -> void:
	if profile == null:
		profile = GameController.current_profile
	if profile == null:
		return
	profile.lesson_test_practice_required.erase("lesson_%02d" % profile.current_lesson)


func get_test_record(lesson: int, profile: PlayerProfile = null) -> Dictionary:
	if profile == null:
		profile = GameController.current_profile
	if profile == null:
		return {}
	return profile.lesson_results.get("lesson_%02d" % lesson, {})


func get_lesson_state(lesson: int, profile: PlayerProfile = null) -> String:
	if not is_unlocked(lesson, profile):
		return "locked"
	if is_passed(lesson, profile):
		return "passed"
	if lesson == get_current_lesson(profile):
		return "current"
	return "unlocked"


func record_test_result(lesson: int, correct_count: int, vocabulary_correct: int, cloze_correct: int, questions_answered: int = TEST_QUESTION_COUNT) -> Dictionary:
	var profile := GameController.current_profile
	if profile == null or not is_unlocked(lesson, profile):
		return {"save_ok": false, "error": "This lesson is not unlocked."}
	if not can_take_test(lesson, profile):
		return {"save_ok": false, "practice_required": true, "error": "Complete a practice session before retrying this test."}
	var snapshot := profile.duplicate(true) as PlayerProfile
	var key := "lesson_%02d" % lesson
	var previous := get_test_record(lesson, profile)
	var passed := questions_answered == TEST_QUESTION_COUNT and correct_count >= PASS_CORRECT_COUNT
	var record := {
		"attempts": int(previous.get("attempts", 0)) + 1,
		"best_score": maxi(int(previous.get("best_score", 0)), correct_count),
		"passed": passed or bool(previous.get("passed", false)),
		"last_score": correct_count,
		"vocabulary_correct": vocabulary_correct,
		"cloze_correct": cloze_correct,
		"questions_answered": questions_answered,
		"timestamp": Time.get_datetime_string_from_system(),
	}
	profile.lesson_results[key] = record
	if passed:
		profile.lesson_test_practice_required.erase(key)
	else:
		profile.lesson_test_practice_required[key] = true
	var newly_unlocked := 0
	if passed and lesson == profile.current_lesson and lesson == profile.highest_unlocked_lesson:
		if lesson < VocabDatabase.get_lessons().size():
			profile.highest_unlocked_lesson += 1
			profile.current_lesson += 1
			newly_unlocked = profile.current_lesson
	profile.settings["target_lesson"] = profile.current_lesson
	var save_ok := SaveManager.save_profile(profile)
	if not save_ok:
		profile.current_lesson = snapshot.current_lesson
		profile.highest_unlocked_lesson = snapshot.highest_unlocked_lesson
		profile.lesson_results = snapshot.lesson_results.duplicate(true)
		profile.lesson_test_practice_required = snapshot.lesson_test_practice_required.duplicate(true)
		profile.settings = snapshot.settings.duplicate(true)
	return {
		"save_ok": save_ok,
		"lesson_number": lesson,
		"correct_count": correct_count,
		"passed": passed,
		"newly_unlocked": newly_unlocked,
		"vocabulary_correct": vocabulary_correct,
		"cloze_correct": cloze_correct,
		"attempts": record["attempts"],
		"best_score": record["best_score"],
		"questions_answered": questions_answered,
		"practice_required": not passed,
		"error": "" if save_ok else "The result could not be saved. Please retry the test.",
	}
