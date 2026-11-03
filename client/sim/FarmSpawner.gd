class_name FarmSpawner
extends RefCounted
## A farming ground's living field (areas.json "spawning"): enemies stand in
## camps across the field, as in the field games it follows, and the hero picks
## which to take on.
##
## Each camp (`camps`: the x of each camp's centre) holds `camp_size` enemies,
## there from the moment the hero arrives. They stand at their own spot
## (EnemyBrain.camp) and come only when the hero walks within `aggro` of one of
## them or strikes one; then the whole camp joins in together (social aggro),
## the other camps stay where they are. One chased too far from home (LEASH
## times `aggro`), or out of reach of the hero for a few seconds
## (EnemyBrain.LOST_TICKS), gives up, walks back and is healed there. Each enemy
## that falls comes back to its camp `respawn_ticks` later (give or take
## RESPAWN_JITTER, so a camp does not pop back all at once), once its camp's
## fight is over, on the side of the camp away from the hero: clearing a camp
## earns a breather of a few seconds, then it stands again, so the fighting
## never goes quiet for long. Several heroes in one field (IL-7) each pull the
## camps near them; the rules here are already per camp. Enemies keep east of
## `from_x` less SAFE_MARGIN, so the west end (where the hero arrives and the
## way out) is a safe spot. Who comes is drawn from `pool` ({enemy: weight});
## one in `elite_chance` is an elite: tougher, worth ELITE_REWARD times the XP,
## coins and loot rolls, named in gold, with a chance at the ground's own prizes
## (`elite_drops`, [{item, chance}]: the Epic gear of its district's bosses).
## Nothing locks the hero in and nothing here is saved: leaving and coming back
## starts a fresh field. Rewards are paid where every enemy's are
## (ZoneSim._defeat). Pure rules on ZoneSim's seeded rng, shared with the
## server.

## How far west of `from_x` an enemy may follow the hero (the safe spot is
## west of that line).
const SAFE_MARGIN := 120.0
## How far from a camp's centre its members stand.
const CAMP_SPREAD := 44.0
## Room east of `from_x` a field needs (the validator's check).
const SPAWN_CLEAR := 120.0
## A returning enemy's time back varies by up to this, either way.
const RESPAWN_JITTER := 60
## How far from home (in aggro radii) a camp member chases before giving up.
const LEASH := 2.5
## An elite's toughness and what it is worth, against its plain kind.
const ELITE_HP := 3.0
const ELITE_POWER := 1.25
const ELITE_REWARD := 3.0
const MAX_CAMPS := 8
const MAX_CAMP_SIZE := 6
const MIN_RESPAWN := 30
const MIN_AGGRO := 60.0
const MAX_AGGRO := 400.0
const MAX_ELITE_CHANCE := 0.25

var _started := false
## Camp members standing, by id -> camp index.
var _members := {}
## Enemies on their way back: [camp, tick due], in the order they fell.
var _returning: Array = []
## Elites standing, by id: each pays its extra loot rolls when it falls.
var _elites := {}


## The area's "spawning" block, or {} when the area has none (every story
## area, the city, the world boss arenas).
static func spec(content: ContentDB, area_id: String) -> Dictionary:
	var block: Variant = content.area(area_id).get("spawning", {})
	return block if block is Dictionary else {}


## True when `area_id` is a living field (AutoPilot hunts there).
static func active(content: ContentDB, area_id: String) -> bool:
	return not spec(content, area_id).is_empty()


## How many enemies the field holds when every camp is full.
static func capacity(data: Dictionary) -> int:
	return (data.get("camps", []) as Array).size() * int(data.get("camp_size", 0))


## One step of the field: fills the camps on arrival, wakes a whole camp
## when one of it is, heals one that walked home, and refills camps short of
## enemies when it is time. Does nothing in an area without "spawning".
func tick(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	var data := spec(zone.content, zone.area_id)
	if data.is_empty():
		return
	_pay_elites(zone)
	var west := float(data["from_x"]) - SAFE_MARGIN
	for enemy in zone.enemies():
		if not enemy.is_ko() and zone.brains.has(enemy.id):
			enemy.position.x = maxf(enemy.position.x, west)
	var camps: Array = data["camps"]
	if not _started:
		_started = true
		for camp in camps.size():
			for member in int(data["camp_size"]):
				_spawn(zone, data, events, camp)
		return
	for camp: int in _fallen(zone):
		var back := (
			int(data["respawn_ticks"]) + zone.rng.randi_range(-RESPAWN_JITTER, RESPAWN_JITTER)
		)
		_returning.append([camp, zone.tick_count + maxi(MIN_RESPAWN, back)])
		_returning.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) < int(b[1]))
	var fighting := _wake_and_heal(zone)
	# One whose camp is still fighting waits for that fight to end: a cleared
	# camp comes back together a few seconds later, not into the same fight.
	var calling := {}
	for back: Array in _returning:
		if zone.tick_count >= int(back[1]) and not fighting.has(int(back[0])):
			calling[int(back[0])] = true
	# A calm camp's first one due brings back all it is waiting for, together.
	for back: Array in _returning.duplicate():
		if calling.has(int(back[0])):
			_returning.erase(back)
			_spawn(zone, data, events, int(back[0]))


## The camps of members that fell since the last tick (forgotten here).
func _fallen(zone: ZoneSim) -> Array[int]:
	var camps: Array[int] = []
	for id: int in _members.keys():
		var enemy := zone.fighter(id)
		if enemy == null or enemy.is_ko() or not zone.brains.has(id):
			camps.append(_members[id])
			_members.erase(id)
	return camps


## Wakes a whole camp when one of it is awake, and heals one back home from a
## chase. Returns the camps that are fighting.
func _wake_and_heal(zone: ZoneSim) -> Dictionary:
	var awake := {}
	for id: int in _members:
		var enemy := zone.fighter(id)
		var brain: EnemyBrain = zone.brains[id]
		if brain.engaged:
			awake[_members[id]] = true
		elif brain.returning and enemy.position.distance_to(brain.home) < CAMP_SPREAD:
			# Back among its camp (its exact spot may be taken by a fellow).
			enemy.hp = enemy.max_hp
			brain.returning = false
	for id: int in _members:
		if awake.has(_members[id]):
			(zone.brains[id] as EnemyBrain).engaged = true
	return awake


func _spawn(zone: ZoneSim, data: Dictionary, events: Array[ZoneEvent], camp: int) -> void:
	var kind := _draw(data["pool"], zone.rng)
	var west := maxf(float(data["from_x"]), zone.bounds.position.x + 12.0)
	var centre := float(data["camps"][camp])
	var offset := zone.rng.randf_range(-CAMP_SPREAD, CAMP_SPREAD)
	if absf(zone.hero.position.x - centre) < float(data["aggro"]):
		# The hero is at this camp: come back on its far side.
		offset = signf(centre - zone.hero.position.x + 0.01) * CAMP_SPREAD
	var x := clampf(centre + offset, west, zone.bounds.end.x - 12.0)
	var lane := zone.bounds
	var y := zone.rng.randf_range(lane.position.y + 10.0, lane.end.y - 10.0)
	var enemy := zone.spawn_enemy(kind, Bodies.clear_spot(Vector2(x, y), zone.solids, lane))
	_scale_rewards(zone, enemy, float(data.get("reward_scale", 1.0)))
	var brain: EnemyBrain = zone.brains[enemy.id]
	brain.camp(enemy.position, float(data["aggro"]), float(data["aggro"]) * LEASH)
	_members[enemy.id] = camp
	var elite := zone.rng.randf() < float(data.get("elite_chance", 0.0))
	if elite:
		_make_elite(zone, enemy)
		_elites[enemy.id] = true
	events.append(
		ZoneEvent.make("spawn", {"id": enemy.id, "kind": kind, "boss": false, "elite": elite})
	)


## An elite that fell since the last tick drops ELITE_REWARD - 1 more rolls
## of its kind's loot items (ZoneSim._defeat paid the first; its coins are
## already scaled), so an elite pays materials in step with its XP.
func _pay_elites(zone: ZoneSim) -> void:
	for id: int in _elites.keys():
		var enemy := zone.fighter(id)
		if enemy == null or not enemy.is_ko():
			if enemy == null:
				_elites.erase(id)
			continue
		_elites.erase(id)
		var stats: Dictionary = zone._enemy_level.get(id, {}).get("stats", {})
		var loot: Dictionary = stats.get("loot", zone.content.enemy(enemy.kind).get("loot", {}))
		var prizes := {"drops": spec(zone.content, zone.area_id).get("elite_drops", [])}
		var dropped: Array[String] = LootRules.roll(prizes, zone.rng)["items"]
		for roll in roundi(ELITE_REWARD) - 1:
			dropped.append_array(LootRules.roll(loot, zone.rng)["items"])
		for item_id in dropped:
			zone._drop({"kind": "item", "item": item_id, "amount": 1}, enemy.position)


## An enemy kind drawn from `pool` ({kind: weight}) in its data order.
static func _draw(pool: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for kind: String in pool:
		total += float(pool[kind])
	var roll := rng.randf() * total
	for kind: String in pool:
		roll -= float(pool[kind])
		if roll < 0.0:
			return kind
	return str(pool.keys().back())


## Scales what `enemy` pays (XP, coins and its loot's drop chances) by
## `scale`: a field's enemies come back in seconds, so each is worth less than
## the same enemy met once on the street, and a minute's farming pays what the
## ground is tuned for ("reward_scale", set with the harness).
static func _scale_rewards(zone: ZoneSim, enemy: Fighter, scale: float) -> void:
	if is_equal_approx(scale, 1.0):
		return
	var stats: Dictionary = zone._enemy_level[enemy.id]["stats"]
	stats["xp"] = roundi(float(stats.get("xp", 0)) * scale)
	stats["money_scale"] = float(stats.get("money_scale", 1.0)) * scale
	var loot: Dictionary = zone.content.enemy(enemy.kind).get("loot", {}).duplicate(true)
	for drop: Dictionary in loot.get("drops", []):
		drop["chance"] = float(drop.get("chance", 0.0)) * scale
	stats["loot"] = loot


## Makes `enemy` an elite: tougher and worth ELITE_REWARD times the XP and
## coins its kind gives at its level (ZoneSim._defeat reads the scaled stats).
static func _make_elite(zone: ZoneSim, enemy: Fighter) -> void:
	enemy.elite = true
	enemy.max_hp = roundi(enemy.max_hp * ELITE_HP)
	enemy.hp = enemy.max_hp
	enemy.power *= ELITE_POWER
	# ZoneSim keeps each enemy's scaled stats (_enemy_level) for _defeat to pay
	# from; there is no line left in ZoneSim for an accessor (gdlint's limit).
	var stats: Dictionary = zone._enemy_level[enemy.id]["stats"]
	stats["xp"] = roundi(float(stats.get("xp", 0)) * ELITE_REWARD)
	stats["money_scale"] = float(stats.get("money_scale", 1.0)) * ELITE_REWARD


## What is wrong with the areas' "spawning" blocks, one message each.
## Only a farming ground has one; it names known enemies (no bosses) and
## keeps its numbers in range.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in content.areas:
		var area: Dictionary = content.areas[id]
		if not area.has("spawning"):
			continue
		var where := "areas.%s.spawning" % id
		var data: Variant = area["spawning"]
		if AreaRules.kind(content, id) != AreaRules.FARM:
			out.append(where + ": only a farming ground has one")
		if not data is Dictionary:
			out.append(where + ": expected an object")
			continue
		var from_x := float(data.get("from_x", -1.0))
		var width := float(area.get("width", 960))
		if from_x < 0.0 or from_x > width - SPAWN_CLEAR:
			out.append(where + ".from_x: inside the area, with room east of it")
		var camps: Variant = data.get("camps", [])
		if not camps is Array or camps.is_empty() or camps.size() > MAX_CAMPS:
			out.append("%s.camps: 1 to %d camp positions" % [where, MAX_CAMPS])
		else:
			for x: Variant in camps:
				if float(x) < from_x or float(x) > width - 12.0:
					out.append("%s.camps: %s is not between from_x and the east edge" % [where, x])
		var size := int(data.get("camp_size", 0))
		if size < 1 or size > MAX_CAMP_SIZE:
			out.append("%s.camp_size: 1 to %d" % [where, MAX_CAMP_SIZE])
		var aggro := float(data.get("aggro", 0.0))
		if aggro < MIN_AGGRO or aggro > MAX_AGGRO:
			out.append("%s.aggro: %d to %d" % [where, MIN_AGGRO, MAX_AGGRO])
		if int(data.get("respawn_ticks", 0)) < MIN_RESPAWN:
			out.append("%s.respawn_ticks: at least %d" % [where, MIN_RESPAWN])
		var reward := float(data.get("reward_scale", 1.0))
		if reward <= 0.0 or reward > 1.0:
			out.append(where + ".reward_scale: above 0, at most 1")
		var chance := float(data.get("elite_chance", 0.0))
		if chance < 0.0 or chance > MAX_ELITE_CHANCE:
			out.append("%s.elite_chance: 0 to %s" % [where, MAX_ELITE_CHANCE])
		for prize: Variant in data.get("elite_drops", []):
			var ok: bool = prize is Dictionary and float(prize.get("chance", 0.0)) > 0.0
			var item := content.item(str(prize.get("item", ""))) if prize is Dictionary else {}
			if not ok or item.get("type") != "equipment":
				out.append(where + ".elite_drops: [{item: gear, chance > 0}]")
		var pool: Variant = data.get("pool", {})
		if not pool is Dictionary or (pool as Dictionary).is_empty():
			out.append(where + ".pool: {enemy: weight}, at least one")
			continue
		for kind: String in pool:
			var enemy := content.enemy(kind)
			if enemy.is_empty() or enemy.get("boss", false) or float(pool[kind]) <= 0.0:
				out.append("%s.pool.%s: a known enemy, not a boss, weight > 0" % [where, kind])
	return out
