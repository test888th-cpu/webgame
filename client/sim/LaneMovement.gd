class_name LaneMovement
extends RefCounted
## Movement rules for a side-scrolling street with depth lanes.
##
## x runs along the street, y is depth into the lane (screen-space, larger is
## nearer the camera). Pure functions with no node or engine-state access, so
## the same rules can run in the browser client (prediction) and in the
## headless zone server (authority) in later milestones.

## Pixels per second along the street.
const WALK_SPEED_X := 120.0
## Depth movement is slower than street movement, as in classic brawlers.
const WALK_SPEED_Y := 70.0
## A single step never integrates more than this, so a frame hitch or a
## backgrounded browser tab cannot teleport an entity.
const MAX_STEP_SECONDS := 0.1


## Returns the new position after applying `input` (each axis in -1..1) for
## `delta` seconds, clamped to `bounds`.
## `speed_scale` is the walker's speed multiplier (enemies differ).
static func step(
	position: Vector2, input: Vector2, delta: float, bounds: Rect2, speed_scale := 1.0
) -> Vector2:
	var dt := clampf(delta, 0.0, MAX_STEP_SECONDS)
	var dir := input.limit_length(1.0) * maxf(0.0, speed_scale)
	return clamp_to(position + Vector2(dir.x * WALK_SPEED_X, dir.y * WALK_SPEED_Y) * dt, bounds)


## Keeps a position inside the walkable street.
static func clamp_to(position: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x),
		clampf(position.y, bounds.position.y, bounds.end.y)
	)


## Facing after an input: +1 right, -1 left, unchanged when there is no
## horizontal input.
static func facing(current: int, input: Vector2) -> int:
	if input.x > 0.0:
		return 1
	if input.x < 0.0:
		return -1
	return current
