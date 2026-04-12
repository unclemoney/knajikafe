extends Control
## settings.gd
##
## Settings screen for display preferences, audio volume, and session config.
## Reads from and writes to the current profile's settings dictionary.

@onready var kanji_toggle: CheckButton = $Panel/VBox/DisplaySection/KanjiToggle
@onready var furigana_toggle: CheckButton = $Panel/VBox/DisplaySection/FuriganaToggle
@onready var romaji_toggle: CheckButton = $Panel/VBox/DisplaySection/RomajiToggle
@onready var english_toggle: CheckButton = $Panel/VBox/DisplaySection/EnglishToggle

@onready var bgm_slider: HSlider = $Panel/VBox/AudioSection/BGMRow/BGMSlider
@onready var bgm_value_label: Label = $Panel/VBox/AudioSection/BGMRow/BGMValue
@onready var sfx_slider: HSlider = $Panel/VBox/AudioSection/SFXRow/SFXSlider
@onready var sfx_value_label: Label = $Panel/VBox/AudioSection/SFXRow/SFXValue

@onready var words_spin: SpinBox = $Panel/VBox/SessionSection/WordsRow/WordsSpinBox

@onready var preview_display: VocabDisplay = $Panel/VBox/PreviewSection/VocabDisplay

@onready var save_btn: Button = $Panel/VBox/ButtonRow/SaveBtn
@onready var back_btn: Button = $Panel/VBox/ButtonRow/BackBtn
@onready var status_label: Label = $Panel/VBox/StatusLabel

## Preview word for testing display settings.
var _preview_word: VocabWord = null


func _ready() -> void:
	save_btn.pressed.connect(_on_save_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	kanji_toggle.toggled.connect(_on_display_toggled)
	furigana_toggle.toggled.connect(_on_display_toggled)
	romaji_toggle.toggled.connect(_on_display_toggled)
	english_toggle.toggled.connect(_on_display_toggled)

	_load_settings()
	_setup_preview()


## Loads current profile settings into the UI.
func _load_settings() -> void:
	var profile := GameController.current_profile
	if profile == null:
		return

	var s := profile.settings
	kanji_toggle.button_pressed = s.get("show_kanji", true)
	furigana_toggle.button_pressed = s.get("show_furigana", true)
	romaji_toggle.button_pressed = s.get("show_romaji", false)
	english_toggle.button_pressed = s.get("show_english", true)

	bgm_slider.value = s.get("bgm_volume", 0.8) * 100.0
	sfx_slider.value = s.get("sfx_volume", 0.8) * 100.0
	_update_volume_labels()

	words_spin.value = s.get("words_per_session", 10)

	status_label.text = ""


## Sets up a preview word to demonstrate display settings.
func _setup_preview() -> void:
	var words := VocabDatabase.get_all_words()
	if words.size() > 0:
		# Pick a word that has kanji for the best preview
		for w in words:
			if w.kanji != "":
				_preview_word = w
				break
		if _preview_word == null:
			_preview_word = words[0]
		_update_preview()


## Updates the preview display with current toggle states.
func _update_preview() -> void:
	if _preview_word == null:
		return
	var overrides := {
		"show_kanji": kanji_toggle.button_pressed,
		"show_furigana": furigana_toggle.button_pressed,
		"show_romaji": romaji_toggle.button_pressed,
		"show_english": english_toggle.button_pressed,
	}
	preview_display.show_word(_preview_word, overrides)


## Saves the current settings to the profile.
func _on_save_pressed() -> void:
	var profile := GameController.current_profile
	if profile == null:
		status_label.text = "No profile loaded!"
		return

	profile.settings["show_kanji"] = kanji_toggle.button_pressed
	profile.settings["show_furigana"] = furigana_toggle.button_pressed
	profile.settings["show_romaji"] = romaji_toggle.button_pressed
	profile.settings["show_english"] = english_toggle.button_pressed
	profile.settings["bgm_volume"] = bgm_slider.value / 100.0
	profile.settings["sfx_volume"] = sfx_slider.value / 100.0
	profile.settings["words_per_session"] = int(words_spin.value)

	AudioManager.apply_profile_settings(profile)
	SaveManager.save_profile(profile)
	status_label.text = "Settings saved!"


## Returns to the Cafe Hub.
func _on_back_pressed() -> void:
	back_btn.disabled = true
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")


## Called when BGM slider changes.
func _on_bgm_changed(_value: float) -> void:
	_update_volume_labels()
	AudioManager.bgm_volume = bgm_slider.value / 100.0


## Called when SFX slider changes.
func _on_sfx_changed(_value: float) -> void:
	_update_volume_labels()
	AudioManager.sfx_volume = sfx_slider.value / 100.0


## Updates volume percentage labels.
func _update_volume_labels() -> void:
	bgm_value_label.text = "%d%%" % int(bgm_slider.value)
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)


## Called when any display toggle changes — updates preview.
func _on_display_toggled(_pressed: bool) -> void:
	_update_preview()
