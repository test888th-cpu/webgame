class_name Player
extends Node2D
## The locally controlled hero. Reads input actions, applies LaneMovement and
## flips the placeholder body to face the movement direction.

## Walkable street area, in world coordinates. Set by the zone.
var bounds := Rect2(0, 0, 640, 360)
var facing := 1

@onready var _body: Node2D = $Body


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position = LaneMovement.step(position, input, delta, bounds)
	facing = LaneMovement.facing(facing, input)
	_body.scale.x = facing
