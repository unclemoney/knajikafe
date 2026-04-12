extends Node
## AudioManager (Autoload)
##
## Manages BGM and SFX playback with volume control and crossfading.
## Registered as an autoload singleton.

## BGM player for background music.
var _bgm_player: AudioStreamPlayer = null

## SFX player pool for overlapping sound effects.
var _sfx_players: Array[AudioStreamPlayer] = []

## Number of concurrent SFX channels.
const SFX_POOL_SIZE: int = 8

## Current BGM volume (0.0–1.0).
var bgm_volume: float = 0.8:
	set(value):
		bgm_volume = clampf(value, 0.0, 1.0)
		if _bgm_player:
			_bgm_player.volume_db = linear_to_db(bgm_volume)

## Current SFX volume (0.0–1.0).
var sfx_volume: float = 0.8


func _ready() -> void:
	_setup_bgm_player()
	_setup_sfx_pool()


## Plays background music, crossfading from any current track.
## stream: the AudioStream to play. If null, stops BGM.
## fade_duration: crossfade time in seconds.
func play_bgm(stream: AudioStream, fade_duration: float = 0.5) -> void:
	if stream == null:
		stop_bgm(fade_duration)
		return

	if _bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		await tween.finished

	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume)
	_bgm_player.play()


## Stops the current BGM with a fade-out.
func stop_bgm(fade_duration: float = 0.5) -> void:
	if not _bgm_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
	await tween.finished
	_bgm_player.stop()


## Plays a one-shot sound effect.
## stream: the AudioStream to play.
## pitch_variation: random pitch range (e.g., 0.1 = ±10%).
func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume)
			if pitch_variation > 0.0:
				player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			else:
				player.pitch_scale = 1.0
			player.play()
			return


## Applies volume settings from a player profile.
func apply_profile_settings(profile: PlayerProfile) -> void:
	bgm_volume = profile.settings.get("bgm_volume", 0.8)
	sfx_volume = profile.settings.get("sfx_volume", 0.8)


func _setup_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)


func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)
