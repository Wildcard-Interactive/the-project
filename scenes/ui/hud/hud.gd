extends CanvasLayer
## In-game HUD. MVP scope: the contextual interact prompt, plus a small
## flash message so interactions have visible feedback. This is the
## placeholder pattern to extend later (ability prompts etc.) -- not a
## full HUD system.

@onready var prompt_label: Label = $PromptLabel
@onready var message_label: Label = $MessageLabel
@onready var controls_hint: HBoxContainer = $ControlsHint

var _message_tween: Tween

func _ready() -> void:
	prompt_label.hide()
	message_label.hide()
	# Kept out of the way during the opening cinematic; the level shows it once
	# the player actually has control.
	controls_hint.hide()

## Show/hide the static key-icon row along the bottom edge.
func set_controls_hint_visible(visible_: bool) -> void:
	controls_hint.visible = visible_

## Pass the text to show, or "" to hide the prompt.
func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text != ""

## Briefly show a line of feedback (e.g. the result of an interaction).
func flash_message(text: String, duration: float = 2.5) -> void:
	if _message_tween:
		_message_tween.kill()
	message_label.text = text
	message_label.modulate.a = 1.0
	message_label.show()
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.8)
	_message_tween.tween_callback(message_label.hide)
