class_name Bodies
extends RefCounted
## Solid footprints on the street floor: fighters, NPCs and street furniture
## (lamp posts, poles, bins, crates, parked vehicles) cannot walk through each
## other. Each body is an ellipse on the ground plane (x along the street, y
## into the lane) around its feet; a solid marked "box" (a parked car) is a
## rectangle instead, so nobody slips past its corners. Pure functions, shared
## with the server.

## Half extents of a standing person's footprint.
const PERSON := Vector2(9.0, 4.0)


## How far apart two footprints are: below 1.0 they overlap.
static func separation(a: Vector2, a_half: Vector2, b: Vector2, b_half: Vector2) -> float:
	var reach := a_half + b_half
	var d := (b - a) / reach
	return d.length()


## How far a body of `half` at `at` is from `solid` ({"position", "half",
## optional "box"}): below 1.0 they overlap.
static func gap(at: Vector2, half: Vector2, solid: Dictionary) -> float:
	if not solid.get("box", false):
		return separation(at, half, solid["position"], solid["half"])
	var d: Vector2 = ((solid["position"] as Vector2) - at).abs() / (half + solid["half"])
	return maxf(d.x, d.y)


## True when a body of `half` may step from `from` to `to` without walking
## into any of `solids` ({"position", "half"}). Stepping out of an overlap it
## already has (after a spawn or a shove) is allowed, never further in.
static func can_step(from: Vector2, to: Vector2, half: Vector2, solids: Array) -> bool:
	return blocker(from, to, half, solids).is_empty()


## The first of `solids` that blocks the step, or {}.
static func blocker(from: Vector2, to: Vector2, half: Vector2, solids: Array) -> Dictionary:
	for solid: Dictionary in solids:
		var ahead := gap(to, half, solid)
		if ahead < 1.0 and ahead < gap(from, half, solid):
			return solid
	return {}


## `at` moved sideways along the street just clear of any solid it lands in,
## so a dropped item or a spawn never sits inside a lamp post.
static func clear_spot(at: Vector2, solids: Array, bounds: Rect2) -> Vector2:
	for solid: Dictionary in solids:
		if gap(at, PERSON, solid) >= 1.0:
			continue
		var centre: Vector2 = solid["position"]
		var side := 1.0 if at.x >= centre.x else -1.0
		var x := centre.x + side * (float(solid["half"].x) + PERSON.x + 2.0)
		if x < bounds.position.x or x > bounds.end.x:
			x = centre.x - side * (float(solid["half"].x) + PERSON.x + 2.0)
		at.x = x
	return LaneMovement.clamp_to(at, bounds)
