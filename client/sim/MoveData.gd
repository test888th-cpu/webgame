class_name MoveData
extends RefCounted
## One attack, as plain data. Timings are in simulation ticks (60 per second).
## Built only through MoveLibrary, which validates every field.

var id := ""
## Ticks before the hitbox appears, while it is live, and after it closes.
var startup := 1
var active := 1
var recovery := 1
var damage := 0
## Ticks the defender cannot act after being hit.
var hitstun := 0
## Total distance in pixels the defender is pushed away.
var knockback := 0.0
## Hitbox in front of the attacker: starts `reach_offset` px ahead, extends
## `reach` px, and hits defenders within `depth_tolerance` px of lane depth.
var reach_offset := 0.0
var reach := 0.0
var depth_tolerance := 0.0
var energy_cost := 0.0
## Ignores guard entirely.
var guard_break := false
## Leaves the defender on the ground (and briefly invulnerable).
var knockdown := false
## Moves this one can be cancelled into once it has landed a hit.
## Keyed by input ("light" / "heavy").
var chains := {}


func total_ticks() -> int:
	return startup + active + recovery


func is_active_tick(tick: int) -> bool:
	return tick >= startup and tick < startup + active
