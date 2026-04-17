extends RefCounted
class_name CatSpriteLoader
## CatSpriteLoader
##
## Utility class that builds a SpriteFrames resource at runtime from
## individual horizontal sprite-strip PNG files for a given cat number.
## File convention: res://Art/Cats/CAT_{N}_{State}.png
## Frame size: 64x64. Frame count auto-detected from sheet width.

## Base path for cat sprite sheets.
const SPRITE_BASE_PATH := "res://Art/Cats/"

## Frame width and height in pixels.
const FRAME_SIZE := 64

## Map of state names to their animation FPS.
const ANIM_FPS: Dictionary = {
	"standing": 4.0,
	"idle": 4.0,
	"walking": 8.0,
	"sitting": 6.0,
	"sitting_idle": 3.0,
	"laying_down": 6.0,
	"laying_down_idle": 2.0,
	"playing": 6.0,
	"eating": 4.0,
	"sleeping": 2.0,
}

## All animation state names that the loader will attempt to find.
## Note: "jumping" and "playing" are excluded — they are split into sub-animations.
const STATE_NAMES: PackedStringArray = [
	"standing", "idle", "walking", "sitting", "sitting_idle",
	"laying_down", "laying_down_idle",
	"eating", "sleeping",
]

## Sprite file name suffixes matching the state names.
## Convention: CAT_1_Stand.png, CAT_1_Idle.png, CAT_1_Walking.png, etc.
const STATE_FILE_SUFFIXES: Dictionary = {
	"standing": "Stand",
	"idle": "Idle",
	"walking": "Walking",
	"sitting": "Sitting",
	"sitting_idle": "SittingIdle",
	"laying_down": "LayingDown",
	"laying_down_idle": "LayingDownIdle",
	"jumping": "Jumping",
	"playing": "Playing",
	"eating": "Eating",
	"sleeping": "Sleeping",
}

## Transition animations that should NOT loop — they play once.
const NO_LOOP_STATES: PackedStringArray = [
	"sitting", "laying_down",
]

## Jump sub-animation definitions built from the Jumping sprite sheet.
## Each entry: {start_frame, end_frame, loop, fps}.
const JUMP_ANIMATIONS: Dictionary = {
	"jump_liftoff": {"start": 0, "end": 2, "loop": false, "fps": 8.0},
	"jump_rise": {"start": 2, "end": 2, "loop": true, "fps": 1.0},
	"jump_fall": {"start": 3, "end": 3, "loop": true, "fps": 1.0},
	"jump_land": {"start": 4, "end": 7, "loop": false, "fps": 10.0},
}

## Playing sub-animation definitions built from the Playing sprite sheet.
## Frames 0-2: stand up, 3-6: play action (repeated N times), 7-9: sit back down.
const PLAY_ANIMATIONS: Dictionary = {
	"play_start": {"start": 0, "end": 2, "loop": false, "fps": 6.0},
	"play_loop": {"start": 3, "end": 6, "loop": false, "fps": 6.0},
	"play_end": {"start": 7, "end": 9, "loop": false, "fps": 6.0},
}


## build_sprite_frames(cat_number) -> SpriteFrames
##
## Loads all available sprite sheets for the given cat number and builds
## a SpriteFrames resource. Missing sheets fall back to "standing".
## If even "standing" is missing, creates a placeholder 1-frame animation.
static func build_sprite_frames(cat_number: int) -> SpriteFrames:
	var frames := SpriteFrames.new()

	# Remove the default animation that SpriteFrames creates automatically
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# First load the standing sheet as the fallback
	var fallback_texture: Texture2D = _load_sheet(cat_number, "standing")

	for state_name in STATE_NAMES:
		frames.add_animation(state_name)
		frames.set_animation_speed(state_name, ANIM_FPS.get(state_name, 4.0))
		var should_loop := not NO_LOOP_STATES.has(state_name)
		frames.set_animation_loop(state_name, should_loop)

		var texture: Texture2D = _load_sheet(cat_number, state_name)
		if texture == null:
			if fallback_texture != null:
				push_warning("Missing sprite: CAT_%d_%s.png — using standing fallback" % [cat_number, STATE_FILE_SUFFIXES[state_name]])
				texture = fallback_texture
			else:
				push_warning("Missing sprite: CAT_%d_%s.png — no fallback available" % [cat_number, STATE_FILE_SUFFIXES[state_name]])
				continue

		var frame_count: int = int(texture.get_width()) / FRAME_SIZE
		if frame_count < 1:
			frame_count = 1

		for i in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(state_name, atlas)

	# Add jump sub-animations from the Jumping sprite sheet
	_add_jump_animations(frames, cat_number, fallback_texture)

	# Add play sub-animations from the Playing sprite sheet
	_add_play_animations(frames, cat_number, fallback_texture)

	# Add getting_up animation (laying_down in reverse)
	_add_getting_up_animation(frames, cat_number)

	return frames


## _add_jump_animations(frames, cat_number, fallback_texture)
##
## Loads the Jumping sprite sheet and creates four sub-animations
## (liftoff, rise-hold, fall-hold, landing) for phased jump playback.
static func _add_jump_animations(frames: SpriteFrames, cat_number: int, fallback_texture: Texture2D) -> void:
	var texture := _load_sheet(cat_number, "jumping")
	if texture == null:
		texture = fallback_texture
	if texture == null:
		return
	for anim_name in JUMP_ANIMATIONS:
		var config: Dictionary = JUMP_ANIMATIONS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, config["fps"])
		frames.set_animation_loop(anim_name, config["loop"])
		for i in range(config["start"], config["end"] + 1):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)


## _add_play_animations(frames, cat_number, fallback_texture)
##
## Loads the Playing sprite sheet and creates three sub-animations
## (start, loop, end) for phased play playback.
static func _add_play_animations(frames: SpriteFrames, cat_number: int, fallback_texture: Texture2D) -> void:
	var texture := _load_sheet(cat_number, "playing")
	if texture == null:
		texture = fallback_texture
	if texture == null:
		return
	for anim_name in PLAY_ANIMATIONS:
		var config: Dictionary = PLAY_ANIMATIONS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, config["fps"])
		frames.set_animation_loop(anim_name, config["loop"])
		for i in range(config["start"], config["end"] + 1):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)


## _add_getting_up_animation(frames, cat_number)
##
## Loads the LayingDown sprite sheet and adds frames in reverse order
## to create a "getting up" animation for waking from sleep.
static func _add_getting_up_animation(frames: SpriteFrames, cat_number: int) -> void:
	var texture := _load_sheet(cat_number, "laying_down")
	if texture == null:
		return
	var frame_count := int(texture.get_width()) / FRAME_SIZE
	frames.add_animation("getting_up")
	frames.set_animation_speed("getting_up", 6.0)
	frames.set_animation_loop("getting_up", false)
	for i in range(frame_count - 1, -1, -1):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame("getting_up", atlas)


## _load_sheet(cat_number, state_name) -> Texture2D
##
## Attempts to load the sprite sheet PNG for the given cat and state.
## Returns null if the file doesn't exist.
static func _load_sheet(cat_number: int, state_name: String) -> Texture2D:
	var suffix: String = STATE_FILE_SUFFIXES.get(state_name, "Stand")
	var path := "%sCAT_%d_%s.png" % [SPRITE_BASE_PATH, cat_number, suffix]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
