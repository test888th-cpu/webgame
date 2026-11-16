class_name BossMechanics
extends RefCounted
## What a boss does beyond its own blows, read from its enemies.json entry:
## * "hazard": calls something down on the hero's spot every so often (a
##   container off a crane, a steam vent bursting, a laser sweeping the whole
##   lane at the hero's depth, the floor plates shocking, a "quake" splitting
##   the street across its whole depth at the hero's spot, so the answer is a
##   step along the street, not across it, or a "rain" of slag, rivets or
##   debris: many small drops scattered around the hero). It warns first,
##   then hits every fighter in its footprint ("half": half its width and
##   depth) but the boss, the boss's own crew included. A volley ("count",
##   default 1) drops the first on the hero and the rest at random spots
##   within "spread" ([x, y]) of them, never stacked on one another, landing
##   "stagger" ticks apart: the hero must read the shadows and run, not just
##   side-step. A "cycle" of hazards is called in turn;
## * "summon": whistles in reinforcements every so often, one from each side
##   of the fight, while fewer than its "max" helpers stand.
## * "elite_summon" (optional, same shape plus "below", a share of the boss's
##   health under which it starts): elite reinforcements on their own timer
##   and their own cap. With both, each counts only its own kind, so one
##   never crowds out the other. Caps are how many stand at once (a load
##   limit), never a limit on fights or entries; at the cap the call waits
##   for room, and nobody standing is removed to make it.
##   It reuses an existing elite (its own enemies.json entry: stats, skills,
##   AI, loot), spawned like any other enemy; missing, empty or malformed data
##   means no elites (elite_spec).
## Reinforcements arrive at the fight's edges, in turn. In a world boss arena
## (SessionRules.WORLD_BOSS) one never arrives within SUMMON_CLEARANCE of the
## hero: it comes in from the other edge instead. Everywhere else (story
## bosses and mini-bosses, lairs) the edges alternate as they always have.
## * "enrage": a fight timer (BossEnrage) after which the boss hits harder and
##   its hazards and summons come quicker, warned a few seconds before.
## A phase may quicken either ("hazard_every", "summon_every"), bring its own
## hazards ("hazard"; {} for none), and raise a "shield": for "up" ticks the
## boss is untouchable and stands back while the hazards run, then for "down"
## ticks the system resets, the hazards stop and the boss can be hit, in a
## rhythm the player can read. Everything stops the moment the boss is down.
## The zone is passed in on every call rather than kept, so the two never
## hold each other. Pure rules, shared with the server.

const KINDS: Array[String] = ["crane", "steam", "laser", "shock", "sludge", "quake", "rain"]
## Random spots a volley tries for each extra drop before giving it up.
const VOLLEY_TRIES := 12

## A boss whose quarry has run this far off (pixels along the street)
## strides to catch up: at least CATCH_UP times the hero's own walk, so a hero
## cannot simply outrun a slow boss and leave it calling skills from afar.
const CATCH_UP_FROM := 150.0
const CATCH_UP := 1.15
## How close (px along the street) to the hero a world boss's reinforcement
## may arrive: any closer and it comes in from the other edge.
const SUMMON_CLEARANCE := 60.0

## The boss's own skills (BossSkills): combos, casts and their cleanup.
var skills := BossSkills.new()
var _hazard_timer := 0
var _hazard_turn := 0
## Counts hazard waves called, so each wave's drops share an id.
var _wave := 0
## Counts hazards called: each drop's own id, carried on its hazard_warn,
## hazard_hit and hazard_cancel events, so the warning drawn for it is the one
## that lands or goes (never another's, whatever order they land in).
var _drop_id := 0
## The boss's own walking speed (its kind, level and phase) and the speed this
## class last gave it, so a phase change is noticed and not overwritten.
var _walk_speed := 0.0
var _set_walk := -1.0
var _summon_timer := 0
var _elite_timer := 0
var _shield_timer := 0
var _shield_up := false
var _rage_id := 0
var _rage_ticks := 0


## True while the boss's shield is up (see the class comment).
func shield_up() -> bool:
	return _shield_up


## Advances the boss of `zone` one tick, appending what happened to `events`.
func tick(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	# Skills first: a boss that fell or left this tick takes its waiting
	# hazards with it before they could land.
	skills.tick(zone, self, events)
	_land_hazards(zone, events)
	var boss := zone.fighter(zone.boss_id) if zone.boss_id != 0 else null
	if boss == null or boss.is_ko() or zone.hero.is_ko():
		_hazard_timer = 0
		_summon_timer = 0
		_elite_timer = 0
		_set_shield(zone, boss, false, events)
		return
	_tick_enrage(zone, boss, events)
	_catch_up(zone, boss)
	var phase := _phase(zone, boss)
	var running := true
	var shield: Dictionary = phase.get("shield", {})
	if shield:
		running = _tick_shield(zone, boss, shield, events)
	else:
		_set_shield(zone, boss, false, events)
	var data := zone.content.enemy(boss.kind)
	var hazard: Dictionary = phase.get("hazard", data.get("hazard", {}))
	# While an Ultimate is channelled its waves are the only hazards called.
	if hazard and running and not skills.channeling():
		_hazard_timer += 1
		if _hazard_timer >= BossEnrage.paced(boss, int(phase.get("hazard_every", hazard["every"]))):
			_hazard_timer = 0
			var cycle: Array = hazard.get("cycle", [hazard])
			_call_hazard(zone, boss, cycle[_hazard_turn % cycle.size()], events)
			_hazard_turn += 1
	var summon: Dictionary = data.get("summon", {})
	var elite := elite_spec(zone.content, data)
	if summon and not skills.channeling():
		_summon_timer += 1
		if _summon_timer >= _every(zone, boss, summon, "summon_every"):
			_summon_timer = 0
			_summon(zone, boss, summon, events, str(elite.get("enemy", "")))
	var below := float(elite.get("below", 1.0))
	if elite and not skills.channeling() and boss.hp <= boss.max_hp * below:
		_elite_timer += 1
		if _elite_timer >= _every(zone, boss, elite, "elite_summon_every"):
			_elite_timer = 0
			_summon(zone, boss, elite, events, "", true)


## Lets `boss` stride after a hero who has run off (CATCH_UP_FROM), and walk
## at its own pace again once close.
func _catch_up(zone: ZoneSim, boss: Fighter) -> void:
	if not is_equal_approx(boss.speed, _set_walk):
		_walk_speed = boss.speed
	var far := absf(zone.hero.position.x - boss.position.x) > CATCH_UP_FROM
	var hero_walk := zone.hero.speed * zone.hero.weapon_speed
	var stride := maxf(_walk_speed, hero_walk * CATCH_UP / maxf(boss.weapon_speed, 0.01))
	boss.speed = stride if far else _walk_speed
	_set_walk = boss.speed


## The fight timer of a boss with "enrage": a warning, then the enrage.
func _tick_enrage(zone: ZoneSim, boss: Fighter, events: Array[ZoneEvent]) -> void:
	var spec: Dictionary = zone.content.enemy(boss.kind).get("enrage", {})
	if spec.is_empty():
		return
	if boss.id != _rage_id:
		_rage_id = boss.id
		_rage_ticks = 0
	_rage_ticks += 1
	var times := BossEnrage.fight_ticks(spec)
	if _rage_ticks == int(times["warn"]) and times["warn"] < times["at"]:
		var seconds := roundi(float(spec["warn_seconds"]))
		events.append(ZoneEvent.make("boss_enrage_warn", {"id": boss.id, "seconds": seconds}))
	if _rage_ticks == int(times["at"]):
		BossEnrage.apply(boss, spec)
		events.append(ZoneEvent.make("boss_enrage", {"id": boss.id}))


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
	return BossEnrage.paced(boss, every)


## Calls hazard `data` down for `boss` (a skill's cast; see _call_hazard).
func call_hazard(zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array) -> void:
	_call_hazard(zone, boss, data, events)


## Calls in helpers `data` for `boss` (a skill's cast; see _summon).
func summon(zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array) -> void:
	_summon(zone, boss, data, events)


func _call_hazard(zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array) -> void:
	var half := Vector2(data["half"][0], data["half"][1])
	var spots := placed(zone, boss, data) if data.has("offsets") else volley(zone, data, half)
	# One call is one wave: a fighter it catches is hit once, however many of
	# its tiles touch them (_land_hazards).
	_wave += 1
	for i in spots.size():
		_drop_id += 1
		var drop := {
			"id": _drop_id,
			"at": spots[i],
			"ticks": int(data["warn"]) + i * int(data.get("stagger", 0)),
			"half": half,
			"damage": roundi(float(data["damage"]) * boss.power),
			"kind": str(data.get("kind", "crane")),
			"wave": _wave,
			# The skill that called it ("" for the boss's own hazard cycle).
			"from": str(data.get("from", "")),
		}
		zone.hazards.append(drop)
		var warn := {
			"id": drop["id"], "at": drop["at"], "ticks": drop["ticks"], "kind": drop["kind"]
		}
		warn["half"] = half
		events.append(ZoneEvent.make("hazard_warn", warn))


## Where a laid-out wave (`data` "offsets": [[dx, dy]], an Ultimate's) lands:
## each offset from "origin" ("boss": mirrored to the boss's facing, so a
## pattern points at the hero; "hero": on the hero), kept inside the fight,
## once each.
static func placed(zone: ZoneSim, boss: Fighter, data: Dictionary) -> Array[Vector2]:
	var on_boss := str(data.get("origin", "boss")) == "boss"
	var origin := boss.position if on_boss else zone.hero.position
	var facing := float(boss.facing) if on_boss else 1.0
	var room := zone.arena if zone.arena.size.x > 0.0 else zone.bounds
	var spots: Array[Vector2] = []
	for offset: Variant in data["offsets"]:
		var at := origin + Vector2(float(offset[0]) * facing, float(offset[1]))
		at = LaneMovement.clamp_to(at, room)
		if at not in spots:
			spots.append(at)
	return spots


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
	# Fighter id + wave: who a wave has already hit this tick.
	var struck := {}
	for drop: Dictionary in zone.hazards.duplicate():
		drop["ticks"] -= 1
		if drop["ticks"] > 0:
			continue
		zone.hazards.erase(drop)
		var at: Vector2 = drop["at"]
		var half: Vector2 = drop["half"]
		var landed := {"id": int(drop.get("id", 0)), "at": at, "kind": drop["kind"]}
		events.append(ZoneEvent.make("hazard_hit", landed))
		for f in zone.fighters:
			var gap := (f.position - at).abs()
			if f.id == zone.boss_id or not CombatRules.is_vulnerable(f):
				continue
			if gap.x > half.x or gap.y > half.y:
				continue
			var key := "%d:%d" % [f.id, int(drop.get("wave", 0))]
			if struck.has(key):
				continue
			struck[key] = true
			var hit := CombatRules.thrown_hit(
				f, zone.boss_id, at.x, int(drop["damage"]), true, str(drop["kind"])
			)
			zone.apply_hit(hit, f, events)


## Reinforcements: up to "count" of "enemy", one from each edge of the fight
## in turn, never past "max" helpers on their feet at once. `skip`: a kind not
## counted against the cap (the other category's); `own`: count only "enemy".
func _summon(
	zone: ZoneSim, boss: Fighter, data: Dictionary, events: Array, skip := "", own := false
) -> void:
	var kind := str(data["enemy"])
	var standing := 0
	for enemy in zone.enemies():
		if enemy == boss or enemy.is_ko() or not zone.brains.has(enemy.id):
			continue
		if enemy.kind == skip or (own and enemy.kind != kind):
			continue
		standing += 1
	var room := mini(int(data["count"]), int(data["max"]) - standing)
	if room <= 0:
		return
	var called: Array[int] = []
	var world := SessionRules.session_type(zone.content, zone.area_id) == SessionRules.WORLD_BOSS
	for i in room:
		var west := i % 2 == 0
		var x := zone.arena.position.x + 12.0 if west else zone.arena.end.x - 12.0
		if world and absf(x - zone.hero.position.x) < SUMMON_CLEARANCE:
			x = zone.arena.end.x - 12.0 if west else zone.arena.position.x + 12.0
		var y := zone.arena.position.y + 15.0 + (i % 3) * 30.0
		var at := Bodies.clear_spot(Vector2(x, y), zone.solids, zone.arena)
		var enemy := zone.spawn_enemy(kind, at)
		called.append(enemy.id)
		events.append(ZoneEvent.make("spawn", {"id": enemy.id, "kind": kind, "boss": false}))
	# "elite": a world boss called in an existing elite, for the HUD to announce
	# once per call (GameFeedback). Presentation only: nothing above changes.
	var elite := world and bool(zone.content.enemy(kind).get("elite", false))
	events.append(
		ZoneEvent.make("boss_summon", {"id": boss.id, "kind": kind, "ids": called, "elite": elite})
	)


## `data`'s (an enemies.json entry) "elite_summon" when it is usable, else {}:
## an object naming an existing elite, with "every", "count" and "max" of at
## least 1 and "below" (default 1.0) in (0, 1]. Anything else (missing, empty,
## malformed) calls no elites, and summon_problems says why.
static func elite_spec(content: ContentDB, data: Dictionary) -> Dictionary:
	var spec: Variant = data.get("elite_summon", {})
	if not spec is Dictionary or spec.is_empty():
		return {}
	if not content.enemy(str(spec.get("enemy", ""))).get("elite", false):
		return {}
	for field in ["every", "count", "max"]:
		var value: Variant = spec.get(field)
		if not (value is int or value is float) or int(value) < 1:
			return {}
	var below: Variant = spec.get("below", 1.0)
	if not (below is int or below is float) or below <= 0.0 or below > 1.0:
		return {}
	return spec


## What is wrong with the bosses' "elite_summon", one message each: like
## "summon" (a known enemy, "every", "count", "max" at least 1), and the enemy
## is an elite; "below" a share in (0, 1].
static func summon_problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for kind: String in content.enemies:
		var spec: Variant = content.enemy(kind).get("elite_summon", {})
		var where := "enemies.%s.elite_summon" % kind
		if not spec is Dictionary:
			out.append(where + ": an object")
			continue
		if spec.is_empty():
			continue
		if not content.enemy(kind).get("boss", false):
			out.append(where + ": only bosses call reinforcements")
		if not content.enemy(str(spec.get("enemy", ""))).get("elite", false):
			out.append(where + ".enemy: an elite enemy")
		for field in ["every", "count", "max"]:
			var value: Variant = spec.get(field)
			if not (value is int or value is float) or int(value) < 1:
				out.append("%s.%s: at least 1" % [where, field])
		var below: Variant = spec.get("below", 1.0)
		if not (below is int or below is float) or below <= 0.0 or below > 1.0:
			out.append(where + ".below: a share of health in (0, 1]")
	return out
