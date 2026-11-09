class_name BossMechanics
extends RefCounted
## What a boss does beyond its own blows, read from its enemies.json entry:
## * "hazard": calls something down on the hero's spot every so often (a
##   container off a crane, a steam vent bursting, a laser sweeping the whole
##   lane at the hero's depth, the floor plates shocking). It warns first,
##   then hits every fighter in its footprint ("half": half its width and
##   depth) but the boss, the boss's own crew included. A volley ("count",
##   default 1) drops the first on the hero and the rest at random spots
##   within "spread" ([x, y]) of them, never stacked on one another, landing
##   "stagger" ticks apart: the hero must read the shadows and run, not just
##   side-step. A "cycle" of hazards is called in turn;
## * "summon": whistles in reinforcements every so often, one from each side
##   of the fight, while fewer than its "max" helpers stand.
## A phase may quicken either ("hazard_every", "summon_every"), bring its own
## hazards ("hazard"; {} for none), and raise a "shield": for "up" ticks the
## boss is untouchable and stands back while the hazards run, then for "down"
## ticks the system resets, the hazards stop and the boss can be hit, in a
## rhythm the player can read. Everything stops the moment the boss is down.
## The zone is passed in on every call rather than kept, so the two never
## hold each other. Pure rules, shared with the server.

const KINDS: Array[String] = ["crane", "steam", "laser", "shock", "sludge"]
## Random spots a volley tries for each extra drop before giving it up.
const VOLLEY_TRIES := 12

var _hazard_timer := 0
var _hazard_turn := 0
var _summon_timer := 0
var _shield_timer := 0
var _shield_up := false


## True while the boss's shield is up (see the class comment).
func shield_up() -> bool:
	return _shield_up


## Advances the boss of `zone` one tick, appending what happened to `events`.
func tick(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	_land_hazards(zone, events)
	var boss := zone.fighter(zone.boss_id) if zone.boss_id != 0 else null
	if boss == null or boss.is_ko() or zone.hero.is_ko():
		_hazard_timer = 0
		_summon_timer = 0
		_set_shield(zone, boss, false, events)
		return
	var phase := _phase(zone, boss)
	var running := true
	var shield: Dictionary = phase.get("shield", {})
	if shield:
		running = _tick_shield(zone, boss, shield, events)
	else:
		_set_shield(zone, boss, false, events)
	var data := zone.content.enemy(boss.kind)
	var hazard: Dictionary = phase.get("hazard", data.get("hazard", {}))
	if hazard and running:
		_hazard_timer += 1
		if _hazard_timer >= int(phase.get("hazard_every", hazard["every"])):
			_hazard_timer = 0
			var cycle: Array = hazard.get("cycle", [hazard])
			_call_hazard(zone, boss, cycle[_hazard_turn % cycle.size()], events)
			_hazard_turn += 1
	var summon: Dictionary = data.get("summon", {})
	if summon:
		_summon_timer += 1
		if _summon_timer >= _every(zone, boss, summon, "summon_every"):
			_summon_timer = 0
			_summon(zone, boss, summon, events)


## The phase `boss` is in ({} before its first).
func _phase(zone: ZoneSim, boss: Fighter) -> Dictionary:
	var done := zone.phase_of(boss.id)
	if done == 0:
		return {}
	return zone.content.enemy(boss.kind).get("phases", [])[done - 1]


## The shield's rhythm: up (untouchable, standing back) then down (open).
## Returns true while it is up, when the hazards run.
func _tick_shield(
	zone: ZoneSim, boss: Fighter, shield: Dictionary, events: Array[ZoneEvent]
) -> bool:
	_shield_timer += 1
	if not _shield_up and (_shield_timer == 1 or _shield_timer > int(shield["down"])):
		_set_shield(zone, boss, true, events)
	elif _shield_up and _shield_timer > int(shield["up"]):
		_set_shield(zone, boss, false, events)
	if _shield_up:
		boss.grace = maxi(boss.grace, 2)
		var brain: EnemyBrain = zone.brains.get(boss.id)
		if brain:
			brain.cooldown = maxi(brain.cooldown, 30)
	return _shield_up


func _set_shield(zone: ZoneSim, boss: Fighter, up: bool, events: Array[ZoneEvent]) -> void:
	if up == _shield_up:
		return
	_shield_up = up
	_shield_timer = 1
	if not up:
		_hazard_timer = 0
	var id := boss.id if boss else zone.boss_id
	events.append(ZoneEvent.make("boss_shield", {"id": id, "up": up}))


## How often (in ticks) `spec` fires for `boss` in its current phase.
func _every(zone: ZoneSim, boss: Fighter, spec: Dictionary, phase_key: String) -> int:
	var every := int(spec["every"])
	var done := zone.phase_of(boss.id)
	if done > 0:
		var phases: Array = zone.content.enemy(boss.kind).get("phases", [])
		every = int(phases[done - 1].get(phase_key, every))
	return every


func _call_hazard(zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array[ZoneEvent]) -> void:
	var half := Vector2(data["half"][0], data["half"][1])
	var spots := volley(zone, data, half)
	for i in spots.size():
		var drop := {
			"at": spots[i],
			"ticks": int(data["warn"]) + i * int(data.get("stagger", 0)),
			"half": half,
			"damage": roundi(float(data["damage"]) * boss.power),
			"kind": str(data.get("kind", "crane")),
		}
		zone.hazards.append(drop)
		var warn := {"at": drop["at"], "ticks": drop["ticks"], "kind": drop["kind"], "half": half}
		events.append(ZoneEvent.make("hazard_warn", warn))


## Where a volley of `data` lands: on the hero first, then up to "count" - 1
## spots within "spread" of them, inside the fight and clear of each other
## (a spot that would overlap another is rolled again, and dropped if no
## room is found), so there is always somewhere to run.
static func volley(zone: ZoneSim, data: Dictionary, half: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = [zone.hero.position]
	var spread: Array = data.get("spread", [0, 0])
	var room := zone.arena if zone.arena.size.x > 0.0 else zone.bounds
	for i in int(data.get("count", 1)) - 1:
		for _try in VOLLEY_TRIES:
			var at := (
				zone.hero.position
				+ Vector2(
					zone.rng.randf_range(-float(spread[0]), float(spread[0])),
					zone.rng.randf_range(-float(spread[1]), float(spread[1]))
				)
			)
			at = LaneMovement.clamp_to(at, room)
			var clear := true
			for other in spots:
				var gap := (other - at).abs()
				clear = clear and (gap.x >= half.x * 1.6 or gap.y >= half.y * 1.6)
			if clear:
				spots.append(at)
				break
	return spots


## Hazards whose warning has run out land on whoever stands there.
func _land_hazards(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	for drop: Dictionary in zone.hazards.duplicate():
		drop["ticks"] -= 1
		if drop["ticks"] > 0:
			continue
		zone.hazards.erase(drop)
		var at: Vector2 = drop["at"]
		var half: Vector2 = drop["half"]
		events.append(ZoneEvent.make("hazard_hit", {"at": at, "kind": drop["kind"]}))
		for f in zone.fighters:
			var gap := (f.position - at).abs()
			if f.id == zone.boss_id or not CombatRules.is_vulnerable(f):
				continue
			if gap.x > half.x or gap.y > half.y:
				continue
			var hit := CombatRules.thrown_hit(
				f, zone.boss_id, at.x, int(drop["damage"]), true, str(drop["kind"])
			)
			zone.apply_hit(hit, f, events)


## Reinforcements: up to "count" of "enemy", one from each edge of the fight
## in turn, never past "max" helpers on their feet at once.
func _summon(zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array[ZoneEvent]) -> void:
	var standing := 0
	for enemy in zone.enemies():
		if enemy != boss and not enemy.is_ko() and zone.brains.has(enemy.id):
			standing += 1
	var room := mini(int(data["count"]), int(data["max"]) - standing)
	if room <= 0:
		return
	var kind := str(data["enemy"])
	var called: Array[int] = []
	for i in room:
		var x := zone.arena.position.x + 12.0 if i % 2 == 0 else zone.arena.end.x - 12.0
		var y := zone.arena.position.y + 15.0 + (i % 3) * 30.0
		var at := Bodies.clear_spot(Vector2(x, y), zone.solids, zone.arena)
		var enemy := zone.spawn_enemy(kind, at)
		called.append(enemy.id)
		events.append(ZoneEvent.make("spawn", {"id": enemy.id, "kind": kind, "boss": false}))
	events.append(ZoneEvent.make("boss_summon", {"id": boss.id, "kind": kind, "ids": called}))
