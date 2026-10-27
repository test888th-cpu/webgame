class_name ShieldView
extends Node2D
## A boss's shield (BossMechanics "shield"): a pulsing blue dome around them
## while they cannot be hurt. Drawn with shapes until the art pass.
## Presentation only.

const COLOR := Color(0.35, 0.75, 1.0)
const RADIUS := Vector2(30, 46)

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var points := PackedVector2Array()
	for i in 33:
		var angle := TAU * i / 32.0
		points.append(Vector2(cos(angle) * RADIUS.x, sin(angle) * RADIUS.y - RADIUS.y + 6.0))
	draw_colored_polygon(points, Color(COLOR, 0.12 + 0.08 * pulse))
	draw_polyline(points, Color(COLOR, 0.6 + 0.3 * pulse), 1.5)
