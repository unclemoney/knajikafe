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
var _sfx_card_flip: AudioStreamWAV = null
var _sfx_meow: AudioStreamWAV = null
var _sfx_achievement: AudioStreamWAV = null
var _sfx_streak: AudioStreamWAV = null

## Procedural BGM streams (generated at startup).
var _bgm_cafe: AudioStreamWAV = null
var _bgm_quiz: AudioStreamWAV = null
var _bgm_results: AudioStreamWAV = null


func _ready() -> void:
	_setup_bgm_player()
	_setup_sfx_pool()
	_generate_placeholder_sfx()
	_generate_procedural_bgm()


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


## Plays the card flip SFX.
func play_card_flip() -> void:
	if _sfx_card_flip:
		play_sfx(_sfx_card_flip, 0.05)


## Plays a cat meow SFX with pitch variation.
func play_meow() -> void:
	if _sfx_meow:
		play_sfx(_sfx_meow, 0.15)


## Plays the achievement unlock SFX.
func play_achievement() -> void:
	if _sfx_achievement:
		play_sfx(_sfx_achievement)


## Plays the streak milestone SFX.
func play_streak() -> void:
	if _sfx_streak:
		play_sfx(_sfx_streak)


## Plays the cafe hub BGM (lofi ambient).
func play_cafe_bgm() -> void:
	if _bgm_cafe:
		play_bgm(_bgm_cafe)


## Plays the quiz/mini-game BGM (upbeat).
func play_quiz_bgm() -> void:
	if _bgm_quiz:
		play_bgm(_bgm_quiz)


## Plays the results screen BGM (gentle).
func play_results_bgm() -> void:
	if _bgm_results:
		play_bgm(_bgm_results)


## Generates simple procedural placeholder sounds.
func _generate_placeholder_sfx() -> void:
	_sfx_correct = _generate_tone(660.0, 0.15, 0.6)
	_sfx_wrong = _generate_tone(220.0, 0.25, 0.5)
	_sfx_click = _generate_tone(880.0, 0.05, 0.3)
	_sfx_level_up = _generate_rising_tone(440.0, 880.0, 0.4, 0.6)
	_sfx_card_flip = _generate_noise_burst(0.08, 0.3)
	_sfx_meow = _generate_meow(0.3, 0.5)
	_sfx_achievement = _generate_fanfare(0.6, 0.6)
	_sfx_streak = _generate_rising_tone(330.0, 660.0, 0.25, 0.5)


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


## Generates a short noise burst (for card flip effect).
func _generate_noise_burst(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / float(num_samples)
		var envelope := 1.0 - t
		var noise := randf_range(-1.0, 1.0)
		var sample_val := noise * volume * envelope * 0.3
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generates a cat meow sound (frequency-modulated sine).
func _generate_meow(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	var phase := 0.0
	for i in num_samples:
		var t := float(i) / float(num_samples)
		# Meow: rises then falls in pitch
		var freq := 600.0 + 400.0 * sin(t * PI)
		var envelope := sin(t * PI) * (1.0 - t * 0.3)
		phase += freq / float(sample_rate)
		var sample_val := sin(phase * TAU) * volume * envelope
		# Add slight harmonic for character
		sample_val += sin(phase * TAU * 2.0) * volume * envelope * 0.15
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generates a short achievement fanfare (ascending arpeggio).
func _generate_fanfare(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	# C major arpeggio: C5, E5, G5, C6
	var notes := [523.25, 659.25, 783.99, 1046.50]
	var note_len := num_samples / notes.size()
	var phase := 0.0

	for i in num_samples:
		var note_idx := mini(i / note_len, notes.size() - 1)
		var local_t := float(i - note_idx * note_len) / float(note_len)
		var freq: float = notes[note_idx]
		var envelope := (1.0 - local_t * 0.4)
		if note_idx == notes.size() - 1:
			# Last note sustains and fades
			envelope = 1.0 - local_t
		phase += freq / float(sample_rate)
		var sample_val := sin(phase * TAU) * volume * envelope
		sample_val += sin(phase * TAU * 2.0) * volume * envelope * 0.2
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generates procedural BGM tracks.
func _generate_procedural_bgm() -> void:
	_bgm_cafe = _generate_lofi_track(16.0, 0.25)
	_bgm_quiz = _generate_upbeat_track(12.0, 0.25)
	_bgm_results = _generate_gentle_track(10.0, 0.2)


## Generates a lofi-style ambient track using pentatonic melody over pads.
func _generate_lofi_track(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	# C pentatonic: C4, D4, E4, G4, A4, C5
	var scale := [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]
	var bpm := 70.0
	var beat_samples := int(sample_rate * 60.0 / bpm)
	var chord_root := 261.63
	var pad_phase := 0.0
	var melody_phase := 0.0
	var current_note : int = scale[0]
	var note_seed := 42

	for i in num_samples:
		var beat_pos := i / beat_samples
		var local_in_beat := float(i % beat_samples) / float(beat_samples)

		# Change melody note every beat
		if i % beat_samples == 0:
			note_seed = (note_seed * 1103515245 + 12345) & 0x7FFFFFFF
			current_note = scale[note_seed % scale.size()]
			# Change chord every 4 beats
			if beat_pos % 4 == 0:
				var chord_idx := (beat_pos / 4) % 4
				if chord_idx == 0:
					chord_root = 261.63  # C
				elif chord_idx == 1:
					chord_root = 220.00  # A
				elif chord_idx == 2:
					chord_root = 196.00  # G
				else:
					chord_root = 246.94  # B

		# Soft pad chord (root + fifth)
		pad_phase += chord_root / float(sample_rate)
		var pad := sin(pad_phase * TAU) * 0.3
		pad += sin(pad_phase * TAU * 1.5) * 0.15
		pad += sin(pad_phase * TAU * 2.0) * 0.08

		# Melody with gentle attack/release
		melody_phase += current_note / float(sample_rate)
		var mel_env := 0.0
		if local_in_beat < 0.1:
			mel_env = local_in_beat / 0.1
		elif local_in_beat < 0.7:
			mel_env = 1.0
		else:
			mel_env = (1.0 - local_in_beat) / 0.3
		var melody := sin(melody_phase * TAU) * 0.4 * mel_env

		var sample_val := (pad + melody) * volume
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	stream.data = data
	return stream


## Generates an upbeat quiz track using faster tempo and brighter tones.
func _generate_upbeat_track(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	var scale := [329.63, 392.00, 440.00, 523.25, 587.33, 659.25]
	var bpm := 110.0
	var beat_samples := int(sample_rate * 60.0 / bpm)
	var bass_phase := 0.0
	var melody_phase := 0.0
	var current_note : int = scale[0]
	var bass_note := 130.81
	var note_seed := 77

	for i in num_samples:
		var beat_pos := i / beat_samples
		var local_in_beat := float(i % beat_samples) / float(beat_samples)

		if i % beat_samples == 0:
			note_seed = (note_seed * 1103515245 + 12345) & 0x7FFFFFFF
			current_note = scale[note_seed % scale.size()]
			if beat_pos % 2 == 0:
				var bass_idx := (beat_pos / 2) % 3
				if bass_idx == 0:
					bass_note = 130.81
				elif bass_idx == 1:
					bass_note = 174.61
				else:
					bass_note = 146.83

		# Bouncy bass
		bass_phase += bass_note / float(sample_rate)
		var bass_env := 1.0 - local_in_beat * 0.8
		var bass := sin(bass_phase * TAU) * 0.35 * bass_env

		# Bright melody
		melody_phase += current_note / float(sample_rate)
		var mel_env := 0.0
		if local_in_beat < 0.05:
			mel_env = local_in_beat / 0.05
		elif local_in_beat < 0.5:
			mel_env = 1.0
		else:
			mel_env = (1.0 - local_in_beat) / 0.5
		var melody := sin(melody_phase * TAU) * 0.35 * mel_env
		melody += sin(melody_phase * TAU * 3.0) * 0.08 * mel_env

		var sample_val := (bass + melody) * volume
		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	stream.data = data
	return stream


## Generates a gentle results track using slow arpeggios.
func _generate_gentle_track(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	# C major 7th arpeggio pattern
	var notes := [261.63, 329.63, 392.00, 493.88, 523.25, 493.88, 392.00, 329.63]
	var bpm := 60.0
	var beat_samples := int(sample_rate * 60.0 / bpm)
	var phase := 0.0

	for i in num_samples:
		var beat_pos := i / beat_samples
		var local_in_beat := float(i % beat_samples) / float(beat_samples)
		var note_idx := beat_pos % notes.size()
		var freq: float = notes[note_idx]

		phase += freq / float(sample_rate)
		# Gentle bell-like envelope
		var envelope := 0.0
		if local_in_beat < 0.02:
			envelope = local_in_beat / 0.02
		else:
			envelope = exp(-local_in_beat * 3.0)

		var sample_val := sin(phase * TAU) * envelope
		sample_val += sin(phase * TAU * 2.0) * envelope * 0.3
		sample_val += sin(phase * TAU * 4.0) * envelope * 0.05
		sample_val *= volume

		var value := int(sample_val * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	stream.data = data
	return stream
