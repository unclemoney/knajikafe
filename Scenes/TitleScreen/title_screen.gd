extends Control
## title_screen.gd
##
## Title screen with animated logo and start button.
## Flow: Start → Profile Select.

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var start_btn: Button = $VBox/StartBtn
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	_animate_intro()


## Transitions to the Profile Select screen.
func _on_start_pressed() -> void:
	start_btn.disabled = true
	GameController.change_scene("res://Scenes/ProfileSelect/profile_select.tscn")


## Plays the intro animation: fade in title, then subtitle, then button.
func _animate_intro() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	start_btn.modulate.a = 0.0
	version_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(start_btn, "modulate:a", 1.0, 0.4)
	tween.tween_property(version_label, "modulate:a", 0.6, 0.3)
