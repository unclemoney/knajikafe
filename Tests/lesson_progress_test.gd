extends Control

const PROFILE_NAME := "__lesson_progress_test__"

var _passes := 0
var _failures := 0


func _ready() -> void:
	SaveManager.delete_profile(PROFILE_NAME)
	var saved_cards := SRSEngine.cards
	var saved_profile := GameController.current_profile
	var profile := SaveManager.create_profile(PROFILE_NAME)
	GameController.current_profile = profile
	_check("New profiles start at Lesson 1", profile.current_lesson == 1 and profile.highest_unlocked_lesson == 1)
	_check("Only Lesson 1 is unlocked", LessonProgressManager.is_unlocked(1) and not LessonProgressManager.is_unlocked(2))
	_check("All lessons have 20 test questions", VocabDatabase.lesson_tests.size() == 900 and _test_banks_valid())
	var failed := LessonProgressManager.record_test_result(1, 15, 8, 7)
	_check("Fifteen correct answers fail without unlocking", failed["save_ok"] and not failed["passed"] and profile.current_lesson == 1 and profile.highest_unlocked_lesson == 1)
	_check("Failure requires practice before retry", not LessonProgressManager.can_take_test(1))
	var blocked_retry := LessonProgressManager.record_test_result(1, 20, 10, 10)
	_check("Blocked retries are rejected", not blocked_retry["save_ok"] and bool(blocked_retry.get("practice_required", false)))
	var blocked_profile := SaveManager.load_profile(PROFILE_NAME)
	_check("Practice requirement survives reload", not LessonProgressManager.can_take_test(1, blocked_profile))
	LessonProgressManager.record_practice_session()
	_check("Completed practice clears the retry block", LessonProgressManager.can_take_test(1))
	var passed := LessonProgressManager.record_test_result(1, 16, 8, 8)
	_check("Sixteen correct answers unlock Lesson 2", passed["passed"] and passed["newly_unlocked"] == 2 and profile.current_lesson == 2)
	_check("Attempts and best score persist", int(LessonProgressManager.get_test_record(1)["attempts"]) == 2 and int(LessonProgressManager.get_test_record(1)["best_score"]) == 16)
	LessonProgressManager.record_test_result(1, 20, 10, 10)
	_check("Review test retries cannot skip ahead", profile.current_lesson == 2 and profile.highest_unlocked_lesson == 2)
	LessonProgressManager.record_test_result(2, 18, 9, 9)
	_check("Passing the frontier unlocks exactly Lesson 3", profile.current_lesson == 3 and profile.highest_unlocked_lesson == 3)
	var locked := LessonProgressManager.record_test_result(4, 20, 10, 10)
	_check("Locked lesson tests are rejected", not locked["save_ok"] and profile.current_lesson == 3)
	_check("Review focus does not move the frontier", LessonProgressManager.get_focus_lesson({"lesson_number": 1}) == 1 and profile.current_lesson == 3)
	var early_failure := LessonProgressManager.record_test_result(3, 9, 5, 4, 12)
	_check("An incomplete test cannot pass", not early_failure["passed"] and profile.current_lesson == 3 and not LessonProgressManager.can_take_test(3))
	LessonProgressManager.record_practice_session()
	var loaded := SaveManager.load_profile(PROFILE_NAME)
	_check("Lesson unlocks survive save/load", loaded.current_lesson == 3 and loaded.highest_unlocked_lesson == 3 and LessonProgressManager.is_passed(1, loaded))
	profile.current_lesson = 45
	profile.highest_unlocked_lesson = 45
	var final := LessonProgressManager.record_test_result(45, 20, 10, 10)
	_check("Final lesson completes without Lesson 46", final["passed"] and final["newly_unlocked"] == 0 and profile.current_lesson == 45)
	_test_session_mix()
	_test_scene_composition()
	profile.current_lesson = 3
	profile.highest_unlocked_lesson = 3
	var profile_path := "user://profiles/%s/profile.tres" % PROFILE_NAME
	DirAccess.remove_absolute(profile_path)
	DirAccess.make_dir_recursive_absolute(profile_path)
	var unsaved := LessonProgressManager.record_test_result(3, 20, 10, 10)
	_check("Failed saves roll back unlock state", not unsaved["save_ok"] and profile.current_lesson == 3 and profile.highest_unlocked_lesson == 3 and not LessonProgressManager.is_passed(3))
	DirAccess.remove_absolute(profile_path)
	SRSEngine.cards = saved_cards
	GameController.current_profile = saved_profile
	GameController.session_data = {}
	SaveManager.delete_profile(PROFILE_NAME)
	print("Lesson progress tests: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_banks_valid() -> bool:
	for lesson in range(1, 46):
		var questions := VocabDatabase.get_lesson_tests(lesson)
		if questions.size() != 20:
			return false
		var vocabulary := 0
		var cloze := 0
		for question in questions:
			if question["kind"] == "vocabulary":
				vocabulary += 1
			elif question["kind"] == "cloze":
				cloze += 1
		if vocabulary != 10 or cloze != 10:
			return false
	return true


func _test_session_mix() -> void:
	var profile := GameController.current_profile
	profile.current_lesson = 2
	profile.highest_unlocked_lesson = 2
	SRSEngine.cards = []
	var lesson_one := VocabDatabase.get_words_by_lesson(1)
	var ids := PackedStringArray()
	for index in 5:
		ids.append(lesson_one[index].id)
	SRSEngine.add_new_cards(ids)
	var future := VocabDatabase.get_words_by_lesson(5)[0]
	SRSEngine.add_new_cards(PackedStringArray([future.id]))
	var selection := LessonSessionPlanner.build_vocabulary_session({"lesson_number": 2}, {}, 10, 10)
	var current := 0
	var review := 0
	var future_found := false
	for word in selection["words"]:
		if 2 in word.lesson_ids:
			current += 1
		elif word.first_lesson == 1:
			review += 1
		if word.id == future.id:
			future_found = true
	_check("Lesson 2 sessions target seven current items", current == 7)
	_check("Lesson 2 sessions include three earlier reviews", review == 3)
	_check("Locked future cards remain ineligible", not future_found)
	var lesson_one_selection := LessonSessionPlanner.build_vocabulary_session({"lesson_number": 1}, {}, 10, 0)
	_check("Lesson 1 has no forced review slots", lesson_one_selection["words"].size() == 5)


func _test_scene_composition() -> void:
	var profile := GameController.current_profile
	profile.current_lesson = 1
	profile.highest_unlocked_lesson = 1
	GameController.session_data = {"lesson_number": 1}
	var test = load("res://Scenes/Lessons/lesson_test.tscn").instantiate()
	add_child(test)
	_check("Lesson test scene builds 20 mixed questions", test._questions.size() == 20 and test._vocabulary_correct == 0 and test._cloze_correct == 0)
	test.free()


func _check(description: String, condition: bool) -> void:
	if condition:
		_passes += 1
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
