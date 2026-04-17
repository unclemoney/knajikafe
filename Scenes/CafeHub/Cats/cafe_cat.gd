extends CharacterBody2D
class_name CafeCat
## CafeCat
##
## An animated cat character that roams the cafe hub using CharacterBody2D
## physics. Driven by a CatStateMachine for behavior, with animated sprites
## loaded at runtime from sprite sheets and a floating speech bubble on click.

## Emitted when this cat is clicked by the player.
signal cat_clicked(cat: CafeCat)

## The CatCharacter resource that defines this cat's identity and dialogue.
@export var cat_data: CatCharacter

## Gravity applied each physics frame (pixels/s²).
const GRAVITY: float = 600.0

## Horizontal walk speed in pixels per second.
const WALK_SPEED: float = 40.0

## Minimum upward velocity for small hops (negative = upward).
const MIN_JUMP_VELOCITY: float = -150.0

## Extra multiplier on calculated jump velocity for arc clearance.
const JUMP_VELOCITY_MARGIN: float = 1.3

## Horizontal boost during jump-to-furniture (pixels/s).
const JUMP_FORWARD_SPEED: float = 60.0

## How close the cat needs to be (x) to the jump point before launching.
const JUMP_ARRIVE_THRESHOLD: float = 8.0

## Pixels above landing surface at which to start the landing animation.
const NEAR_LANDING_PIXELS: float = 24.0

## Floor Y position that the cat returns to when jumping down.
const FLOOR_Y: float = 280.0

## Collision layer bit for platforms (counter, shelves). Layer 2 = bit index 2.
const PLATFORM_LAYER_BIT: int = 2

## Boundaries for horizontal movement (kept slightly inset from screen edges).
const LEFT_BOUND: float = 16.0
const RIGHT_BOUND: float = 624.0

## Jump animation phases.
enum JumpPhase {
	NONE,     ## Not jumping.
	LIFTOFF,  ## Playing liftoff frames (0-2).
	RISING,   ## Holding peak frame while velocity.y < 0.
	FALLING,  ## Holding fall frame while velocity.y >= 0.
	LANDING,  ## Playing landing frames near the surface.
}

## Playing animation phases.
enum PlayPhase {
	NONE,     ## Not in a playing sequence.
	START,    ## Playing stand-up frames.
	LOOP,     ## Playing action frames, repeated N times.
	END,      ## Playing sit-down frames.
}

## Direction: -1 = left, 1 = right.
var _direction: float = 1.0

## Whether the cat is currently in mid-air.
var _is_jumping: bool = false

## Current jump animation phase.
var _jump_phase: JumpPhase = JumpPhase.NONE

## Whether a jump target was set by WALKING_TO_JUMP.
var _has_jump_target: bool = false

## Whether the current jump is going down (off furniture).
var _jumping_down: bool = false

## Whether the cat is currently standing on furniture above floor level.
var on_furniture: bool = false

## Current playing animation phase.
var _play_phase: PlayPhase = PlayPhase.NONE

## Number of play_loop repetitions remaining.
var _play_loops_remaining: int = 0

## Target position that the cat walks toward before jumping.
var _jump_target: Vector2 = Vector2.ZERO

## List of furniture landing positions (set by the owning scene).
var jump_targets: Array[Vector2] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _state_machine: CatStateMachine = $CatStateMachine
@onready var _click_area: Area2D = $ClickArea
@onready var _speech_bubble: PanelContainer = $SpeechBubble
@onready var _speech_label: Label = $SpeechBubble/MarginContainer/SpeechLabel


## _ready()
##
## Loads sprite frames, connects signals, and hides the speech bubble.
func _ready() -> void:
	if cat_data:
		var frames := CatSpriteLoader.build_sprite_frames(cat_data.cat_number)
		_sprite.sprite_frames = frames
		_sprite.play("standing")
	_speech_bubble.visible = false
	_speech_bubble.modulate.a = 0.0
	_state_machine.state_changed.connect(_on_state_changed)
	_click_area.input_event.connect(_on_click_area_input_event)
	_sprite.animation_finished.connect(_on_animation_finished)

	# Random initial direction
	if randf() > 0.5:
		_direction = -1.0
		_sprite.flip_h = true


## _physics_process(delta)
##
## Applies gravity, handles per-state movement, and calls move_and_slide().
func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if _is_jumping:
			_is_jumping = false
			_jump_phase = JumpPhase.NONE
			velocity.x = 0.0
			if _jumping_down:
				set_collision_mask_value(PLATFORM_LAYER_BIT, true)
				_jumping_down = false
				on_furniture = false
			else:
				on_furniture = global_position.y < FLOOR_Y - 20.0
			_state_machine.on_furniture = on_furniture
			_state_machine.force_state(CatStateMachine.State.IDLE)

	# State-specific horizontal movement
	match _state_machine.current_state:
		CatStateMachine.State.WALKING:
			if global_position.x <= LEFT_BOUND and _direction < 0:
				_direction = 1.0
			elif global_position.x >= RIGHT_BOUND and _direction > 0:
				_direction = -1.0
			velocity.x = _direction * WALK_SPEED
			_sprite.flip_h = _direction < 0
		CatStateMachine.State.WALKING_TO_JUMP:
			_walk_toward_jump_target()
		CatStateMachine.State.JUMPING:
			if _jumping_down:
				velocity.x = _direction * JUMP_FORWARD_SPEED * 0.5
			else:
				velocity.x = _direction * JUMP_FORWARD_SPEED
			_update_jump_phase()
		_:
			velocity.x = 0.0

	move_and_slide()

	# Clamp to screen bounds
	if global_position.x < LEFT_BOUND:
		global_position.x = LEFT_BOUND
		_direction = 1.0
		_sprite.flip_h = false
		velocity.x = 0.0
	elif global_position.x > RIGHT_BOUND:
		global_position.x = RIGHT_BOUND
		_direction = -1.0
		_sprite.flip_h = true
		velocity.x = 0.0


## _walk_toward_jump_target()
##
## Moves the cat toward the jump launch point. When close enough, starts the jump.
func _walk_toward_jump_target() -> void:
	var launch_x := _jump_launch_x()
	var diff_x := launch_x - global_position.x
	if absf(diff_x) <= JUMP_ARRIVE_THRESHOLD:
		velocity.x = 0.0
		_state_machine.force_state(CatStateMachine.State.JUMPING)
	else:
		_direction = signf(diff_x)
		_sprite.flip_h = _direction < 0
		velocity.x = _direction * WALK_SPEED


## _update_jump_phase()
##
## Checks velocity and position to advance through jump animation phases:
## LIFTOFF -> RISING (via animation_finished) -> FALLING -> LANDING.
func _update_jump_phase() -> void:
	if _jump_phase == JumpPhase.RISING:
		if velocity.y >= 0:
			_jump_phase = JumpPhase.FALLING
			_sprite.play("jump_fall")
	elif _jump_phase == JumpPhase.FALLING:
		var landing_y := _jump_target.y if not _jumping_down else FLOOR_Y
		if global_position.y >= landing_y - NEAR_LANDING_PIXELS:
			_jump_phase = JumpPhase.LANDING
			_sprite.play("jump_land")


## _calculate_jump_velocity() -> float
##
## Computes upward velocity needed to reach _jump_target.y from the current
## position, with a margin to create a nice arc over the platform.
## For jump-down, gives a small hop upward.
func _calculate_jump_velocity() -> float:
	if _jumping_down:
		return -80.0
	var height := global_position.y - _jump_target.y
	if height <= 0:
		return MIN_JUMP_VELOCITY
	var needed := sqrt(2.0 * GRAVITY * height) * JUMP_VELOCITY_MARGIN
	if needed < -MIN_JUMP_VELOCITY:
		needed = -MIN_JUMP_VELOCITY
	return -needed


## _jump_launch_x() -> float
##
## Returns the x position the cat should walk to before jumping.
## For jumping up, positions the cat at the near edge of the furniture.
## For jumping down, uses the cat's current x (jump off wherever you are).
func _jump_launch_x() -> float:
	if _jumping_down:
		return global_position.x
	# Walk to the near edge of the target rather than the center.
	# If cat is to the left of target, approach from the left edge (target - 50).
	# If cat is to the right, approach from the right edge (target + 50).
	var edge_offset := 50.0
	if global_position.x < _jump_target.x:
		return _jump_target.x - edge_offset
	else:
		return _jump_target.x + edge_offset


## _pick_jump_target() -> Vector2
##
## Selects a random landing position from the available furniture targets.
## If the cat is already on furniture, jumps down to the floor instead.
## Falls back to a small hop in place if no targets are available.
func _pick_jump_target() -> Vector2:
	if on_furniture:
		_jumping_down = true
		# Drift slightly toward center when jumping down
		var nudge := 30.0 if global_position.x < 320.0 else -30.0
		return Vector2(global_position.x + nudge, FLOOR_Y)
	_jumping_down = false
	if jump_targets.is_empty():
		return global_position + Vector2(0, -30)
	return jump_targets[randi() % jump_targets.size()]


## _is_on_furniture() -> bool
##
## Returns true if the cat is currently standing on a platform above the floor.
func _is_on_furniture() -> bool:
	return is_on_floor() and global_position.y < FLOOR_Y - 20.0


## _on_state_changed(new_state)
##
## Responds to state machine transitions by playing the matching animation
## and applying state-specific setup (direction change, jump velocity, etc.).
## JUMPING uses phase-based animation so its auto-play is skipped here.
func _on_state_changed(new_state: int) -> void:
	if new_state != CatStateMachine.State.JUMPING and new_state != CatStateMachine.State.PLAYING:
		var anim_name := CatStateMachine.get_state_name(new_state)
		if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
			_sprite.play(anim_name)
		else:
			_sprite.play("standing")

	match new_state:
		CatStateMachine.State.WALKING:
			# Pick a new random direction sometimes
			if randf() > 0.5:
				_direction *= -1.0
				_sprite.flip_h = _direction < 0
		CatStateMachine.State.WALKING_TO_JUMP:
			_jump_target = _pick_jump_target()
			_has_jump_target = true
		CatStateMachine.State.JUMPING:
			if is_on_floor():
				if not _has_jump_target:
					_jump_target = global_position
				_direction = signf(_jump_target.x - global_position.x) if absf(_jump_target.x - global_position.x) > 4.0 else _direction
				_sprite.flip_h = _direction < 0
				if _jumping_down:
					set_collision_mask_value(PLATFORM_LAYER_BIT, false)
				velocity.y = _calculate_jump_velocity()
				_is_jumping = true
				_jump_phase = JumpPhase.LIFTOFF
				_has_jump_target = false
				_sprite.play("jump_liftoff")
		CatStateMachine.State.SLEEPING, CatStateMachine.State.SITTING, \
		CatStateMachine.State.SITTING_IDLE, CatStateMachine.State.LAYING_DOWN, \
		CatStateMachine.State.LAYING_DOWN_IDLE, CatStateMachine.State.EATING, \
		CatStateMachine.State.GETTING_UP:
			velocity.x = 0.0
		CatStateMachine.State.PLAYING:
			velocity.x = 0.0
			_play_phase = PlayPhase.START
			_play_loops_remaining = randi_range(2, 7)
			_sprite.play("play_start")


## _on_animation_finished()
##
## Handles one-shot animations. For jump sub-animations, advances to the
## next jump phase. For transition states, notifies the state machine.
func _on_animation_finished() -> void:
	var current_anim := _sprite.animation
	# Jump phase handling
	if current_anim == &"jump_liftoff":
		_jump_phase = JumpPhase.RISING
		_sprite.play("jump_rise")
		return
	if current_anim == &"jump_land":
		return
	# Playing phase handling
	if current_anim == &"play_start":
		_play_phase = PlayPhase.LOOP
		_play_loops_remaining -= 1
		_sprite.play("play_loop")
		return
	if current_anim == &"play_loop":
		if _play_loops_remaining > 0:
			_play_loops_remaining -= 1
			_sprite.play("play_loop")
		else:
			_play_phase = PlayPhase.END
			_sprite.play("play_end")
		return
	if current_anim == &"play_end":
		_play_phase = PlayPhase.NONE
		_state_machine.force_state(CatStateMachine.State.IDLE)
		return
	_state_machine.notify_transition_animation_done()


## _on_click_area_input_event(_viewport, event, _shape_idx)
##
## Detects mouse clicks on the cat and shows a speech bubble.
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		print("Cat clicked: %s" % cat_data.cat_name)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_speech_bubble()
			cat_clicked.emit(self)


## _show_speech_bubble()
##
## Picks a random dialogue line from the cat's data and shows it in a
## floating bubble above the cat. Fades in, holds for 3 seconds, fades out.
func _show_speech_bubble() -> void:
	if not cat_data or cat_data.dialogue_lines.size() == 0:
		return

	var line := cat_data.dialogue_lines[randi() % cat_data.dialogue_lines.size()]
	_speech_label.text = line
	_speech_bubble.visible = true

	# Kill any existing tween on the bubble
	var tween := create_tween()
	tween.tween_property(_speech_bubble, "modulate:a", 1.0, 0.2)
	tween.tween_interval(3.0)
	tween.tween_property(_speech_bubble, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: _speech_bubble.visible = false)
