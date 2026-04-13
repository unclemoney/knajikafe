extends Control
## tutorial.gd
##
## Interactive tutorial/onboarding flow for first-time players.
## Mochi the cat guides the player through the cafe and explains stations.
## Steps through a series of dialogue panels with continue buttons.

signal tutorial_completed

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var cat_label: Label = $Panel/VBox/CatLabel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var dialogue_label: Label = $Panel/VBox/DialogueLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var skip_btn: Button = $Panel/VBox/SkipBtn

## Tutorial steps: each has a cat expression, title, and dialogue text.
const STEPS: Array = [
	{
		"cat": "🐱",
		"title": "Welcome to KanjiKafe!",
		"text": "Nyaa~! I'm Mochi, and this is my cafe! I'll show you around. We help humans learn Japanese here!",
	},
	{
		"cat": "🐱 ☕",
		"title": "The Cafe Hub",
		"text": "This is the main cafe! You can see your level, XP, and streak at the top. Cats like me wander around!",
	},
	{
		"cat": "🐱 📝",
		"title": "Quiz Station",
		"text": "Tap 'Quiz' to start a multiple-choice quiz. You'll see a Japanese word and pick the right meaning!",
	},
	{
		"cat": "🐱 🃏",
		"title": "Flashcard Review",
		"text": "Flashcards let you study at your own pace. Flip the card, then rate how well you knew it!",
	},
	{
		"cat": "🐱 🔤",
		"title": "Typing Practice",
		"text": "In typing mode, you see the English meaning and type the hiragana reading. Use the on-screen keyboard or type directly!",
	},
	{
		"cat": "🐱 🧩",
		"title": "More Games!",
		"text": "Try Kanji Matching to pair kanji with meanings, Fill in the Blank for sentences, or Cafe Orders for timed challenges!",
	},
	{
		"cat": "🐱 ⭐",
		"title": "Spaced Repetition",
		"text": "Words you get right come back less often. Words you struggle with come back sooner. This helps you remember!",
	},
	{
		"cat": "🐱 🔥",
		"title": "Daily Streaks",
		"text": "Play every day to build a streak! Streaks give you bonus XP. Don't break the chain!",
	},
	{
		"cat": "🐱 🏆",
		"title": "Achievements & Cats",
		"text": "Earn achievements as you learn! Level up to unlock new cats and cafe decorations. Collect them all!",
	},
	{
		"cat": "🐱 ✨",
		"title": "Let's Get Started!",
		"text": "That's everything, nya~! Head to a station and try your first quiz. Good luck, and have fun learning!",
	},
]

var _current_step: int = 0


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	skip_btn.pressed.connect(_on_skip)
	_show_step(0)
	TweenFX.fade_in(backdrop, 0.4)
	TweenFX.pop_in(panel, 0.4)


## Displays the tutorial step at the given index.
func _show_step(index: int) -> void:
	_current_step = index
	var step: Dictionary = STEPS[index]
	cat_label.text = step["cat"]
	title_label.text = step["title"]
	dialogue_label.text = step["text"]

	if index == STEPS.size() - 1:
		continue_btn.text = "Start Playing!"
	else:
		continue_btn.text = "Next (%d/%d)" % [index + 1, STEPS.size()]

	TweenFX.pop_in(cat_label, 0.3)


func _on_continue() -> void:
	_current_step += 1
	if _current_step >= STEPS.size():
		_complete_tutorial()
	else:
		_show_step(_current_step)


func _on_skip() -> void:
	_complete_tutorial()


## Marks tutorial as completed and removes the overlay.
func _complete_tutorial() -> void:
	var profile := GameController.current_profile
	if profile:
		profile.has_completed_tutorial = true
		SaveManager.save_profile(profile)
	tutorial_completed.emit()
	await TweenFX.fade_out(self, 0.3).finished
	queue_free()
