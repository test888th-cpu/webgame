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


func _init(
	p_content: ContentDB, p_profile: PlayerProfile, p_area_id: String, entry := "", seed := 0
) -> void:
	content = p_content
	profile = p_profile
	area_id = p_area_id
	area = content.area(area_id)
	rng.seed = seed
	var width := float(area.get("width", 960))
	bounds = Rect2(EDGE_MARGIN, LANE_TOP, width - EDGE_MARGIN * 2.0, LANE_DEPTH)
	arena = bounds
	var start := Vector2(120.0, 300.0)
	if entry == "west":
		start.x = bounds.position.x + 24.0
	elif entry == "east":
		start.x = bounds.end.x - 24.0
	hero = Fighter.new(HERO_ID, HERO_TEAM, start, 100)
	hero.kind = "hero"
	hero.facing = -1 if entry == "east" else 1
	if area.get("heal_on_enter", false):
		profile.hp = profile.stats(content)["max_hp"]
	refresh_hero()
	fighters.append(hero)
	for placed: Dictionary in area.get("placed", []):
		var enemy := spawn_enemy(str(placed["enemy"]), Vector2(placed["x"], placed["y"]))
		_home[enemy.id] = enemy.position
	for encounter: Dictionary in area.get("encounters", []):
		_encounters.append({"data": encounter, "state": "pending"})


## Applies profile stats (level, equipment) to the hero fighter.
func refresh_hero() -> void:
	var stats := profile.stats(content)
	hero.max_hp = stats["max_hp"]
	hero.power = stats["power"]
	hero.defense = stats["defense"]
	hero.hp = clampi(profile.hp, 1, hero.max_hp)
	profile.hp = hero.hp
	hero.speed = stats["speed"]
	hero.skills = SkillRules.unlocked(content, profile.hero, profile.level)


func spawn_enemy(kind: String, position: Vector2) -> Fighter:
	var data := content.enemy(kind)
	var enemy := Fighter.new(_next_id, ENEMY_TEAM, position, int(data["max_hp"]))
	_next_id += 1
	enemy.kind = kind
	enemy.moveset = data.get("moveset", {}).duplicate()
	enemy.power = float(data.get("power", 1.0))
	enemy.defense = int(data.get("defense", 0))
	enemy.speed = float(data.get("speed", 1.0))
	enemy.facing = -1 if hero.position.x < position.x else 1
	fighters.append(enemy)
	if data.get("ai") != null:
		brains[enemy.id] = EnemyBrain.new(data["ai"], rng)
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


## Advances the zone one tick. Returns everything that happened.
func tick(hero_input: FighterInput) -> Array[ZoneEvent]:
	tick_count += 1
	item_cooldown = maxi(0, item_cooldown - 1)
	var events: Array[ZoneEvent] = []
	_update_encounter(events)
	var inputs := {HERO_ID: hero_input}
	var allowed := _attack_tokens()
	for id: int in brains:
		var enemy := fighter(id)
		if enemy and not enemy.is_ko():
			inputs[id] = brains[id].think(enemy, hero, allowed.has(id), content.moves, rng)
	for hit in CombatRules.tick(fighters, inputs, content.moves, arena):
		var event := ZoneEvent.make("hit")
		event.hit = hit
		events.append(event)
		var defender := fighter(hit.defender_id)
		if defender == hero:
			profile.hp = hero.hp
		if hit.ko:
			if defender == hero:
				_hero_down(events)
			else:
				_defeat(defender, events)
	_report_actions(events)
	_check_phases(events)
	_separate_crowd()
	_update_downed(events)
	_collect_pickups(events)
	_check_exit(hero_input, events)
	return events


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
	var enemy := spawn_enemy(kind, Vector2(x, y))
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
	var levels := profile.add_xp(int(data.get("xp", 0)), content)
	var loot := LootRules.roll(data.get("loot", {}), rng)
	if loot["money"] > 0:
		_drop({"kind": "money", "amount": loot["money"]}, enemy.position)
	for item_id: String in loot["items"]:
		_drop({"kind": "item", "item": item_id, "amount": 1}, enemy.position)
	events.append(
		ZoneEvent.make(
			"defeat",
			{
				"id": enemy.id,
				"kind": enemy.kind,
				"xp": int(data.get("xp", 0)),
				"boss": enemy.id == boss_id
			}
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
	pickup["position"] = LaneMovement.clamp_to(at + scatter, bounds)
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
			brain.planned = ""
		events.append(ZoneEvent.make("boss_phase", {"id": enemy.id, "phase": done + 1}))


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
			a.position = LaneMovement.clamp_to(a.position - Vector2(push * dir, 0), arena)
			b.position = LaneMovement.clamp_to(b.position + Vector2(push * dir, 0), arena)


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


func _check_exit(input: FighterInput, events: Array[ZoneEvent]) -> void:
	if in_encounter() or hero.is_ko():
		return
	var exits: Dictionary = area.get("exits", {})
	var side := ""
	if input.move.x < 0.0 and hero.position.x <= bounds.position.x + 0.5:
		side = "west"
	elif input.move.x > 0.0 and hero.position.x >= bounds.end.x - 0.5:
		side = "east"
	if side and exits.has(side):
		events.append(ZoneEvent.make("exit", exits[side].duplicate()))
