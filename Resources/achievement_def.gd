extends Resource
class_name AchievementDef
## AchievementDef
##
## Defines a single achievement with its unlock condition and display data.

## Unique identifier (e.g., "first_quiz", "streak_7").
@export var id: String = ""

## Display title (e.g., "First Steps").
@export var title: String = ""

## Description of how to earn it (e.g., "Complete your first quiz").
@export var description: String = ""

## Icon texture for the achievement badge.
@export var icon: Texture2D = null

## Unlock condition string. Parsed by the achievement system.
## Formats: "quiz_count:1", "words_learned:100", "streak:7",
##          "level:5", "cats_unlocked:3", "category_complete:n5"
@export var unlock_condition: String = ""

## Whether this achievement is hidden until unlocked.
@export var is_hidden: bool = false
