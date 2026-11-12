class_name HazardShapes
extends RefCounted
## The outlines a hazard warning is drawn from (HazardView): plain geometry,
## kept apart so the view stays readable. Presentation only.


## `area` grown by `grow` px with corners rounded by the same radius (the
## Minkowski sum with a disc): every point of `area` lies inside it. Points
## about every 2 px along it.
static func rounded(area: Rect2, grow: float, along := true) -> PackedVector2Array:
	var radius := maxf(grow, 0.5)
	var inner := area.grow(grow - radius)
	var points := PackedVector2Array()
	var centres := [
		Vector2(inner.end.x, inner.position.y),
		inner.end,
		Vector2(inner.position.x, inner.end.y),
		inner.position,
	]
	var start := [-PI / 2.0, 0.0, PI / 2.0, PI]
	for c in 4:
		var a: Vector2 = centres[c]
		var b: Vector2 = centres[(c + 1) % 4]
		for k in 4:
			var angle: float = start[c] + PI / 2.0 * k / 3.0
			points.append(a + Vector2(cos(angle), sin(angle)) * radius)
		var corner_end: Vector2 = points[points.size() - 1]
		var next_start: Vector2 = (
			b + Vector2(cos(start[(c + 1) % 4]), sin(start[(c + 1) % 4])) * radius
		)
		var length := corner_end.distance_to(next_start)
		# Points along the straight edge only when asked (the seam wanders on them).
		var steps := int(length / 2.0) if along else 0
		for k in range(1, steps):
			points.append(corner_end.lerp(next_start, float(k) / steps))
	points.append(points[0])
	return points
