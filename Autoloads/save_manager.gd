extends Node
## SaveManager (Autoload)
##
## Handles player profile CRUD operations. Profiles are saved to
## user://profiles/<sanitized_name>/profile.tres and srs_data.tres.

## Base directory for all profile saves.
const PROFILES_DIR: String = "user://profiles/"


func _ready() -> void:
	_ensure_profiles_dir()


## Creates a new player profile with the given name.
## Returns the new PlayerProfile, or null if name already taken.
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

	var err := ResourceSaver.save(profile, dir_path + "profile.tres")
	if err != OK:
		push_error("SaveManager: Failed to save new profile: %s" % error_string(err))
		return null

	# Create empty SRS data array
	_save_srs_data(safe_name, [])
	return profile


## Loads a profile by player name. Returns null if not found.
func load_profile(player_name: String) -> PlayerProfile:
	var safe_name := _sanitize_name(player_name)
	var path := PROFILES_DIR + safe_name + "/profile.tres"
	if not ResourceLoader.exists(path):
		push_warning("SaveManager: Profile not found at '%s'." % path)
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerProfile


## Saves the given profile to disk.
func save_profile(profile: PlayerProfile) -> bool:
	var safe_name := _sanitize_name(profile.player_name)
	var dir_path := PROFILES_DIR + safe_name + "/"
	_ensure_profiles_dir()

	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	profile.last_played = GameController.get_current_date()
	var err := ResourceSaver.save(profile, dir_path + "profile.tres")
	if err != OK:
		push_error("SaveManager: Failed to save profile: %s" % error_string(err))
		return false
	return true


## Deletes a profile and all its data.
func delete_profile(player_name: String) -> bool:
	var safe_name := _sanitize_name(player_name)
	var dir_path := PROFILES_DIR + safe_name + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		return false

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return false

	# Delete all files in the profile directory
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Remove the directory itself
	DirAccess.remove_absolute(dir_path)
	return true


## Returns an array of player names for all existing profiles.
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


## Loads SRS card data for a profile. Returns an Array of SRSCard resources.
func load_srs_data(player_name: String) -> Array:
	var safe_name := _sanitize_name(player_name)
	var path := PROFILES_DIR + safe_name + "/srs_data.tres"
	if not ResourceLoader.exists(path):
		return []
	var data = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if data is Resource and data.has_method("get"):
		return data.get("cards") if data.get("cards") is Array else []
	return []


## Saves SRS card data for a profile.
func save_srs_data(player_name: String, cards: Array) -> bool:
	var safe_name := _sanitize_name(player_name)
	return _save_srs_data(safe_name, cards)


## Ensures the base profiles directory exists.
func _ensure_profiles_dir() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)


## Sanitizes a player name for use as a directory name.
func _sanitize_name(player_name: String) -> String:
	var safe := player_name.to_lower().strip_edges()
	# Replace unsafe filesystem characters
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


## Internal: saves SRS card array as a simple JSON file for flexibility.
func _save_srs_data(safe_name: String, cards: Array) -> bool:
	var dir_path := PROFILES_DIR + safe_name + "/"
	var path := dir_path + "srs_data.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Cannot write SRS data to '%s'." % path)
		return false

	var data_array: Array = []
	for card in cards:
		if card is SRSCard:
			data_array.append({
				"vocab_id": card.vocab_id,
				"ease_factor": card.ease_factor,
				"interval": card.interval,
				"repetitions": card.repetitions,
				"next_review_date": card.next_review_date,
				"last_review_date": card.last_review_date,
				"total_reviews": card.total_reviews,
				"correct_reviews": card.correct_reviews,
			})

	file.store_string(JSON.stringify(data_array, "\t"))
	file.close()
	return true


## Loads SRS cards from JSON file.
func load_srs_cards(player_name: String) -> Array[SRSCard]:
	var safe_name := _sanitize_name(player_name)
	var path := PROFILES_DIR + safe_name + "/srs_data.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("SaveManager: Failed to parse SRS data: %s" % json.get_error_message())
		return []

	var cards: Array[SRSCard] = []
	var data_array = json.data
	if data_array is Array:
		for entry in data_array:
			if entry is Dictionary:
				var card := SRSCard.new()
				card.vocab_id = entry.get("vocab_id", "")
				card.ease_factor = entry.get("ease_factor", 2.5)
				card.interval = entry.get("interval", 0.0)
				card.repetitions = entry.get("repetitions", 0)
				card.next_review_date = entry.get("next_review_date", "")
				card.last_review_date = entry.get("last_review_date", "")
				card.total_reviews = entry.get("total_reviews", 0)
				card.correct_reviews = entry.get("correct_reviews", 0)
				cards.append(card)

	return cards
