class_name BossMechanics
extends RefCounted
## What a boss does beyond its own blows, read from its enemies.json entry:
## * "hazard": calls something down on the hero's spot every so often (a
##   container off a crane, a steam vent bursting, a laser sweeping the whole
##   lane at the hero's depth). It warns first, then hits every fighter in
##   its footprint ("half": half its width and depth) but the boss, the
##   boss's own crew included;
## * "summon": whistles in reinforcements every so often, one from each side
##   of the fight, while fewer than its "max" helpers stand.
## A phase may quicken either ("hazard_every", "summon_every"). Both stop the
## moment the boss is down. The zone is passed in on every call rather than
## kept, so the two never hold each other. Pure rules, shared with the server.

var _hazard_timer := 0
var _summon_timer := 0


## Advances the boss of `zone` one tick, appending what happened to `events`.
func tick(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	_land_hazards(zone, events)
	var boss := zone.fighter(zone.boss_id) if zone.boss_id != 0 else null
	if boss == null or boss.is_ko() or zone.hero.is_ko():
		_hazard_timer = 0
		_summon_timer = 0
		return
	var data := zone.content.enemy(boss.kind)
	var hazard: Dictionary = data.get("hazard", {})
	if hazard:
		_hazard_timer += 1
		if _hazard_timer >= _every(zone, boss, hazard, "hazard_every"):
			_hazard_timer = 0
			_call_hazard(zone, boss, hazard, events)
	var summon: Dictionary = data.get("summon", {})
	if summon:
		_summon_timer += 1
		if _summon_timer >= _every(zone, boss, summon, "summon_every"):
			_summon_timer = 0
			_summon(zone, boss, summon, events)


## How often (in ticks) `spec` fires for `boss` in its current phase.
func _every(zone: ZoneSim, boss: Fighter, spec: Dictionary, phase_key: String) -> int:
	var every := int(spec["every"])
	var done := zone.phase_of(boss.id)
	if done > 0:
		var phases: Array = zone.content.enemy(boss.kind).get("phases", [])
		every = int(phases[done - 1].get(phase_key, every))
	return every


func _call_hazard(zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array[ZoneEvent]) -> void:
	var drop := {
		"at": zone.hero.position,
		"ticks": int(data["warn"]),
		"half": Vector2(data["half"][0], data["half"][1]),
		"damage": roundi(float(data["damage"]) * boss.power),
		"kind": str(data.get("kind", "crane")),
	}
	zone.hazards.append(drop)
	events.append(
		ZoneEvent.make(
			"hazard_warn",
			{"at": drop["at"], "ticks": drop["ticks"], "kind": drop["kind"], "half": drop["half"]}
		)
	)


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
