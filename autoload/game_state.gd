extends Node
## Tracks high-level state for the current playthrough.
##
## MVP stub only. Exists so early scenes (Level_0's waking-up sequence) have
## something real to read from, and so the save system has something to
## serialize once it's built out. Expand as actual systems come online --
## don't assume this shape is final.

## The narrative frame: the player doesn't know how long they've been in the
## facility. This flag is the hook for any UI/dialogue that plays on that
## uncertainty (e.g. a corrupted clock, a stammering NPC). Not wired into
## anything yet.
var time_elapsed_unknown: bool = true

## Placeholder counter for the "recovering memory" thread. No gameplay
## system increments this yet.
var memory_fragments_recovered: int = 0

func reset_run() -> void:
	time_elapsed_unknown = true
	memory_fragments_recovered = 0
