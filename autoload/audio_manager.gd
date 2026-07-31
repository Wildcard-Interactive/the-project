extends Node
## Central audio playback for the project.
##
## Three jobs:
##   - one-shot SFX (UI blips, jumpscare stingers) via play_sfx()
##   - surface-aware footsteps via play_footstep()
##   - a single looping ambience bed via play_ambience()
##
## No mixer buses exist yet -- everything routes to Master and loudness is set
## per call via volume_db. Add SFX/Ambience buses here when the settings screen
## needs independent sliders.

## Surface name -> footstep filenames, relative to FOOTSTEP_DIR.
##
## Listed explicitly rather than scanned with DirAccess: res:// listing is not
## dependable in exported builds, and the vendor pack misspells the metal set
## ("Foodstep"), so a naming convention alone would not resolve every file.
const FOOTSTEP_DIR := "res://assets/audio/sfx/footsteps"
const FOOTSTEP_FILES := {
	"concrete": [
		"Footstep Concrete 1.ogg", "Footstep Concrete 2.ogg", "Footstep Concrete 3.ogg",
		"Footstep Concrete 4.ogg", "Footstep Concrete 5.ogg",
	],
	"dirt": [
		"Footstep Dirt 1.ogg", "Footstep Dirt 2.ogg", "Footstep Dirt 3.ogg",
		"Footstep Dirt 4.ogg", "Footstep Dirt 5.ogg",
	],
	"grass": [
		"Footstep Grass 1.ogg", "Footstep Grass 2.ogg", "Footstep Grass 3.ogg",
		"Footstep Grass 4.ogg", "Footstep Grass 5.ogg", "Footstep Grass 6.ogg",
	],
	"gravel": [
		"Footstep Gravel 1.ogg", "Footstep Gravel 2.ogg", "Footstep Gravel 3.ogg",
		"Footstep Gravel 4.ogg", "Footstep Gravel 5.ogg",
	],
	"metal": [
		"Foodstep Metal 1.ogg", "Foodstep Metal 2.ogg", "Foodstep Metal 3.ogg",
		"Foodstep Metal 4.ogg", "Foodstep Metal 5.ogg",
	],
	"stairs": [
		"Footstep Stairs 1.ogg", "Footstep Stairs 2.ogg", "Footstep Stairs 3.ogg",
		"Footstep Stairs 4.ogg", "Footstep Stairs 5.ogg",
	],
	"stone": [
		"Footstep Stone 1.ogg", "Footstep Stone 2.ogg", "Footstep Stone 3.ogg",
		"Footstep Stone 4.ogg",
	],
	"wood": [
		"Footstep Wood 1.ogg", "Footstep Wood 2.ogg", "Footstep Wood 3.ogg",
		"Footstep Wood 4.ogg", "Footstep Wood 5.ogg",
	],
}

## Used when the player is not standing in any tagged surface zone. The GDD
## calls out concrete and metal as the signature surfaces; Level_0 is a
## concrete basement cell, so concrete is the sane floor default.
const DEFAULT_SURFACE := "concrete"

## Levels tag floor zones by putting an Area2D in "surface_<name>", e.g.
## "surface_metal". See surface_for_areas().
const SURFACE_GROUP_PREFIX := "surface_"

## Enough voices that overlapping steps/stingers don't cut each other off.
const SFX_POOL_SIZE := 8

var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _ambience_player: AudioStreamPlayer
var _ambience_path: String = ""
var _ambience_tween: Tween

# surface name -> Array[AudioStream], filled on first use.
var _footstep_cache: Dictionary = {}
# surface name -> last index played, so a sound never repeats back to back.
var _last_footstep: Dictionary = {}

func _ready() -> void:
	for _i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_pool.append(player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	add_child(_ambience_player)

func _exit_tree() -> void:
	# Release streams explicitly on teardown. Note this does NOT silence the
	# "N instances leaked at exit" notice you get when quitting mid-playback:
	# by the time an autoload's _exit_tree runs, the audio server no longer
	# gets a chance to release the streaming playback. That notice is cosmetic
	# (process is ending, nothing accumulates) and any looping stream playing
	# at quit produces it. Stopping playback earlier is the only real fix.
	if _ambience_tween:
		_ambience_tween.kill()
	_ambience_player.stop()
	_ambience_player.stream = null
	for player in _sfx_pool:
		player.stop()
		player.stream = null
	_footstep_cache.clear()

## Play a one-shot from an absolute res:// path. This is the entry point for
## sfx/ui/ and sfx/stingers/ -- UI and event code can call it without any
## further plumbing.
func play_sfx(path: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: no AudioStream at %s" % path)
		return
	_play_on_pool(stream, volume_db, pitch_scale)

## Play a random footstep for the given surface. Unknown surfaces fall back to
## DEFAULT_SURFACE rather than going silent, so an untagged level still sounds
## like something.
func play_footstep(surface: String, volume_db: float = 0.0) -> void:
	var streams := _streams_for_surface(surface)
	if streams.is_empty():
		return
	var index := randi() % streams.size()
	if streams.size() > 1 and index == _last_footstep.get(surface, -1):
		index = (index + 1) % streams.size()
	_last_footstep[surface] = index
	# Slight pitch jitter so repeated steps don't read as a looping sample.
	_play_on_pool(streams[index], volume_db, randf_range(0.94, 1.06))

## Start (or switch to) a looping ambience bed. Calling it again with the path
## already playing is a no-op, so levels can call it unconditionally.
func play_ambience(path: String, volume_db: float = -14.0, fade_in: float = 2.0) -> void:
	if path == _ambience_path and _ambience_player.playing:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: no AudioStream at %s" % path)
		return
	# The pack imports with loop=false. Duplicate before enabling loop so this
	# doesn't mutate the shared imported resource for every other user of it.
	stream = stream.duplicate()
	if "loop" in stream:
		stream.loop = true
	_ambience_path = path
	_ambience_player.stream = stream
	_ambience_player.play()
	if _ambience_tween:
		_ambience_tween.kill()
	if fade_in > 0.0:
		_ambience_player.volume_db = volume_db - 24.0
		_ambience_tween = create_tween()
		_ambience_tween.tween_property(_ambience_player, "volume_db", volume_db, fade_in)
	else:
		_ambience_player.volume_db = volume_db

func stop_ambience(fade_out: float = 1.5) -> void:
	if not _ambience_player.playing:
		return
	_ambience_path = ""
	if _ambience_tween:
		_ambience_tween.kill()
	if fade_out <= 0.0:
		_ambience_player.stop()
		return
	_ambience_tween = create_tween()
	_ambience_tween.tween_property(_ambience_player, "volume_db", -40.0, fade_out)
	_ambience_tween.tween_callback(_ambience_player.stop)

## Resolve a surface name from areas the player is currently overlapping.
## Keeps the group-naming convention in one place. Returns DEFAULT_SURFACE
## when nothing is tagged.
func surface_for_areas(areas: Array[Area2D]) -> String:
	for area in areas:
		for group in area.get_groups():
			var name := String(group)
			if name.begins_with(SURFACE_GROUP_PREFIX):
				return name.substr(SURFACE_GROUP_PREFIX.length())
	return DEFAULT_SURFACE

func _play_on_pool(stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
	var player := _sfx_pool[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _streams_for_surface(surface: String) -> Array:
	var key := surface if FOOTSTEP_FILES.has(surface) else DEFAULT_SURFACE
	if _footstep_cache.has(key):
		return _footstep_cache[key]
	var streams: Array = []
	for file_name in FOOTSTEP_FILES[key]:
		var stream := load("%s/%s/%s" % [FOOTSTEP_DIR, key, file_name]) as AudioStream
		if stream:
			streams.append(stream)
	_footstep_cache[key] = streams
	return streams
