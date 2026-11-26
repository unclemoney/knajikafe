extends Resource
class_name SkillEvidence
## Observed attempts for one learning skill on an SRS card.

@export var attempts: int = 0
@export var correct: int = 0
@export var lapses: int = 0
@export var consecutive_correct: int = 0
@export var last_quality: int = -1
@export var last_review_date: String = ""
@export var last_source: String = ""


func record(quality: int, review_date: String, source: String) -> void:
	attempts += 1
	last_quality = clampi(quality, 0, 5)
	last_review_date = review_date
	last_source = source
	if quality >= 3:
		correct += 1
		consecutive_correct += 1
	else:
		lapses += 1
		consecutive_correct = 0


func get_success_rate() -> float:
	if attempts == 0:
		return 0.0
	return float(correct) / float(attempts)


func to_dict() -> Dictionary:
	return {
		"attempts": attempts,
		"correct": correct,
		"lapses": lapses,
		"consecutive_correct": consecutive_correct,
		"last_quality": last_quality,
		"last_review_date": last_review_date,
		"last_source": last_source,
	}


static func from_dict(data: Dictionary) -> SkillEvidence:
	var evidence := SkillEvidence.new()
	evidence.attempts = int(data.get("attempts", 0))
	evidence.correct = int(data.get("correct", 0))
	evidence.lapses = int(data.get("lapses", 0))
	evidence.consecutive_correct = int(data.get("consecutive_correct", 0))
	evidence.last_quality = int(data.get("last_quality", -1))
	evidence.last_review_date = data.get("last_review_date", "")
	evidence.last_source = data.get("last_source", "")
	return evidence
