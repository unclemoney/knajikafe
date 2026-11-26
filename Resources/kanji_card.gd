extends SRSCard
class_name KanjiCard
## SM-2 state and skill evidence for one kanji character.

@export var character: String = ""


func setup(value: String) -> void:
	character = value
	vocab_id = "kanji:" + value
