extends Resource
class_name CatCharacter
## CatCharacter
##
## Defines a cat companion's identity, personality, and unlock conditions.

## Unique identifier (e.g., "mochi", "sushi", "matcha").
@export var cat_id: String = ""

## Display name for this cat.
@export var cat_name: String = ""

## Short personality description shown in the cat collection screen.
@export var personality: String = ""

## Which mini-game this cat specializes in (scene name, e.g., "MultipleChoice").
@export var specialty_game: String = ""

## Path to the sprite sheet resource for this cat.
@export var sprite_sheet: Texture2D = null

## Condition to unlock: "default" (always unlocked), "level:5", "achievement:first_quiz", etc.
@export var unlock_condition: String = "default"

## Lines of dialogue the cat can say. Randomly selected.
@export var dialogue_lines: PackedStringArray = []

## Color tint for this cat's theme/accent in UI.
@export var accent_color: Color = Color.WHITE

## Numeric index for sprite sheet loading (CAT_{cat_number}_{State}.png).
@export var cat_number: int = 1
