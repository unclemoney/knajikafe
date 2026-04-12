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

## Placeholder procedural SFX (generated at startup).
var _sfx_correct: AudioStreamWAV = null
var _sfx_wrong: AudioStreamWAV = null
var _sfx_click: AudioStreamWAV = null
var _sfx_level_up: AudioStreamWAV = null


func _ready() -> void:
	_setup_bgm_player()
	_setup_sfx_pool()
	_generate_placeholder_sfx()


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


## Plays the correct-answer SFX.
func play_correct() -> void:
	if _sfx_correct:
		play_sfx(_sfx_correct)


## Plays the wrong-answer SFX.
func play_wrong() -> void:
	if _sfx_wrong:
		play_sfx(_sfx_wrong)


## Plays the UI click SFX.
func play_click() -> void:
	if _sfx_click:
		play_sfx(_sfx_click)


## Plays the level-up SFX.
func play_level_up() -> void:
	if _sfx_level_up:
		play_sfx(_sfx_level_up)


## Generates simple procedural placeholder sounds.
func _generate_placeholder_sfx() -> void:
	_sfx_correct = _generate_tone(660.0, 0.15, 0.6)
	_sfx_wrong = _generate_tone(220.0, 0.25, 0.5)
	_sfx_click = _generate_tone(880.0, 0.05, 0.3)
	_sfx_level_up = _generate_rising_tone(440.0, 880.0, 0.4, 0.6)


## Generates a simple sine wave tone as an AudioStreamWAV.
func _generate_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / float(sample_rate)
		var envelope := 1.0 - (float(i) / float(num_samples))
		var sample_val := sin(t * freq * TAU) * volume * envelope
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generates a rising pitch tone (for level-up jingle).
func _generate_rising_tone(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	var phase := 0.0
	for i in num_samples:
		var t := float(i) / float(num_samples)
		var freq := freq_start + (freq_end - freq_start) * t
		var envelope := 1.0 - t * 0.5
		phase += freq / float(sample_rate)
		var sample_val := sin(phase * TAU) * volume * envelope
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
