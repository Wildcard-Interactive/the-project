extends Node2D
## Level_0 -- the basement waking-up sequence.
##
## Controls the opening cinematic beat (eyes overlay -> fade to the cell),
## the forced-still moment before control unlocks, and the exit trigger at
## the stairwell. Pacing per the confirmed plan: disorientation first,
## environmental obstacle (locked door) before any threat, drone glimpsed
## safely from a distance, forward hook at the stairwell.

const EYES_HOLD_SECONDS := 3.0
const FADE_SECONDS := 2.5
const STILL_SECONDS := 1.5

## Ambience bed for the basement tier. Which track fits is a taste call --
## the "Area Tunnels" beds read as a collapsed sub-level, but swap this in the
## inspector to audition anything else in assets/audio/ambience/.
@export_file("*.ogg") var ambience_track: String = "res://assets/audio/ambience/AMBUndr_Atmo-Area Tunnels 01_TGRJ_GSHR1.ogg"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var cinematic: CanvasLayer = $Cinematic
@onready var black_rect: ColorRect = $Cinematic/BlackRect
@onready var eyes_rect: TextureRect = $Cinematic/EyesRect
@onready var exit_label: Label = $Cinematic/ExitLabel

func _ready() -> void:
	GameState.reset_run()
	exit_label.hide()
	AudioManager.play_ambience(ambience_track)
	_run_intro()

## R restarts the level, per the Controls section of the GDD.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		# Cut the bed instantly -- _ready() fades a fresh one back in.
		AudioManager.stop_ambience(0.0)
		get_tree().reload_current_scene()

func _run_intro() -> void:
	# No control during the opening beat.
	player.set_physics_process(false)
	cinematic.visible = true
	black_rect.modulate.a = 1.0
	eyes_rect.modulate.a = 1.0

	# Hold on the eyes -- the image that set the tone for the project.
	await get_tree().create_timer(EYES_HOLD_SECONDS).timeout

	# Fade the overlay out to reveal the cell.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(eyes_rect, "modulate:a", 0.0, FADE_SECONDS * 0.6)
	tween.tween_property(black_rect, "modulate:a", 0.0, FADE_SECONDS)
	await tween.finished
	eyes_rect.hide()

	# Brief forced stillness on the floor of the cell, then control unlocks.
	await get_tree().create_timer(STILL_SECONDS).timeout
	player.set_physics_process(true)
	hud.set_controls_hint_visible(true)

func _on_player_interaction_prompt_changed(text: String) -> void:
	hud.set_prompt(text)

func _on_locked_door_interacted() -> void:
	hud.flash_message("Sealed from the other side.")

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body != player:
		return
	# Forward hook: fade out at the stairwell leading up into the facility.
	player.set_physics_process(false)
	black_rect.show()
	exit_label.show()
	exit_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(black_rect, "modulate:a", 1.0, 2.0)
	tween.tween_property(exit_label, "modulate:a", 1.0, 1.5)
	# Level_1 (labs/blacksite tier) doesn't exist yet -- see GDD addendum
	# for the bottom-to-top progression. For now the run ends here.
