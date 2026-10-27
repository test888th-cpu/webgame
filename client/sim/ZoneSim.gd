class_name ZoneSim
extends RefCounted
## One zone instance: the hero, its enemies, encounters, loot on the ground and
## exits, advanced one fixed tick at a time. Everything that decides an
## outcome lives here (spawns, AI, hits, rewards, quest progress), so in
## Milestone 3 the zone server runs this class and clients only render it.
## Nothing here touches nodes, input devices or the clock.

const HERO_ID := 1
const HERO_TEAM := 1
const ENEMY_TEAM := 2

## Street lane: y from LANE_TOP to LANE_TOP + LANE_DEPTH.
const LANE_TOP := 250.0
const LANE_DEPTH := 90.0
const EDGE_MARGIN := 16.0

## At most this many enemies attack the hero at once (bosses ignore it).
const MAX_ATTACKERS := 2
const SPAWN_INTERVAL := 40
const CORPSE_TICKS := 90
## Enemies closer than this along the street (in the same lane) push apart.
const CROWD_GAP := 18.0
const PICKUP_REACH := Vector2(16.0, 12.0)
## How close a fighter must stand to pick up a weapon from the street.
const WEAPON_REACH := Vector2(18.0, 12.0)
## Oldest weapons on the street vanish beyond this many.
const MAX_GROUND_WEAPONS := 10
## Weapons are never scattered closer than this to an NPC (along the street).
const NPC_CLEARANCE := 40.0
## Throwing the held weapon: the wind-up move, then the weapon flies straight
## along the street at THROW_SPEED px per tick for up to THROW_TICKS ticks
## and hits the first foe it meets within THROW_REACH.
const THROW_MOVE := "weapon_throw"
const LOCKED_BUMP_TICKS := 90
const THROW_SPEED := 5.0
const THROW_TICKS := 32
const THROW_REACH := Vector2(12.0, 14.0)

var content: ContentDB
var profile: PlayerProfile
var area_id := ""
var area: Dictionary
var rng := RandomNumberGenerator.new()
## The whole street, and the part currently walkable (locked during fights).
var bounds: Rect2
var arena: Rect2
var hero: Fighter
var fighters: Array[Fighter] = []
var brains := {}
var pickups: Array[Dictionary] = []
var tick_count := 0
## Id of the boss in the current fight, 0 if none.
var boss_id := 0
## Ticks until the hero may use another consumable.
var item_cooldown := 0
## The area's difficulty level (enemies scale with it; see LevelRules).
var level := 1
## Weapons lying on the street: {id, weapon, position, uses}.
var ground_weapons: Array[Dictionary] = []
## What stands on the street and blocks walking: the area's street furniture
## and its NPCs, as {"position", "half", "kind"} (see Bodies). Fighters block
## each other too, added as they stand each tick.
var solids: Array[Dictionary] = []
## Weapons in flight: {id, weapon, uses, owner, team, position, dir, ticks,
## damage}. They land as ground weapons (or break) when they hit or stop.
var thrown: Array[Dictionary] = []
## Hazards on their way: {"at": Vector2, "ticks": left, "half": Vector2,
## "damage": int, "kind": "crane" | "steam"}. A boss with "hazard" in
## enemies.json calls one on the hero's spot every so often (a container off
## a crane, a steam vent bursting); it warns first, then hits every fighter
## there but the boss, the boss's own crew included.
var hazards: Array[Dictionary] = []
var _hazard_timer := 0
var _next_weapon := 1
## Where each fighter stood before this tick's movement.
var _before := {}
## Each enemy's level and money multiplier, by id.
var _enemy_level := {}

var _encounters: Array[Dictionary] = []
var _active := -1
var _waves_left: Array = []
var _spawn_queue: Array = []
var _spawn_timer := 0
var _spawn_side := 0
var _next_id := 100
var _next_pickup := 1
var _down_ticks := {}
var _home := {}
var _phase := {}
var _hero_down_sent := false
## Tick of the hero's last push on a locked exit (to tell them once per bump).
var _last_locked_bump := -1000


## `start_x` (if not negative) places the hero along the street instead of at
## the `entry` side: where a knocked-out hero comes to (see respawn_x).
func _init(
	p_content: ContentDB,
	p_profile: PlayerProfile,
	p_area_id: String,
	entry := "",
	seed := 0,
	start_x := -1.0
) -> void:
	content = p_content
	profile = p_profile
	area_id = p_area_id
	area = content.area(area_id)
	level = int(area.get("level", 1))
	rng.seed = seed
	var width := float(area.get("width", 960))
	bounds = Rect2(EDGE_MARGIN, LANE_TOP, width - EDGE_MARGIN * 2.0, LANE_DEPTH)
	arena = bounds
	_build_solids()
	var start := Vector2(120.0, 300.0)
	if entry == "west":
		start.x = bounds.position.x + 24.0
	elif entry == "east":
		start.x = bounds.end.x - 24.0
	if start_x >= 0.0:
		start.x = clampf(start_x, bounds.position.x, bounds.end.x)
	hero = Fighter.new(HERO_ID, HERO_TEAM, Bodies.clear_spot(start, solids, bounds), 100)
	hero.kind = "hero"
	hero.stun_limit = CombatRules.HERO_STUN_LIMIT
	hero.can_parry = true
	var hero_data := content.hero(profile.hero)
	hero.parry_window = int(hero_data.get("parry_window", CombatRules.PERFECT_GUARD_TICKS))
	hero.skill_armor = bool(hero_data.get("skill_armor", false))
	hero.throws = true
	hero.facing = -1 if entry == "east" else 1
	if area.get("heal_on_enter", false):
		profile.hp = profile.stats(content)["max_hp"]
		StreetMemory.rest(profile)
	StreetMemory.visit(profile, area_id)
	refresh_hero()
	fighters.append(hero)
	for placed: Dictionary in area.get("placed", []):
		var enemy := spawn_enemy(str(placed["enemy"]), Vector2(placed["x"], placed["y"]))
		_home[enemy.id] = enemy.position
	var pending := StreetMemory.pending(profile, content, area_id)
	var encounters: Array = area.get("encounters", [])
	for i in encounters.size():
		_encounters.append(
			{"data": encounters[i], "state": "pending" if i in pending else "cleared"}
		)
	_scatter_weapons()


## Where a hero knocked out now comes to in this area: just short of the boss
## fight they lost, to try again at once; otherwise at the area's west end
## (fights already won stay won, see StreetMemory).
func respawn_x() -> float:
	if _active >= 0 and boss_id != 0:
		return float(_encounters[_active]["data"]["arena"][0]) + 16.0
	return bounds.position.x + 24.0


## Applies profile stats (level, equipment) to the hero fighter.
func refresh_hero() -> void:
	var stats := profile.stats(content)
	hero.max_hp = stats["max_hp"]
	hero.power = stats["power"]
	hero.defense = stats["defense"]
	hero.hp = clampi(profile.hp, 1, hero.max_hp)
	profile.hp = hero.hp
	hero.speed = stats["speed"]
	hero.crit_chance = stats["crit"]
	hero.attack_speed = stats["attack_speed"]
	hero.skills = SkillRules.unlocked(content, profile.hero, profile.level)


func spawn_enemy(kind: String, position: Vector2) -> Fighter:
	var data := content.enemy(kind)
	var enemy_level := LevelRules.enemy_level(data, level)
	var stats := LevelRules.enemy_stats(data, enemy_level)
	var enemy := Fighter.new(_next_id, ENEMY_TEAM, position, stats["max_hp"])
	_next_id += 1
	enemy.kind = kind
	enemy.moveset = data.get("moveset", {}).duplicate()
	enemy.power = stats["power"]
	enemy.defense = stats["defense"]
	enemy.speed = stats["speed"]
	enemy.poise_limit = int(data.get("poise", 0))
	enemy.facing = -1 if hero.position.x < position.x else 1
	fighters.append(enemy)
	_enemy_level[enemy.id] = {"level": enemy_level, "stats": stats}
	if data.get("ai") != null:
		var has_heavy := enemy.moveset.has("heavy")
		var ai := LevelRules.enemy_ai(data["ai"], enemy_level, has_heavy)
		# Only enemies that can hold a weapon (wields) go and fetch one.
		ai["scavenge"] = ai["scavenge"] and data.get("wields", false)
		brains[enemy.id] = EnemyBrain.new(ai, rng)
	if rng.randf() < LevelRules.armed_chance(data, enemy_level):
		var weapon_id := LevelRules.roll_weapon(content.weapons, enemy_level, rng)
		if weapon_id:
			equip_weapon(enemy, weapon_id, int(content.weapons[weapon_id]["durability"]))
	if data.get("boss", false):
		boss_id = enemy.id
	return enemy


func fighter(id: int) -> Fighter:
	for f in fighters:
		if f.id == id:
			return f
	return null


func enemies() -> Array[Fighter]:
	var result: Array[Fighter] = []
	for f in fighters:
		if f.team == ENEMY_TEAM:
			result.append(f)
	return result


func in_encounter() -> bool:
	return _active >= 0


## Why the hero cannot go straight home to the start area right now (the
## pause menu's "Return to Depot Yard"), or "" when they can: never in the
## middle of a fight, so it is no escape from one.
func recall_problem() -> String:
	if area_id == content.start_area:
		return "You are already there."
	if in_encounter():
		return "Finish this fight first."
	if hero.is_ko() or hero.state == Fighter.State.DOWN:
		return "Get back on your feet first."
	return ""


## Advances the zone one tick. Returns everything that happened.
func tick(hero_input: FighterInput) -> Array[ZoneEvent]:
	tick_count += 1
	item_cooldown = maxi(0, item_cooldown - 1)
	var events: Array[ZoneEvent] = []
	_update_encounter(events)
	_before.clear()
	for f in fighters:
		_before[f.id] = f.position
	var inputs := {HERO_ID: hero_input}
	var allowed := _attack_tokens()
	for id: int in brains:
		var enemy := fighter(id)
		if enemy and not enemy.is_ko():
			inputs[id] = brains[id].think(
				enemy,
				hero,
				allowed.has(id),
				content.moves,
				rng,
				_nearest_weapon(enemy.position),
				tick_count
			)
	for id: int in inputs:
		if inputs[id].pick:
			_pick_or_drop(fighter(id), events)
	for hit in CombatRules.tick(fighters, inputs, content.moves, arena, _resolve_bodies, rng):
		var event := ZoneEvent.make("hit")
		event.hit = hit
		events.append(event)
		var defender := fighter(hit.defender_id)
		if defender == hero:
			profile.hp = hero.hp
		_wear_weapon(fighter(hit.attacker_id), hit, events)
		_after_hit(hit, defender, events)
	_release_throws(events)
	_fly_thrown(events)
	_drop_hazards(events)
	_report_actions(events)
	_check_phases(events)
	_separate_crowd()
	_update_downed(events)
	_collect_pickups(events)
	_check_exit(hero_input, events)
	return events


## What follows any hit: a fighter knocked off their feet loses their grip,
## and a KO ends the hero's run or defeats the enemy.
func _after_hit(hit: CombatEvent, defender: Fighter, events: Array[ZoneEvent]) -> void:
	if (hit.knocked_down or hit.ko) and defender.weapon:
		var behind := Vector2(signf(defender.position.x - hit.position.x) * 14.0, 4.0)
		_drop_weapon(defender, defender.position + behind, events)
	if hit.ko:
		if defender == hero:
			_hero_down(events)
		else:
			_defeat(defender, events)


## Throwers whose wind-up just ended let go: the weapon leaves the hand and
## flies. Damage is the weapon's heavy blow at the thrower's power, fixed now.
func _release_throws(events: Array[ZoneEvent]) -> void:
	for f in fighters:
		if f.state != Fighter.State.ATTACK or f.state_tick != f.move.startup:
			continue
		var ranged: Dictionary = content.enemy(f.kind).get("ranged", {})
		if ranged and f.move.id == str(ranged["move"]):
			_lob(f, ranged, events)
			continue
		if f.move.id != THROW_MOVE or f.weapon == "":
			continue
		var heavy := content.moves.get_move(str(f.weapon_moveset.get("heavy", "")))
		var base := heavy.damage if heavy else 10
		var entry := {
			"id": _next_weapon,
			"weapon": f.weapon,
			"uses": f.weapon_uses,
			"owner": f.id,
			"team": f.team,
			"position": f.position + Vector2(f.facing * 12.0, 0.0),
			"dir": f.facing,
			"ticks": THROW_TICKS,
			"damage": roundi(base * f.power),
			"knockdown": true,
		}
		_next_weapon += 1
		thrown.append(entry)
		events.append(ZoneEvent.make("weapon_throw", {"id": f.id, "weapon": f.weapon}))
		_clear_weapon(f)


func _drop_hazards(events: Array[ZoneEvent]) -> void:
	for drop: Dictionary in hazards.duplicate():
		drop["ticks"] -= 1
		if drop["ticks"] > 0:
			continue
		hazards.erase(drop)
		var at: Vector2 = drop["at"]
		var half: Vector2 = drop["half"]
		events.append(ZoneEvent.make("hazard_hit", {"at": at, "kind": drop["kind"]}))
		for f in fighters:
			var gap := (f.position - at).abs()
			if f.id == boss_id or not CombatRules.is_vulnerable(f):
				continue
			if gap.x > half.x or gap.y > half.y:
				continue
			var hit := CombatRules.thrown_hit(
				f, boss_id, at.x, int(drop["damage"]), true, str(drop["kind"])
			)
			var event := ZoneEvent.make("hit")
			event.hit = hit
			events.append(event)
			if f == hero:
				profile.hp = hero.hp
			_after_hit(hit, f, events)
	var boss := fighter(boss_id) if boss_id != 0 else null
	if boss == null or boss.is_ko() or hero.is_ko():
		_hazard_timer = 0
		return
	var data: Dictionary = content.enemy(boss.kind).get("hazard", {})
	if data.is_empty():
		return
	_hazard_timer += 1
	var every := int(data["every"])
	var phases: Array = content.enemy(boss.kind).get("phases", [])
	var done := int(_phase.get(boss.id, 0))
	if done > 0:
		every = int(phases[done - 1].get("hazard_every", every))
	if _hazard_timer < every:
		return
	_hazard_timer = 0
	var drop := {
		"at": hero.position,
		"ticks": int(data["warn"]),
		"half": Vector2(data["half"][0], data["half"][1]),
		"damage": roundi(float(data["damage"]) * boss.power),
		"kind": str(data.get("kind", "crane")),
	}
	hazards.append(drop)
	events.append(
		ZoneEvent.make(
			"hazard_warn", {"at": drop["at"], "ticks": drop["ticks"], "kind": drop["kind"]}
		)
	)


## A ranged enemy's lob: a fresh projectile (it has endless bottles) that
## stuns rather than floors and shatters wherever it lands.
func _lob(f: Fighter, ranged: Dictionary, events: Array[ZoneEvent]) -> void:
	(
		thrown
		. append(
			{
				"id": _next_weapon,
				"weapon": str(ranged["projectile"]),
				"uses": 0,
				"owner": f.id,
				"team": f.team,
				"position": f.position + Vector2(f.facing * 12.0, 0.0),
				"dir": f.facing,
				"ticks": THROW_TICKS,
				"damage": roundi(float(ranged["damage"]) * f.power),
				"knockdown": false,
			}
		)
	)
	_next_weapon += 1
	events.append(ZoneEvent.make("weapon_throw", {"id": f.id, "weapon": str(ranged["projectile"])}))


## Moves weapons in flight; each hits the first foe in reach, then lands at
## their feet (or breaks when that blow was its last), or lands where it
## runs out of range or reaches the edge of the fight.
func _fly_thrown(events: Array[ZoneEvent]) -> void:
	for entry: Dictionary in thrown.duplicate():
		var at: Vector2 = entry["position"] + Vector2(entry["dir"] * THROW_SPEED, 0.0)
		entry["position"] = at
		entry["ticks"] -= 1
		var target := _thrown_target(entry)
		if target:
			var boss := bool(content.enemy(target.kind).get("boss", false))
			var hit := (
				CombatRules
				. thrown_hit(
					target,
					int(entry["owner"]),
					at.x - entry["dir"] * THROW_SPEED,
					int(entry["damage"]),
					# A thrown pipe stuns a boss but never floors one.
					bool(entry.get("knockdown", true)) and not boss,
					"thrown_" + str(entry["weapon"])
				)
			)
			var event := ZoneEvent.make("hit")
			event.hit = hit
			events.append(event)
			if target == hero:
				profile.hp = hero.hp
			_after_hit(hit, target, events)
			entry["uses"] -= 1
			_land_thrown(entry, target.position - Vector2(entry["dir"] * 12.0, -4.0), events)
		elif entry["ticks"] <= 0 or at.x <= arena.position.x or at.x >= arena.end.x:
			_land_thrown(entry, LaneMovement.clamp_to(at, arena), events)


func _thrown_target(entry: Dictionary) -> Fighter:
	for f in fighters:
		if f.team == int(entry["team"]) or not CombatRules.is_vulnerable(f):
			continue
		var gap: Vector2 = (f.position - entry["position"]).abs()
		if gap.x <= THROW_REACH.x and gap.y <= THROW_REACH.y:
			return f
	return null


func _land_thrown(entry: Dictionary, at: Vector2, events: Array[ZoneEvent]) -> void:
	thrown.erase(entry)
	var weapon := str(entry["weapon"])
	if int(entry["uses"]) <= 0:
		var material := str(content.weapons[weapon].get("material", "wood"))
		var data := {"id": entry["owner"], "weapon": weapon, "at": at, "material": material}
		events.append(ZoneEvent.make("weapon_break", data))
		return
	var ground := place_weapon(weapon, at, int(entry["uses"]))
	events.append(
		ZoneEvent.make(
			"weapon_drop",
			{"id": entry["owner"], "weapon": weapon, "ground": ground["id"], "at": at}
		)
	)


## Gives `f` the weapon `weapon_id` with `uses` hits left.
func equip_weapon(f: Fighter, weapon_id: String, uses: int) -> void:
	var weapon: Dictionary = content.weapons[weapon_id]
	f.weapon = weapon_id
	f.weapon_uses = uses
	f.weapon_moveset = weapon["moveset"].duplicate()
	f.weapon_speed = float(weapon.get("speed", 1.0))


## Puts a weapon on the street (oldest ones vanish past the limit).
func place_weapon(weapon_id: String, at: Vector2, uses: int) -> Dictionary:
	var entry := {
		"id": _next_weapon,
		"weapon": weapon_id,
		"position": Bodies.clear_spot(at, solids, bounds),
		"uses": uses,
	}
	_next_weapon += 1
	ground_weapons.append(entry)
	while ground_weapons.size() > MAX_GROUND_WEAPONS:
		ground_weapons.pop_front()
	return entry


func _clear_weapon(f: Fighter) -> void:
	f.weapon = ""
	f.weapon_uses = 0
	f.weapon_moveset = {}
	f.weapon_speed = 1.0


func _drop_weapon(f: Fighter, at: Vector2, events: Array[ZoneEvent]) -> void:
	var entry := place_weapon(f.weapon, at, f.weapon_uses)
	events.append(
		ZoneEvent.make(
			"weapon_drop", {"id": f.id, "weapon": f.weapon, "ground": entry["id"], "at": at}
		)
	)
	_clear_weapon(f)


## The pick button: take the weapon underfoot (dropping any held one in its
## place), or put the held weapon down if there is nothing to take.
func _pick_or_drop(f: Fighter, events: Array[ZoneEvent]) -> void:
	if f == null or f.state != Fighter.State.IDLE:
		return
	var found := weapon_in_reach(f.position)
	if found < 0:
		if f.weapon and f.throws:
			CombatRules.start_move(f, content.moves.get_move(THROW_MOVE))
		elif f.weapon:
			_drop_weapon(f, f.position + Vector2(f.facing * 10.0, 2.0), events)
		return
	var entry: Dictionary = ground_weapons[found]
	ground_weapons.remove_at(found)
	if f.weapon:
		_drop_weapon(f, f.position, events)
	equip_weapon(f, entry["weapon"], int(entry["uses"]))
	events.append(
		ZoneEvent.make(
			"weapon_pickup", {"id": f.id, "weapon": entry["weapon"], "ground": entry["id"]}
		)
	)


## Every landed weapon blow (not skills or fists) uses the weapon up.
func _wear_weapon(attacker: Fighter, hit: CombatEvent, events: Array[ZoneEvent]) -> void:
	if attacker == null or attacker.weapon == "":
		return
	if not _weapon_moves(attacker.weapon_moveset).has(hit.move_id):
		return
	attacker.weapon_uses -= 1
	if attacker.weapon_uses > 0:
		return
	var weapon := attacker.weapon
	var material := str(content.weapons[weapon].get("material", "wood"))
	_clear_weapon(attacker)
	var data := {"id": attacker.id, "weapon": weapon, "at": attacker.position, "material": material}
	events.append(ZoneEvent.make("weapon_break", data))


## Every move a weapon's moveset can reach, its chains included.
func _weapon_moves(moveset: Dictionary) -> Dictionary:
	var found := {}
	var queue: Array = moveset.values()
	while not queue.is_empty():
		var move_id: String = queue.pop_back()
		if found.has(move_id):
			continue
		found[move_id] = true
		var move := content.moves.get_move(move_id)
		if move:
			queue.append_array(move.chains.values())
	return found


## Puts back the weapons left on this street earlier (replacing the fresh
## scatter), so what was dropped is still there on return.
func restore_weapons(entries: Array) -> void:
	ground_weapons.assign(entries.duplicate(true))
	for entry in ground_weapons:
		_next_weapon = maxi(_next_weapon, int(entry["id"]) + 1)


## Index in ground_weapons of the closest weapon within reach of `at`, or -1.
func weapon_in_reach(at: Vector2) -> int:
	var found := -1
	var best := INF
	for i in ground_weapons.size():
		var offset: Vector2 = ground_weapons[i]["position"] - at
		if absf(offset.x) <= WEAPON_REACH.x and absf(offset.y) <= WEAPON_REACH.y:
			if offset.length() < best:
				best = offset.length()
				found = i
	return found


func _nearest_weapon(from: Vector2) -> Vector2:
	var best := Vector2.INF
	for entry: Dictionary in ground_weapons:
		var at: Vector2 = entry["position"]
		if best == Vector2.INF or at.distance_to(from) < best.distance_to(from):
			best = at
	return best


## Weapons lying around a street at the start, from the area's "weapons"
## block: how many and which (by weight, limited by the area's level).
func _scatter_weapons() -> void:
	var spec: Dictionary = area.get("weapons", {})
	if spec.is_empty():
		return
	var count := rng.randi_range(int(spec["count"][0]), int(spec["count"][1]))
	for i in count:
		var weapon_id := LevelRules.roll_weapon(content.weapons, level, rng, spec.get("pool", {}))
		if weapon_id == "":
			continue
		var at := Vector2(
			rng.randf_range(bounds.position.x + 160.0, bounds.end.x - 40.0),
			rng.randf_range(bounds.position.y + 6.0, bounds.end.y - 6.0)
		)
		# Not at a shopkeeper's feet, where E talks instead of picking up.
		for npc: Dictionary in area.get("npcs", []):
			if absf(at.x - float(npc["x"])) < NPC_CLEARANCE:
				at.x += NPC_CLEARANCE * 2.0
		place_weapon(weapon_id, at, int(content.weapons[weapon_id]["durability"]))


## The level an enemy fights at (for its label), 0 if unknown.
func enemy_level(id: int) -> int:
	return int(_enemy_level.get(id, {}).get("level", 0))


## Uses a consumable from the inventory on the hero. Consumables share a
## short cooldown so healing cannot be spammed mid-combo.
func use_item(item_id: String) -> bool:
	if item_cooldown > 0 or hero.is_ko():
		return false
	if not profile.use_item(item_id, hero, content):
		return false
	item_cooldown = content.item_cooldown
	return true


## Reports attacks, skills and dodges that began this tick (for sounds and
## effects; they change nothing).
func _report_actions(events: Array[ZoneEvent]) -> void:
	for f in fighters:
		if f.state_tick != 0:
			continue
		if f.state == Fighter.State.ATTACK:
			var data := {"id": f.id, "move": f.move.id, "skill": ""}
			for skill_id: String in f.skills:
				if f.skills[skill_id]["move"] == f.move.id:
					data["skill"] = skill_id
			events.append(ZoneEvent.make("swing", data))
		elif f.state == Fighter.State.DODGE:
			events.append(ZoneEvent.make("dodge", {"id": f.id}))


func _attack_tokens() -> Dictionary:
	var allowed := {}
	var attacking := 0
	var ready: Array[Fighter] = []
	for enemy in enemies():
		if enemy.is_ko() or not brains.has(enemy.id):
			continue
		if enemy.state == Fighter.State.ATTACK:
			attacking += 1
		elif content.enemy(enemy.kind).get("boss", false):
			allowed[enemy.id] = true
		elif brains[enemy.id].wants_attack():
			ready.append(enemy)
	ready.sort_custom(
		func(a: Fighter, b: Fighter) -> bool:
			var da := absf(a.position.x - hero.position.x)
			var db := absf(b.position.x - hero.position.x)
			return da < db if da != db else a.id < b.id
	)
	for enemy in ready:
		if attacking >= MAX_ATTACKERS:
			break
		allowed[enemy.id] = true
		attacking += 1
	return allowed


func _update_encounter(events: Array[ZoneEvent]) -> void:
	if _active < 0:
		for i in _encounters.size():
			var entry := _encounters[i]
			if entry["state"] == "pending" and hero.position.x >= float(entry["data"]["trigger_x"]):
				_start_encounter(i, events)
				return
		return
	var data: Dictionary = _encounters[_active]["data"]
	var alive := 0
	for id: int in brains:
		var enemy := fighter(id)
		if enemy and not enemy.is_ko():
			alive += 1
	if not _spawn_queue.is_empty():
		_spawn_timer -= 1
		if alive < int(data["max_alive"]) and _spawn_timer <= 0:
			_spawn_next(events)
	elif alive == 0:
		if not _waves_left.is_empty():
			_spawn_queue = _waves_left.pop_front()
			_spawn_timer = SPAWN_INTERVAL
			events.append(ZoneEvent.make("wave", {"remaining": _waves_left.size()}))
		else:
			_encounters[_active]["state"] = "cleared"
			StreetMemory.mark_cleared(profile, area_id, _active)
			_active = -1
			boss_id = 0
			arena = bounds
			events.append(ZoneEvent.make("encounter_clear"))


func _start_encounter(index: int, events: Array[ZoneEvent]) -> void:
	_active = index
	var data: Dictionary = _encounters[index]["data"]
	_encounters[index]["state"] = "active"
	var left := maxf(bounds.position.x, float(data["arena"][0]))
	var right := minf(bounds.end.x, float(data["arena"][1]))
	arena = Rect2(left, LANE_TOP, right - left, LANE_DEPTH)
	_waves_left = data["waves"].duplicate(true)
	_spawn_queue = _waves_left.pop_front()
	_spawn_timer = 0
	var has_boss := false
	for wave: Array in data["waves"]:
		for kind: String in wave:
			has_boss = has_boss or content.enemy(kind).get("boss", false)
	events.append(ZoneEvent.make("encounter_start", {"arena": arena, "boss": has_boss}))


func _spawn_next(events: Array[ZoneEvent]) -> void:
	var kind: String = _spawn_queue.pop_front()
	# Alternate sides so the hero is flanked, entering just inside the arena.
	_spawn_side = 1 - _spawn_side
	var x := arena.position.x + 12.0 if _spawn_side == 0 else arena.end.x - 12.0
	var y := rng.randf_range(arena.position.y + 10.0, arena.end.y - 10.0)
	var enemy := spawn_enemy(kind, Bodies.clear_spot(Vector2(x, y), solids, arena))
	_spawn_timer = SPAWN_INTERVAL
	events.append(
		ZoneEvent.make("spawn", {"id": enemy.id, "kind": kind, "boss": enemy.id == boss_id})
	)


func _defeat(enemy: Fighter, events: Array[ZoneEvent]) -> void:
	var data := content.enemy(enemy.kind)
	_down_ticks[enemy.id] = 0
	if data.get("training", false):
		return
	profile.defeated[enemy.kind] = int(profile.defeated.get(enemy.kind, 0)) + 1
	var scaled: Dictionary = _enemy_level.get(enemy.id, {}).get("stats", {})
	var xp := int(scaled.get("xp", data.get("xp", 0)))
	xp = roundi(xp * LevelRules.xp_scale(enemy_level(enemy.id), profile.level))
	var levels := profile.add_xp(xp, content)
	var loot := LootRules.roll(data.get("loot", {}), rng)
	var money := roundi(loot["money"] * float(scaled.get("money_scale", 1.0)))
	if money > 0:
		_drop({"kind": "money", "amount": money}, enemy.position)
	for item_id: String in loot["items"]:
		_drop({"kind": "item", "item": item_id, "amount": 1}, enemy.position)
	events.append(
		ZoneEvent.make(
			"defeat", {"id": enemy.id, "kind": enemy.kind, "xp": xp, "boss": enemy.id == boss_id}
		)
	)
	if levels > 0:
		refresh_hero()
		hero.hp = hero.max_hp
		profile.hp = hero.hp
		var unlocked: Array[String] = []
		for level in range(profile.level - levels + 1, profile.level + 1):
			unlocked.append_array(SkillRules.unlocked_at(content, profile.hero, level))
		events.append(ZoneEvent.make("level_up", {"level": profile.level, "skills": unlocked}))
	for quest_id in QuestRules.on_defeat(profile, enemy.kind, content):
		events.append(ZoneEvent.make("quest_complete", {"quest": quest_id}))


func _drop(pickup: Dictionary, at: Vector2) -> void:
	pickup["id"] = _next_pickup
	_next_pickup += 1
	var scatter := Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-8.0, 8.0))
	pickup["position"] = Bodies.clear_spot(at + scatter, solids, bounds)
	# Where it dropped from, so views can show it flying out of the enemy.
	pickup["from"] = at
	pickups.append(pickup)


func _hero_down(events: Array[ZoneEvent]) -> void:
	if _hero_down_sent:
		return
	_hero_down_sent = true
	events.append(ZoneEvent.make("hero_down"))


func _check_phases(events: Array[ZoneEvent]) -> void:
	for enemy in enemies():
		var phases: Array = content.enemy(enemy.kind).get("phases", [])
		var done := int(_phase.get(enemy.id, 0))
		if enemy.is_ko() or done >= phases.size():
			continue
		var phase: Dictionary = phases[done]
		if float(enemy.hp) / enemy.max_hp >= float(phase["below"]):
			continue
		_phase[enemy.id] = done + 1
		enemy.speed = float(phase.get("speed", enemy.speed))
		enemy.power = float(phase.get("power", enemy.power))
		if phase.has("moveset"):
			enemy.moveset = phase["moveset"].duplicate()
		if brains.has(enemy.id):
			var brain: EnemyBrain = brains[enemy.id]
			brain.cooldown_ticks = int(phase.get("cooldown", brain.cooldown_ticks))
			brain.heavy_chance = float(phase.get("heavy_chance", brain.heavy_chance))
			brain.heavy_cooldown_ticks = int(
				phase.get("heavy_cooldown", brain.heavy_cooldown_ticks)
			)
			brain.planned = ""
		events.append(ZoneEvent.make("boss_phase", {"id": enemy.id, "phase": done + 1}))


func _build_solids() -> void:
	for obstacle: Dictionary in area.get("obstacles", []):
		var kind: Dictionary = content.obstacles.get(str(obstacle["kind"]), {})
		var half: Array = kind.get("half", [6, 3])
		(
			solids
			. append(
				{
					"position": Vector2(obstacle["x"], obstacle["y"]),
					"half": Vector2(half[0], half[1]),
					"kind": str(obstacle["kind"]),
					"box": bool(kind.get("box", false)),
				}
			)
		)
	for npc: Dictionary in area.get("npcs", []):
		solids.append(
			{"position": Vector2(npc["x"], npc["y"]), "half": Bodies.PERSON, "kind": "npc"}
		)


## Called by CombatRules after everyone has moved, before blows are judged:
## undoes or trims any step into street furniture, an NPC or another fighter.
## A step at an angle slides along what it hit; an enemy walking straight into
## something steps around it, so it still reaches the hero. The hero has to
## walk around by itself.
func _resolve_bodies() -> void:
	for f in fighters:
		var from: Vector2 = _before.get(f.id, f.position)
		if f.is_ko() or f.position == from:
			continue
		var others := _solids_for(f)
		var to := f.position
		if Bodies.can_step(from, to, Bodies.PERSON, others):
			continue
		var along := Vector2(to.x, from.y)
		var across := Vector2(from.x, to.y)
		if along != from and Bodies.can_step(from, along, Bodies.PERSON, others):
			f.position = along
		elif across != from and Bodies.can_step(from, across, Bodies.PERSON, others):
			f.position = across
		else:
			f.position = from
		if f != hero and f.state == Fighter.State.IDLE and f.position.x == from.x:
			f.position = _detour(f, from, to, others)


## What `f` may not walk into: the street's solids and, unless it is reeling
## or down, every fighter still on their feet.
func _solids_for(f: Fighter) -> Array:
	var others: Array = solids.duplicate()
	if f.state == Fighter.State.HITSTUN or f.state == Fighter.State.DOWN:
		return others
	for other in fighters:
		if other != f and not other.is_ko() and other.state != Fighter.State.DOWN:
			others.append(
				{
					"position": other.position,
					"half": Bodies.PERSON,
					"kind": "fighter",
					"id": other.id
				}
			)
	return others


## A sidestep for an enemy blocked while walking along the street: around the
## side it is already on (or towards the hero's side), not into the hero.
func _detour(f: Fighter, from: Vector2, to: Vector2, others: Array) -> Vector2:
	if to.x == from.x:
		return f.position
	var block := Bodies.blocker(from, Vector2(to.x, from.y), Bodies.PERSON, others)
	if block.is_empty() or int(block.get("id", 0)) == HERO_ID:
		return f.position
	var side := signf(from.y - float(block["position"].y))
	if side == 0.0:
		side = 1.0 if hero.position.y >= from.y else -1.0
	var step := LaneMovement.WALK_SPEED_Y * CombatRules.TICK_SECONDS * maxf(f.speed, 0.5)
	for dir: float in [side, -side]:
		var at := LaneMovement.clamp_to(from + Vector2(0, dir * step), arena)
		if at != from and Bodies.can_step(from, at, Bodies.PERSON, others):
			return at
	return f.position


func _separate_crowd() -> void:
	var crowd: Array[Fighter] = []
	for enemy in enemies():
		if not enemy.is_ko():
			crowd.append(enemy)
	for i in crowd.size():
		for j in range(i + 1, crowd.size()):
			var a := crowd[i]
			var b := crowd[j]
			if absf(a.position.y - b.position.y) > 10.0:
				continue
			var gap := b.position.x - a.position.x
			if absf(gap) >= CROWD_GAP:
				continue
			var push := (CROWD_GAP - absf(gap)) * 0.5
			var dir := 1.0 if gap > 0.0 or (gap == 0.0 and b.id > a.id) else -1.0
			_shove(a, a.position - Vector2(push * dir, 0))
			_shove(b, b.position + Vector2(push * dir, 0))


## Moves `f` to `to` unless that would push it into street furniture.
func _shove(f: Fighter, to: Vector2) -> void:
	to = LaneMovement.clamp_to(to, arena)
	if Bodies.can_step(f.position, to, Bodies.PERSON, solids):
		f.position = to


func _update_downed(events: Array[ZoneEvent]) -> void:
	for id: int in _down_ticks.keys():
		var enemy := fighter(id)
		if enemy == null:
			_down_ticks.erase(id)
			continue
		_down_ticks[id] += 1
		var respawn := int(content.enemy(enemy.kind).get("respawn_ticks", 0))
		if respawn > 0 and _home.has(id):
			if _down_ticks[id] >= respawn:
				_down_ticks.erase(id)
				enemy.hp = enemy.max_hp
				enemy.position = _home[id]
				enemy.knockback_remaining = 0.0
				enemy.enter(Fighter.State.IDLE)
		elif _down_ticks[id] >= CORPSE_TICKS:
			_down_ticks.erase(id)
			fighters.erase(enemy)
			brains.erase(id)
			_phase.erase(id)
			_enemy_level.erase(id)
			events.append(ZoneEvent.make("despawn", {"id": id}))


func _collect_pickups(events: Array[ZoneEvent]) -> void:
	if hero.is_ko():
		return
	for pickup in pickups.duplicate():
		var offset: Vector2 = pickup["position"] - hero.position
		if absf(offset.x) > PICKUP_REACH.x or absf(offset.y) > PICKUP_REACH.y:
			continue
		pickups.erase(pickup)
		if pickup["kind"] == "money":
			profile.money += int(pickup["amount"])
		else:
			profile.add_item(pickup["item"], int(pickup["amount"]))
		events.append(ZoneEvent.make("pickup", pickup))


## What still keeps the exit on `side` shut: {"defeat", "count", "hint",
## "done"} (done: how many are down so far), or {} when it is open. Exits
## open once the hero has defeated enough of the enemy that guards them, so
## the street opens as the story moves on, whichever quest is active.
func exit_locked(side: String) -> Dictionary:
	var requires: Dictionary = area.get("exits", {}).get(side, {}).get("requires", {})
	if requires.is_empty():
		return {}
	var done := int(profile.defeated.get(str(requires["defeat"]), 0))
	if done >= int(requires["count"]):
		return {}
	var gate := requires.duplicate()
	gate["done"] = done
	gate["side"] = side
	return gate


func _check_exit(input: FighterInput, events: Array[ZoneEvent]) -> void:
	if in_encounter() or hero.is_ko():
		return
	var exits: Dictionary = area.get("exits", {})
	var side := ""
	if input.move.x < 0.0 and hero.position.x <= bounds.position.x + 0.5:
		side = "west"
	elif input.move.x > 0.0 and hero.position.x >= bounds.end.x - 0.5:
		side = "east"
	if side and exits.has(side) and not exit_locked(side).is_empty():
		# Tell the player once per bump, not every tick they push on it.
		if tick_count - _last_locked_bump > LOCKED_BUMP_TICKS:
			var gate := exit_locked(side)
			events.append(ZoneEvent.make("exit_locked", gate))
		_last_locked_bump = tick_count
	elif side and exits.has(side):
		# Street weapons belong to their street: leaving puts the weapon down.
		if hero.weapon:
			_drop_weapon(hero, hero.position, events)
		events.append(ZoneEvent.make("exit", exits[side].duplicate()))
