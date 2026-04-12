extends Resource
class_name CafeDecoration
## CafeDecoration
##
## Defines a visual decoration item that can be unlocked and placed in the cafe hub.
## Decorations are cosmetic-only and change the appearance of the cafe background.

## Unique identifier (e.g., "plant_bonsai", "wall_scroll_sakura").
@export var id: String = ""

## Display name shown in the shop/collection.
@export var display_name: String = ""

## Short description of the decoration.
@export var description: String = ""

## Which slot this decoration goes in (e.g., "wall", "counter", "table", "window", "floor").
@export var slot: String = ""

## The visual emoji/text representation (placeholder until we have pixel art).
@export var icon_text: String = "🪴"

## Unlock condition: "default" (always available), "level:5", "xp:1000", etc.
@export var unlock_condition: String = "default"

## Whether this decoration is available to the player (derived at runtime, not saved).
var is_unlocked: bool = false
