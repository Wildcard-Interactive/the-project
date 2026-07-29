extends Node
## Save/load scaffolding.
##
## MVP stub only -- no real serialization yet. Wire this up to GameState
## (and eventually player/level state) once there's something worth
## persisting between sessions.

const SAVE_PATH := "user://save_slot_1.tres"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	# TODO: serialize GameState into a Resource and write it to SAVE_PATH.
	pass

func load_game() -> void:
	# TODO: read SAVE_PATH and restore GameState from it.
	pass
