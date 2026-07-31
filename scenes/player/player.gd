extends CharacterBody2D
## Minimal top-down movement controller for the MVP.
##
## Three speed tiers -- crouch, walk, sprint -- matching the stealth framing
## in the GDD. No noise/visibility system is wired in yet; this is just the
## movement primitive those systems will hook into later. Written fresh,
## not reusing the discarded draft controllers.

## Emitted with the prompt to display ("" when nothing is in range).
signal interaction_prompt_changed(text: String)

@export var crouch_speed: float = 90.0
@export var walk_speed: float = 180.0
@export var sprint_speed: float = 320.0

## Distance covered between footstep sounds. Tuned by feel rather than measured
## against the sprite -- retune alongside the speed exports above.
const STRIDE_PIXELS := 48.0

## Per-mode footstep loudness. Crouching is quiet on purpose: the stealth loop
## in the GDD keys off noise, so this is the audible tell for it.
const FOOTSTEP_VOLUME_DB := {
	"crouch": -14.0,
	"walk": -6.0,
	"sprint": -2.0,
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var _surface_probe: Area2D = $SurfaceProbe

var _nearby_interactables: Array[Interactable] = []
var _distance_since_step: float = 0.0

var _sprite_by_direction: Dictionary = {
	"up": preload("res://assets/characters/player/idle_up.png"),
	"down": preload("res://assets/characters/player/idle_down.png"),
	"left": preload("res://assets/characters/player/idle_left.png"),
	"right": preload("res://assets/characters/player/idle_right.png"),
}
var _facing: String = "down"

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	# Crouch takes priority over sprint -- you can't sprint while crouched.
	var mode := "walk"
	var speed := walk_speed
	if Input.is_action_pressed("crouch"):
		mode = "crouch"
		speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		mode = "sprint"
		speed = sprint_speed

	if input_vector.length() > 0.0:
		_update_facing(input_vector)

	velocity = input_vector * speed
	move_and_slide()
	_accumulate_footsteps(delta, mode)

	if Input.is_action_just_pressed("interact"):
		var target := _nearest_interactable()
		if target:
			target.trigger()

## Emit a footstep every STRIDE_PIXELS of actual travel. Distance-based rather
## than on a timer so cadence follows speed for free -- sprinting sounds fast,
## crouching sounds slow, with no extra bookkeeping.
func _accumulate_footsteps(delta: float, mode: String) -> void:
	# move_and_slide() rewrites velocity to what actually happened, so walking
	# into a wall correctly produces no steps.
	var travelled := velocity.length() * delta
	if travelled <= 0.0:
		# Prime the accumulator so the first step after standing still lands
		# promptly instead of half a stride late.
		_distance_since_step = STRIDE_PIXELS * 0.5
		return
	_distance_since_step += travelled
	if _distance_since_step < STRIDE_PIXELS:
		return
	_distance_since_step -= STRIDE_PIXELS
	AudioManager.play_footstep(_current_surface(), FOOTSTEP_VOLUME_DB[mode])

## Surface under the player's feet, read from Area2D zones tagged
## "surface_<name>" (e.g. "surface_metal"). Untagged ground falls back to the
## AudioManager default, so a level with no zones still sounds like something.
func _current_surface() -> String:
	return AudioManager.surface_for_areas(_surface_probe.get_overlapping_areas())

func _nearest_interactable() -> Interactable:
	var nearest: Interactable = null
	var nearest_dist := INF
	for interactable in _nearby_interactables:
		var dist := global_position.distance_squared_to(interactable.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = interactable
	return nearest

func _refresh_prompt() -> void:
	var target := _nearest_interactable()
	if target:
		interaction_prompt_changed.emit("E — %s" % target.prompt_text)
	else:
		interaction_prompt_changed.emit("")

func _on_interaction_sensor_area_entered(area: Area2D) -> void:
	if area is Interactable:
		_nearby_interactables.append(area)
		_refresh_prompt()

func _on_interaction_sensor_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_nearby_interactables.erase(area)
		_refresh_prompt()

func _update_facing(input_vector: Vector2) -> void:
	if abs(input_vector.x) > abs(input_vector.y):
		_facing = "right" if input_vector.x > 0.0 else "left"
	else:
		_facing = "down" if input_vector.y > 0.0 else "up"
	sprite.texture = _sprite_by_direction[_facing]
