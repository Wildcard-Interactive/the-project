extends Node2D
## Minimal patrol AI for the MVP.
##
## Walks a straight line and reverses direction when the raycast facing
## its direction of travel detects an obstacle. No player detection or
## vision cone yet -- this is movement scaffolding for the stealth loop,
## not the full AI described in the GDD. Written fresh, not reusing the
## discarded draft (which checked all four rays every frame regardless of
## travel direction).

@export var speed: float = 60.0
## Cardinal direction the drone starts patrolling in (set per-instance).
@export var initial_direction: Vector2 = Vector2.RIGHT

@onready var _ray_by_direction: Dictionary = {
	Vector2.UP: $RayCastNorth,
	Vector2.RIGHT: $RayCastEast,
	Vector2.DOWN: $RayCastSouth,
	Vector2.LEFT: $RayCastWest,
}

var _direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_direction = initial_direction.normalized()

func _process(delta: float) -> void:
	var forward_ray: RayCast2D = _ray_by_direction.get(_direction)
	if forward_ray and forward_ray.is_colliding():
		_direction = -_direction
	position += _direction * speed * delta
