extends RefCounted
class_name ActivityCatalog

const ACTIVITIES: Array[Dictionary] = [
	{"game_type": "multiple_choice", "name": "Multiple Choice", "scene_path": "res://Scenes/MiniGames/MultipleChoice/multiple_choice.tscn", "station": "quiz", "skill": "meaning", "session_size": 0, "description": "Choose vocabulary meanings"},
	{"game_type": "flashcard_review", "name": "Flashcard Review", "scene_path": "res://Scenes/MiniGames/FlashcardReview/flashcard_review.tscn", "station": "flashcards", "skill": "meaning", "session_size": 0, "description": "Self-rate vocabulary recall"},
	{"game_type": "kanji_matching", "name": "Kanji Matching", "scene_path": "res://Scenes/MiniGames/KanjiMatching/kanji_matching.tscn", "station": "table", "skill": "meaning", "session_size": 6, "description": "Match vocabulary and meanings"},
	{"game_type": "kanji_workshop", "name": "Kanji Workshop", "scene_path": "res://Scenes/MiniGames/KanjiWorkshop/kanji_workshop.tscn", "station": "table", "skill": "kanji_form", "session_size": 8, "description": "Practice kanji meanings, readings, and form"},
	{"game_type": "typing_input", "name": "Typing Input", "scene_path": "res://Scenes/MiniGames/TypingInput/typing_input.tscn", "station": "register", "skill": "reading", "session_size": 0, "description": "Type readings from meaning prompts"},
	{"game_type": "listening_lab", "name": "Listening Lab", "scene_path": "res://Scenes/MiniGames/ListeningLab/listening_lab.tscn", "station": "register", "skill": "listening", "session_size": 0, "description": "Transcribe spoken vocabulary readings", "require_audio": true},
	{"game_type": "fill_in_blank", "name": "Fill in the Blank", "scene_path": "res://Scenes/MiniGames/FillInBlank/fill_in_blank.tscn", "station": "bookshelf", "skill": "context", "session_size": 0, "description": "Complete professional lesson sentences and exercises", "require_cloze": true},
	{"game_type": "reading_shelf", "name": "Reading Shelf", "scene_path": "res://Scenes/MiniGames/ReadingShelf/reading_shelf.tscn", "station": "bookshelf", "skill": "context", "session_size": 5, "description": "Read passages and answer questions", "require_reading": true},
	{"game_type": "cafe_orders", "name": "Café Orders · Legacy Supplement", "scene_path": "res://Scenes/MiniGames/CafeOrders/cafe_orders.tscn", "station": "orders", "skill": "listening", "session_size": 0, "description": "Game-only café listening; separate from the professional curriculum", "require_menu": true, "require_audio": true},
]

const NOTEBOOK := {"game_type": "study_notebook", "name": "Study Notebook", "scene_path": "res://Scenes/StudyNotebook/study_notebook.tscn", "station": "bookshelf", "session_size": 0, "description": "Search vocabulary, examples, progress, and audio"}


static func get_activity(game_type: String) -> Dictionary:
	for activity in ACTIVITIES:
		if activity["game_type"] == game_type:
			return activity.duplicate(true)
	return {}


static func get_config(game_type: String, profile: PlayerProfile) -> Dictionary:
	var activity := get_activity(game_type)
	if activity.is_empty():
		return {}
	var words_per_session := int(profile.settings.get("words_per_session", 10))
	if int(activity.get("session_size", 0)) > 0:
		words_per_session = int(activity["session_size"])
	return {"game_type": game_type, "words_per_session": words_per_session, "scene_path": activity["scene_path"]}


static func get_option(game_type: String, profile: PlayerProfile) -> Dictionary:
	var activity := get_activity(game_type)
	if activity.is_empty():
		return {}
	return {"name": activity["name"], "description": activity["description"], "config": get_config(game_type, profile)}


static func get_station_options(station: String, profile: PlayerProfile) -> Array:
	var options: Array = []
	for activity in ACTIVITIES:
		if activity["station"] == station:
			options.append(get_option(activity["game_type"], profile))
	if station == "bookshelf":
		options.append({"name": NOTEBOOK["name"], "description": NOTEBOOK["description"], "config": {"game_type": "study_notebook", "words_per_session": 0, "scene_path": NOTEBOOK["scene_path"]}})
	return options


static func get_notebook_option() -> Dictionary:
	return {"name": NOTEBOOK["name"], "description": NOTEBOOK["description"], "config": {"game_type": "study_notebook", "words_per_session": 0, "scene_path": NOTEBOOK["scene_path"]}}
