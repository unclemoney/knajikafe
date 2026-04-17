extends Control
## CatStateMachineTest
##
## Visual test scene to verify CafeCat physics, state machine transitions,
## speech bubbles, and sprite loading. Spawns a single cat on a floor
## with platforms. Shows current state and provides buttons to force states.

const CAFE_CAT_SCENE := preload("res://Scenes/CafeHub/Cats/cafe_cat.tscn")

## Furniture landing positions matching the test scene physics bodies.
const FURNITURE_TARGETS: Array[Vector2] = [
	Vector2(320.0, 196.0),  # Counter surface
	Vector2(90.0, 136.0),   # Shelf left surface
	Vector2(550.0, 136.0),  # Shelf right surface
]

@onready var state_label: Label = $UI/StateLabel
@onready var cat_world: Node2D = $CatWorld
@onready var restart_btn: Button = $UI/RestartBtn
@onready var jump_btn: Button = $UI/JumpBtn
@onready var state_buttons: GridContainer = $UI/StateButtons

var _test_cat: CafeCat = null


func _ready() -> void:
	restart_btn.pressed.connect(_restart)
	jump_btn.pressed.connect(_jump_on_furniture)
	_build_state_buttons()
	_spawn_cat()


func _process(_delta: float) -> void:
	if _test_cat and is_instance_valid(_test_cat):
		var state_name := CatStateMachine.get_state_name(_test_cat._state_machine.current_state)
		var phase_name := "NONE"
		if _test_cat._jump_phase == CafeCat.JumpPhase.LIFTOFF:
			phase_name = "LIFTOFF"
		elif _test_cat._jump_phase == CafeCat.JumpPhase.RISING:
			phase_name = "RISING"
		elif _test_cat._jump_phase == CafeCat.JumpPhase.FALLING:
			phase_name = "FALLING"
		elif _test_cat._jump_phase == CafeCat.JumpPhase.LANDING:
			phase_name = "LANDING"
		var play_name := "NONE"
		if _test_cat._play_phase == CafeCat.PlayPhase.START:
			play_name = "START"
		elif _test_cat._play_phase == CafeCat.PlayPhase.LOOP:
			play_name = "LOOP(%d)" % _test_cat._play_loops_remaining
		elif _test_cat._play_phase == CafeCat.PlayPhase.END:
			play_name = "END"
		state_label.text = "State: %s\nPos: (%d, %d)\nVel: (%d, %d)\nFloor: %s | Furn: %s\nJump: %s | Play: %s" % [
			state_name,
			int(_test_cat.position.x),
			int(_test_cat.position.y),
			int(_test_cat.velocity.x),
			int(_test_cat.velocity.y),
			str(_test_cat.is_on_floor()),
			str(_test_cat.on_furniture),
			phase_name,
			play_name,
		]


## _build_state_buttons()
##
## Creates one button per CatStateMachine.State to force-transition the cat.
func _build_state_buttons() -> void:
	for state_value in CatStateMachine.State.values():
		var btn := Button.new()
		btn.text = CatStateMachine.get_state_name(state_value)
		btn.custom_minimum_size = Vector2(70, 20)
		btn.add_theme_font_size_override("font_size", 7)
		btn.pressed.connect(_on_state_button_pressed.bind(state_value))
		state_buttons.add_child(btn)


## _on_state_button_pressed(state)
##
## Forces the test cat into the selected state.
func _on_state_button_pressed(state: int) -> void:
	if _test_cat and is_instance_valid(_test_cat):
		_test_cat._state_machine.force_state(state as CatStateMachine.State)


func _spawn_cat() -> void:
	# Load Mochi as the test cat
	var cat_data := load("res://Resources/Cats/mochi.tres") as CatCharacter
	_test_cat = CAFE_CAT_SCENE.instantiate()
	_test_cat.cat_data = cat_data
	_test_cat.position = Vector2(320, 270)
	_test_cat.jump_targets = FURNITURE_TARGETS
	cat_world.add_child(_test_cat)


func _restart() -> void:
	if _test_cat and is_instance_valid(_test_cat):
		_test_cat.queue_free()
	_spawn_cat()


## _jump_on_furniture()
##
## Forces the cat to walk toward a random furniture target and jump onto it.
func _jump_on_furniture() -> void:
	if _test_cat and is_instance_valid(_test_cat):
		_test_cat._state_machine.force_state(CatStateMachine.State.WALKING_TO_JUMP)
