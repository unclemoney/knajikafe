extends Node
class_name CatStateMachine
## CatStateMachine
##
## Finite state machine that drives cat AI behavior in the cafe hub.
## Manages state transitions with weighted random selection and per-state
## duration timers. Transition states (SITTING, LAYING_DOWN) play once
## then auto-advance to their idle variant. WALKING_TO_JUMP walks the cat
## toward a jump target before launching.

## Emitted when the FSM transitions to a new state.
signal state_changed(new_state: int)

## Emitted when a transition animation finishes one loop.
signal transition_finished(state: int)

## All possible cat behavior states.
enum State {
	STANDING,
	IDLE,
	WALKING,
	SITTING,          ## Transition: plays once, then -> SITTING_IDLE
	SITTING_IDLE,     ## Looping idle in sitting position
	LAYING_DOWN,      ## Transition: plays once, then -> LAYING_DOWN_IDLE
	LAYING_DOWN_IDLE, ## Looping idle in laying position
	WALKING_TO_JUMP,  ## Walks toward a jump target, then -> JUMPING
	JUMPING,
	PLAYING,
	EATING,
	SLEEPING,
}

## States that are one-shot transitions (play one loop, then auto-advance).
const TRANSITION_STATES: Dictionary = {
	State.SITTING: State.SITTING_IDLE,
	State.LAYING_DOWN: State.SLEEPING,
}

## The current active state.
var current_state: State = State.STANDING

## Time remaining in the current state before transitioning.
var _state_timer: float = 0.0

## Whether the current transition animation has finished its single loop.
var _transition_done: bool = false

## Minimum and maximum durations per state (in seconds).
var _state_durations: Dictionary = {
	State.STANDING: Vector2(1.0, 3.0),
	State.IDLE: Vector2(3.0, 10.0),
	State.WALKING: Vector2(2.0, 5.0),
	State.SITTING: Vector2(0.0, 0.0),        ## Timer unused — driven by animation loop
	State.SITTING_IDLE: Vector2(4.0, 10.0),
	State.LAYING_DOWN: Vector2(0.0, 0.0),    ## Timer unused — driven by animation loop
	State.LAYING_DOWN_IDLE: Vector2(5.0, 12.0),
	State.WALKING_TO_JUMP: Vector2(0.0, 0.0), ## Timer unused — driven by CafeCat arrival
	State.JUMPING: Vector2(0.5, 1.0),
	State.PLAYING: Vector2(3.0, 6.0),
	State.EATING: Vector2(4.0, 8.0),
	State.SLEEPING: Vector2(8.0, 15.0),
}

## Weighted transition table: current_state -> Array of [next_state, weight].
var _transitions: Dictionary = {
	State.STANDING: [
		[State.IDLE, 4],
		[State.WALKING, 3],
		[State.SITTING, 2],
		[State.LAYING_DOWN, 1],
		[State.PLAYING, 1],
	],
	State.IDLE: [
		[State.WALKING, 4],
		[State.STANDING, 2],
		[State.SITTING, 3],
		[State.LAYING_DOWN, 2],
		[State.EATING, 2],
		[State.SLEEPING, 1],
		[State.PLAYING, 1],
		[State.WALKING_TO_JUMP, 1],
	],
	State.WALKING: [
		[State.STANDING, 2],
		[State.IDLE, 3],
		[State.SITTING, 2],
		[State.WALKING_TO_JUMP, 2],
		[State.PLAYING, 1],
	],
	State.SITTING_IDLE: [
		[State.IDLE, 3],
		[State.STANDING, 2],
		[State.WALKING, 3],
		[State.LAYING_DOWN, 1],
		[State.SLEEPING, 2],
	],
	State.LAYING_DOWN_IDLE: [
		[State.IDLE, 3],
		[State.STANDING, 2],
		[State.WALKING, 2],
		[State.SLEEPING, 3],
	],
	State.JUMPING: [
		[State.WALKING, 3],
		[State.IDLE, 3],
		[State.STANDING, 2],
		[State.SITTING, 1],
	],
	State.PLAYING: [
		[State.IDLE, 3],
		[State.WALKING, 3],
		[State.SITTING, 2],
		[State.STANDING, 1],
	],
	State.EATING: [
		[State.IDLE, 3],
		[State.SITTING, 3],
		[State.WALKING, 2],
		[State.SLEEPING, 2],
	],
	State.SLEEPING: [
		[State.IDLE, 5],
		[State.STANDING, 3],
		[State.SITTING, 2],
	],
}


## _ready()
##
## Starts the FSM in the STANDING state.
func _ready() -> void:
	_enter_state(State.STANDING)


## _process(delta)
##
## Counts down the state timer and triggers a transition when it expires.
## JUMPING and WALKING_TO_JUMP are handled by physics, not timer.
## Transition states wait for their animation loop to complete.
func _process(delta: float) -> void:
	if current_state == State.JUMPING:
		return
	if current_state == State.WALKING_TO_JUMP:
		return
	if TRANSITION_STATES.has(current_state):
		if _transition_done:
			var next_idle: State = TRANSITION_STATES[current_state]
			_exit_state(current_state)
			_enter_state(next_idle)
		return
	_state_timer -= delta
	if _state_timer <= 0.0:
		_transition_to_next()


## notify_transition_animation_done()
##
## Called by CafeCat when an AnimatedSprite2D animation_finished signal fires
## for a transition state. Marks the transition as complete so _process
## advances to the idle variant on the next frame.
func notify_transition_animation_done() -> void:
	if TRANSITION_STATES.has(current_state):
		_transition_done = true
		transition_finished.emit(current_state)


## force_state(state)
##
## Forces an immediate transition to the given state. Used externally
## (e.g., when the cat lands after a jump).
func force_state(state: State) -> void:
	_exit_state(current_state)
	_enter_state(state)


## _transition_to_next()
##
## Picks the next state from the weighted transition table and enters it.
func _transition_to_next() -> void:
	var next_state := _pick_weighted_state(current_state)
	_exit_state(current_state)
	_enter_state(next_state)


## _enter_state(state)
##
## Sets the new state, picks a random duration, and emits state_changed.
func _enter_state(state: State) -> void:
	current_state = state
	_transition_done = false
	var dur_range: Vector2 = _state_durations[state]
	_state_timer = randf_range(dur_range.x, dur_range.y)
	state_changed.emit(current_state)


## _exit_state(_state)
##
## Called when leaving a state. Currently a no-op placeholder for future needs.
func _exit_state(_state: State) -> void:
	pass


## _pick_weighted_state(from_state) -> State
##
## Selects a random next state from the transition table using weighted random.
func _pick_weighted_state(from_state: State) -> State:
	var options: Array = _transitions.get(from_state, [])
	if options.is_empty():
		return State.IDLE
	var total_weight: int = 0
	for option in options:
		total_weight += option[1]
	var roll: int = randi_range(1, total_weight)
	var cumulative: int = 0
	for option in options:
		cumulative += option[1]
		if roll <= cumulative:
			return option[0] as State
	return State.STANDING


## get_state_name(state) -> String
##
## Returns a human-readable name for the given state enum value.
## This also doubles as the animation name used by CatSpriteLoader.
static func get_state_name(state: State) -> String:
	match state:
		State.STANDING:
			return "standing"
		State.IDLE:
			return "idle"
		State.WALKING:
			return "walking"
		State.SITTING:
			return "sitting"
		State.SITTING_IDLE:
			return "sitting_idle"
		State.LAYING_DOWN:
			return "laying_down"
		State.LAYING_DOWN_IDLE:
			return "laying_down_idle"
		State.WALKING_TO_JUMP:
			return "walking"
		State.JUMPING:
			return "jumping"
		State.PLAYING:
			return "playing"
		State.EATING:
			return "eating"
		State.SLEEPING:
			return "sleeping"
	return "standing"
