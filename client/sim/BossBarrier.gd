class_name BossBarrier
extends RefCounted
## A boss's shield as a solid barrier on the street (BossMechanics raises and
## drops it with the shield phase, enemies.json "phases[].shield"). While it is
## up:
## * its footprint, an ellipse round the boss's feet ("half": [along the
##   street, into the lane]), is a wall for the boss's foes: they cannot walk,
##   dodge or be thrown into it (ZoneSim._solids_for), though one caught
##   inside may always step out;
## * whoever of the boss's foes stands inside when it goes up is thrown out
##   and floored, unhurt; one the barrier reaches later (the boss walking up
##   to them) is shoved out without being floored;
## * its "height" is how tall the dome is drawn, in game pixels, covering the
##   boss's head (tested against the art); the footprint is what blocks, and
##   the dome is drawn to the same numbers.
## The boss's own side passes through it. Pure rules, shared with the server.

## Footprint and height when an enemy's shield names none: a person's dome
## at the enemy's "scale".
const DEFAULT_HALF := Vector2(44.0, 18.0)
const DEFAULT_HEIGHT := 70.0
## How far past the barrier's edge a fighter is thrown, in pixels.
const CLEARANCE := 3.0


## The barrier of `shield` (a phase's "shield") on enemy `kind`:
## {"half": Vector2, "height": float}.
static func size(content: ContentDB, kind: String, shield: Dictionary) -> Dictionary:
	var scale := float(content.enemy(kind).get("scale", 1.0))
	var half := DEFAULT_HALF * scale
	if shield.get("half") is Array and (shield["half"] as Array).size() == 2:
		half = Vector2(float(shield["half"][0]), float(shield["half"][1]))
	return {"half": half, "height": float(shield.get("height", DEFAULT_HEIGHT * scale))}


## Raises (`shield` not empty) or drops (`shield` {}) `boss`'s barrier, and
## keeps it on the boss's feet. On raising, anyone of the boss's foes inside
## is thrown out and floored; while it stays up, shoved out.
static func hold(
	zone: ZoneSim, boss: Fighter, shield: Dictionary, raised: bool, events: Array
) -> void:
	if boss == null:  # the boss gone: its barrier with it
		zone.barriers.clear()
		return
	zone.barriers.assign(
		zone.barriers.filter(func(b: Dictionary) -> bool: return b["id"] != boss.id)
	)
	if shield.is_empty() or boss.is_ko():
		return
	var spec := size(zone.content, boss.kind, shield)
	var barrier := {
		"id": boss.id,
		"team": boss.team,
		"position": boss.position,
		"half": spec["half"],
		"height": spec["height"],
	}
	zone.barriers.append(barrier)
	for f in zone.fighters:
		if f.team == boss.team or f.is_ko():
			continue
		var push := shove(barrier, f.position, zone.walk)
		if push == 0.0:
			continue
		var hit := CombatRules.barrier_shove(f, boss.id, push, raised)
		zone.apply_hit(hit, f, events)


## True when a person at `at` overlaps `barrier`.
static func inside(barrier: Dictionary, at: Vector2) -> bool:
	return Bodies.gap(at, Bodies.PERSON, barrier) < 1.0


## How far along the street a person at `at` must go to be clear of
## `barrier` (signed, away from its centre; towards the other side when the
## street's end `walk` is too close behind them), or 0 when already clear.
static func shove(barrier: Dictionary, at: Vector2, walk: Rect2) -> float:
	if not inside(barrier, at):
		return 0.0
	var centre: Vector2 = barrier["position"]
	var reach: Vector2 = (barrier["half"] as Vector2) + Bodies.PERSON
	var depth := clampf((at.y - centre.y) / reach.y, -1.0, 1.0)
	var clear := reach.x * sqrt(1.0 - depth * depth) + CLEARANCE
	var away := signf(at.x - centre.x)
	if away == 0.0:
		away = -1.0 if at.x < walk.get_center().x else 1.0
	var target := centre.x + away * clear
	if target < walk.position.x or target > walk.end.x:
		target = centre.x - away * clear
	return target - at.x
