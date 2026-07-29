class_name Interactable
extends Area2D
## Attach to an Area2D to make something the player can interact with.
##
## The player's InteractionSensor picks these up; the HUD shows prompt_text
## while one is in range, and pressing the interact action calls trigger().
## Extend by connecting to the interacted signal (or subclassing for
## stateful objects like doors and terminals).

signal interacted

## Shown in the HUD prompt while the player is in range, prefixed with the
## interact key (e.g. "E — Inspect door").
@export var prompt_text: String = "Interact"

func trigger() -> void:
	interacted.emit()
