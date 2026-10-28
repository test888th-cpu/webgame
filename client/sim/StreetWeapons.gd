class_name StreetWeapons
extends RefCounted
## Where the weapons scattered on a street lie: somewhere the hero can stand
## on them and pick them up. Pure rules, shared with the server.

## Room a weapon's spot keeps from every solid (1.0 is touching).
const ROOM := 1.2
## Random spots tried before a weapon is left out.
const TRIES := 24


## A random spot in `bounds`: off every solid with room to spare, and
## ZoneSim.NPC_CLEARANCE from every NPC (near one, E talks instead). A spot
## that fails is rolled again; Vector2.INF when none is found.
static func spot(rng: RandomNumberGenerator, bounds: Rect2, solids: Array, npcs: Array) -> Vector2:
	for _try in TRIES:
		var at := Vector2(
			rng.randf_range(bounds.position.x + 160.0, bounds.end.x - 40.0),
			rng.randf_range(bounds.position.y + 6.0, bounds.end.y - 6.0)
		)
		at = Bodies.clear_spot(at, solids, bounds)
		if Bodies.is_clear(at, solids, bounds, ROOM) and not near_npc(at, npcs):
			return at
	return Vector2.INF


static func near_npc(at: Vector2, npcs: Array) -> bool:
	for npc: Dictionary in npcs:
		if absf(at.x - float(npc["x"])) < ZoneSim.NPC_CLEARANCE:
			return true
	return false
