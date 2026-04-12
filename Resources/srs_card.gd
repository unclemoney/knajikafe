extends Resource
class_name SRSCard
## SRSCard
##
## Tracks SM-2 spaced repetition data for a single vocabulary word.
## Managed by SRSEngine, stored per-profile.

## Reference to the VocabWord.id this card tracks.
@export var vocab_id: String = ""

## SM-2 easiness factor (minimum 1.3, default 2.5).
@export var ease_factor: float = 2.5

## Current interval in days until next review.
@export var interval: float = 0.0

## Number of consecutive successful reviews (quality >= 3).
@export var repetitions: int = 0

## ISO 8601 date string for when this card is next due.
@export var next_review_date: String = ""

## ISO 8601 date string of the last review.
@export var last_review_date: String = ""

## Total number of times this card has been reviewed.
@export var total_reviews: int = 0

## Total number of correct answers (quality >= 3).
@export var correct_reviews: int = 0


## Returns true if this card is due for review (on or before the given date).
func is_due(current_date: String) -> bool:
	if next_review_date == "":
		return true
	return next_review_date <= current_date


## Returns the accuracy percentage (0.0–1.0), or 0.0 if never reviewed.
func get_accuracy() -> float:
	if total_reviews == 0:
		return 0.0
	return float(correct_reviews) / float(total_reviews)
