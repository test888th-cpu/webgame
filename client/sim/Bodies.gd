class_name Bodies
extends RefCounted
## Solid footprints on the street floor: fighters, NPCs and street furniture
## (lamp posts, poles, bins, crates) cannot walk through each other. Each body
## is an ellipse on the ground plane (x along the street, y into the lane)
## around its feet. Pure functions, shared with the server.

## Half extents of a standing person's footprint.
const PERSON := Vector2(9.0, 4.0)


## How far apart two footprints are: below 1.0 they overlap.
static func separation(a: Vector2, a_half: Vector2, b: Vector2, b_half: Vector2) -> float:
	var reach := a_half + b_half
	var d := (b - a) / reach
	return d.length()


## True when a body of `half` may step from `from` to `to` without walking
## into any of `solids` ({"position", "half"}). Stepping out of an overlap it
## already has (after a spawn or a shove) is allowed, never further in.
static func can_step(from: Vector2, to: Vector2, half: Vector2, solids: Array) -> bool:
	return blocker(from, to, half, solids).is_empty()


## The first of `solids` that blocks the step, or {}.
static func blocker(from: Vector2, to: Vector2, half: Vector2, solids: Array) -> Dictionary:
	for solid: Dictionary in solids:
		var gap := separation(to, half, solid["position"], solid["half"])
		if gap < 1.0 and gap < separation(from, half, solid["position"], solid["half"]):
			return solid
	return {}


## `at` moved sideways along the street just clear of any solid it lands in,
## so a dropped item or a spawn never sits inside a lamp post.
static func clear_spot(at: Vector2, solids: Array, bounds: Rect2) -> Vector2:
	for solid: Dictionary in solids:
		if separation(at, PERSON, solid["position"], solid["half"]) >= 1.0:
			continue
		var centre: Vector2 = solid["position"]
		var side := 1.0 if at.x >= centre.x else -1.0
		var x := centre.x + side * (float(solid["half"].x) + PERSON.x + 2.0)
		if x < bounds.position.x or x > bounds.end.x:
			x = centre.x - side * (float(solid["half"].x) + PERSON.x + 2.0)
		at.x = x
	return LaneMovement.clamp_to(at, bounds)
