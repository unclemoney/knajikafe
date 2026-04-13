extends Control
## results_screen.gd
##
## Post-quiz results screen showing accuracy, XP earned, and level status.
## Reads data from GameController.session_data.

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var words_label: Label = $Panel/VBox/StatsBox/WordsLabel
@onready var accuracy_label: Label = $Panel/VBox/StatsBox/AccuracyLabel
@onready var xp_label: Label = $Panel/VBox/StatsBox/XPLabel
@onready var streak_label: Label = $Panel/VBox/StatsBox/StreakLabel
@onready var level_label: Label = $Panel/VBox/StatsBox/LevelLabel
@onready var level_up_label: Label = $Panel/VBox/LevelUpLabel
@onready var return_btn: Button = $Panel/VBox/ReturnBtn


func _ready() -> void:
	return_btn.pressed.connect(_on_return_pressed)
	AudioManager.play_results_bgm()
	_display_results()


## Populates the results display from session data.
func _display_results() -> void:
	var data := GameController.session_data

	var words_reviewed: int = data.get("words_reviewed", 0)
	var correct_count: int = data.get("correct_count", 0)
	var xp_earned: int = data.get("xp_earned", 0)
	var base_xp: int = data.get("base_xp", xp_earned)
	var streak_mult: float = data.get("streak_multiplier", 1.0)
	var streak_days: int = data.get("streak_days", 0)
	var leveled_up: bool = data.get("leveled_up", false)
	var new_level: int = data.get("new_level", 1)

	var accuracy := 0.0
	if words_reviewed > 0:
		accuracy = float(correct_count) / float(words_reviewed) * 100.0

	words_label.text = "Words Reviewed: %d" % words_reviewed
	accuracy_label.text = "Correct: %d / %d  (%d%%)" % [correct_count, words_reviewed, int(accuracy)]

	if streak_mult > 1.0:
		xp_label.text = "XP Earned: +%d  (base %d × %.1f streak)" % [xp_earned, base_xp, streak_mult]
	else:
		xp_label.text = "XP Earned: +%d" % xp_earned

	if streak_days > 1:
		streak_label.text = "🔥 %d day streak!" % streak_days
		streak_label.visible = true
	elif streak_days == 1:
		streak_label.text = "🔥 Streak started! Come back tomorrow!"
		streak_label.visible = true
	else:
		streak_label.visible = false

	var profile := GameController.current_profile
	if profile:
		level_label.text = "Level: %d  |  Total XP: %d" % [profile.level, profile.xp]
	else:
		level_label.text = ""

	# Set title based on performance
	if accuracy >= 90.0:
		title_label.text = "Excellent! 🌟"
		TweenFX.tada(title_label, 0.6)
	elif accuracy >= 70.0:
		title_label.text = "Good job! ✨"
		TweenFX.pop_in(title_label, 0.4)
	elif accuracy >= 50.0:
		title_label.text = "Keep practicing! 📖"
		TweenFX.fade_in(title_label, 0.5)
	else:
		title_label.text = "Don't give up! 💪"
		TweenFX.fade_in(title_label, 0.5)

	# Animate stats with staggered pop-in
	var stat_nodes: Array[Label] = [words_label, accuracy_label, xp_label, level_label]
	for i in stat_nodes.size():
		var node: Label = stat_nodes[i]
		node.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(0.15 * i + 0.3)
		tween.tween_property(node, "modulate:a", 1.0, 0.3)

	if leveled_up:
		level_up_label.text = "⭐ Level Up! You are now Level %d! ⭐" % new_level
		level_up_label.visible = true
		TweenFX.upgrade(level_up_label, 0.8)
	else:
		level_up_label.visible = false


## Returns to the Cafe Hub.
func _on_return_pressed() -> void:
	return_btn.disabled = true
	GameController.session_data = {}
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")
