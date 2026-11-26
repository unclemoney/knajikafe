extends Node
## SaveManager (Autoload)
## Handles profile CRUD and versioned learning-data persistence.

const PROFILES_DIR: String = "user://profiles/"
const LEARNING_SCHEMA_VERSION: int = 3
const MAX_SESSION_HISTORY: int = 100

var _write_blocked_profiles: Dictionary = {}


func _ready() -> void:
	_ensure_profiles_dir()


func create_profile(player_name: String) -> PlayerProfile:
	var safe_name := _sanitize_name(player_name)
	var dir_path := PROFILES_DIR + safe_name + "/"
	if DirAccess.dir_exists_absolute(dir_path):
		push_warning("SaveManager: Profile '%s' already exists." % player_name)
		return null
	DirAccess.make_dir_recursive_absolute(dir_path)
	var profile := PlayerProfile.new()
	profile.player_name = player_name
	profile.created_date = GameController.get_current_date()
	profile.last_played = profile.created_date
	_apply_profile_defaults(profile)
	var err := ResourceSaver.save(profile, dir_path + "profile.tres")
	if err != OK:
		push_error("SaveManager: Failed to save new profile: %s" % error_string(err))
		return null
	_write_blocked_profiles.erase(safe_name)
	if not save_learning_data(player_name, [], [], []):
		return null
	return profile


func load_profile(player_name: String) -> PlayerProfile:
	var safe_name := _sanitize_name(player_name)
	var path := PROFILES_DIR + safe_name + "/profile.tres"
	if not ResourceLoader.exists(path):
		push_warning("SaveManager: Profile not found at '%s'." % path)
		return null
	var profile := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerProfile
	if profile:
		_apply_profile_defaults(profile)
	return profile


func save_profile(profile: PlayerProfile) -> bool:
	var safe_name := _sanitize_name(profile.player_name)
	var dir_path := PROFILES_DIR + safe_name + "/"
	_ensure_profiles_dir()
	_apply_profile_defaults(profile)
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	profile.last_played = GameController.get_current_date()
	var err := ResourceSaver.save(profile, dir_path + "profile.tres")
	if err != OK:
		push_error("SaveManager: Failed to save profile: %s" % error_string(err))
		return false
	return true


func delete_profile(player_name: String) -> bool:
	var safe_name := _sanitize_name(player_name)
	var dir_path := PROFILES_DIR + safe_name + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		return false
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)
	_write_blocked_profiles.erase(safe_name)
	return true


func list_profiles() -> PackedStringArray:
	var names: PackedStringArray = []
	var dir := DirAccess.open(PROFILES_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var folder := dir.get_next()
	while folder != "":
		if dir.current_is_dir() and folder != "." and folder != "..":
			var profile := load_profile(folder)
			if profile:
				names.append(profile.player_name)
		folder = dir.get_next()
	dir.list_dir_end()
	return names


func load_learning_data(player_name: String) -> Dictionary:
	var safe_name := _sanitize_name(player_name)
	var path := PROFILES_DIR + safe_name + "/srs_data.json"
	var result := {
		"cards": [] as Array[SRSCard],
		"kanji_cards": [] as Array[KanjiCard],
		"sessions": [],
		"load_ok": true,
		"migrated": false,
	}
	if not FileAccess.file_exists(path):
		_write_blocked_profiles.erase(safe_name)
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failed_learning_load(safe_name, "Cannot open learning data")
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return _failed_learning_load(safe_name, "Failed to parse learning data: " + json.get_error_message())

	var source_version := 1
	var cards_data: Array = []
	var kanji_data: Array = []
	var sessions_data: Array = []
	if json.data is Array:
		cards_data = json.data
	elif json.data is Dictionary:
		var envelope: Dictionary = json.data
		source_version = int(envelope.get("schema_version", 0))
		if source_version not in [2, 3]:
			return _failed_learning_load(safe_name, "Unsupported learning-data schema")
		cards_data = envelope.get("cards", []) if envelope.get("cards", []) is Array else []
		kanji_data = envelope.get("kanji_cards", []) if envelope.get("kanji_cards", []) is Array else []
		sessions_data = envelope.get("sessions", []) if envelope.get("sessions", []) is Array else []
	else:
		return _failed_learning_load(safe_name, "Learning data must be an array or object")

	var cards: Array[SRSCard] = []
	for entry in cards_data:
		if entry is Dictionary:
			cards.append(_deserialize_card(entry))
	var kanji_cards: Array[KanjiCard] = []
	for entry in kanji_data:
		if entry is Dictionary:
			kanji_cards.append(_deserialize_kanji_card(entry))
	var sessions: Array = []
	for entry in sessions_data:
		if entry is Dictionary:
			sessions.append(entry.duplicate(true))
	if sessions.size() > MAX_SESSION_HISTORY:
		sessions = sessions.slice(sessions.size() - MAX_SESSION_HISTORY)

	if source_version < LEARNING_SCHEMA_VERSION:
		if not _backup_source_data(safe_name, json_text, source_version):
			return _failed_learning_load(safe_name, "Could not back up source learning data")
		if not _write_learning_file(path, cards, sessions, kanji_cards):
			return _failed_learning_load(safe_name, "Could not write migrated learning data")
		result["migrated"] = true
	_write_blocked_profiles.erase(safe_name)
	result["cards"] = cards
	result["kanji_cards"] = kanji_cards
	result["sessions"] = sessions
	return result


func save_learning_data(player_name: String, cards: Array, sessions: Array, kanji_cards: Array = []) -> bool:
	var safe_name := _sanitize_name(player_name)
	if _write_blocked_profiles.has(safe_name):
		push_error("SaveManager: Learning-data writes are blocked for '%s'." % player_name)
		return false
	var dir_path := PROFILES_DIR + safe_name + "/"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var bounded_sessions := sessions.duplicate(true)
	if bounded_sessions.size() > MAX_SESSION_HISTORY:
		bounded_sessions = bounded_sessions.slice(bounded_sessions.size() - MAX_SESSION_HISTORY)
	return _write_learning_file(dir_path + "srs_data.json", cards, bounded_sessions, kanji_cards)


func load_srs_cards(player_name: String) -> Array[SRSCard]:
	var data := load_learning_data(player_name)
	var cards: Array[SRSCard] = data["cards"]
	return cards


func save_srs_data(player_name: String, cards: Array) -> bool:
	var data := load_learning_data(player_name)
	if not data["load_ok"]:
		return false
	return save_learning_data(player_name, cards, data["sessions"], data["kanji_cards"])


func load_srs_data(player_name: String) -> Array:
	var safe_name := _sanitize_name(player_name)
	var path := PROFILES_DIR + safe_name + "/srs_data.tres"
	if not ResourceLoader.exists(path):
		return []
	var data = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if data is Resource and data.has_method("get"):
		return data.get("cards") if data.get("cards") is Array else []
	return []


func _write_learning_file(path: String, cards: Array, sessions: Array, kanji_cards: Array) -> bool:
	var cards_data: Array = []
	for card in cards:
		if card is SRSCard:
			cards_data.append(_serialize_card(card))
	var kanji_data: Array = []
	for card in kanji_cards:
		if card is KanjiCard:
			kanji_data.append(_serialize_card(card))
	var envelope := {
		"schema_version": LEARNING_SCHEMA_VERSION,
		"cards": cards_data,
		"kanji_cards": kanji_data,
		"sessions": sessions,
	}
	var json_text := JSON.stringify(envelope, "\t")
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Cannot write temporary learning data")
		return false
	file.store_string(json_text)
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("SaveManager: Failed to serialize learning data")
		return false
	var rename_error := DirAccess.rename_absolute(temp_path, path)
	if rename_error != OK:
		push_error("SaveManager: Failed to replace learning data: %s" % error_string(rename_error))
		return false
	return true


func _serialize_card(card: SRSCard) -> Dictionary:
	var evidence_data: Dictionary = {}
	for skill in card.skill_evidence:
		var evidence = card.skill_evidence[skill]
		if evidence is SkillEvidence:
			evidence_data[skill] = evidence.to_dict()
	var data := {
		"vocab_id": card.vocab_id,
		"ease_factor": card.ease_factor,
		"interval": card.interval,
		"repetitions": card.repetitions,
		"next_review_date": card.next_review_date,
		"last_review_date": card.last_review_date,
		"total_reviews": card.total_reviews,
		"correct_reviews": card.correct_reviews,
		"skill_evidence": evidence_data,
	}
	if card is KanjiCard:
		data["character"] = card.character
	return data


func _deserialize_card(entry: Dictionary) -> SRSCard:
	var card := SRSCard.new()
	_populate_card(card, entry)
	return card


func _deserialize_kanji_card(entry: Dictionary) -> KanjiCard:
	var card := KanjiCard.new()
	_populate_card(card, entry)
	card.character = entry.get("character", card.vocab_id.trim_prefix("kanji:"))
	if card.character == "":
		card.setup(card.vocab_id.trim_prefix("kanji:"))
	return card


func _populate_card(card: SRSCard, entry: Dictionary) -> void:
	card.vocab_id = entry.get("vocab_id", "")
	card.ease_factor = entry.get("ease_factor", 2.5)
	card.interval = entry.get("interval", 0.0)
	card.repetitions = entry.get("repetitions", 0)
	card.next_review_date = entry.get("next_review_date", "")
	card.last_review_date = entry.get("last_review_date", "")
	card.total_reviews = entry.get("total_reviews", 0)
	card.correct_reviews = entry.get("correct_reviews", 0)
	var evidence_data = entry.get("skill_evidence", {})
	if evidence_data is Dictionary:
		for skill in evidence_data:
			if evidence_data[skill] is Dictionary:
				card.skill_evidence[skill] = SkillEvidence.from_dict(evidence_data[skill])


func _backup_source_data(safe_name: String, json_text: String, source_version: int) -> bool:
	var backup_path := PROFILES_DIR + safe_name + "/srs_data_v%d_backup.json" % source_version
	if FileAccess.file_exists(backup_path):
		return true
	var backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if backup == null:
		return false
	backup.store_string(json_text)
	var err := backup.get_error()
	backup.close()
	return err == OK


func _failed_learning_load(safe_name: String, message: String) -> Dictionary:
	_write_blocked_profiles[safe_name] = true
	push_error("SaveManager: " + message)
	return {
		"cards": [] as Array[SRSCard],
		"kanji_cards": [] as Array[KanjiCard],
		"sessions": [],
		"load_ok": false,
		"migrated": false,
	}


func _apply_profile_defaults(profile: PlayerProfile) -> void:
	var defaults := {
		"show_kanji": true,
		"show_furigana": true,
		"show_romaji": false,
		"show_english": true,
		"bgm_volume": 0.8,
		"sfx_volume": 0.8,
		"words_per_session": 10,
		"target_jlpt_level": 5,
		"speech_volume": 0.85,
		"target_topic": "all",
		"new_cards_per_session": 5,
		"difficulty": "standard",
	}
	for key in defaults:
		if not profile.settings.has(key):
			profile.settings[key] = defaults[key]
	for decoration_id in profile.cafe_decorations:
		profile.owned_decorations[decoration_id] = true


func _ensure_profiles_dir() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)


func _sanitize_name(player_name: String) -> String:
	var safe := player_name.to_lower().strip_edges()
	safe = safe.replace(" ", "_")
	safe = safe.replace("/", "_")
	safe = safe.replace("\\", "_")
	safe = safe.replace(":", "_")
	safe = safe.replace("*", "_")
	safe = safe.replace("?", "_")
	safe = safe.replace("\"", "_")
	safe = safe.replace("<", "_")
	safe = safe.replace(">", "_")
	safe = safe.replace("|", "_")
	return safe
