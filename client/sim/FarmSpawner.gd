class_name FarmSpawner
extends RefCounted
## A farming ground's living field (areas.json "spawning"): enemies keep
## coming, so the hero fights on without walking back for another round.
##
## The field fills up to `cap` enemies standing, one every FILL_TICKS. After
## that enemies come in packs, as in the field games it follows: once there is
## room for a whole `pack` (cap less pack standing), the next pack arrives
## `respawn_ticks` later, running in together from one side, PACK_STAGGER
## ticks apart. So the fighting comes in bursts and the next pack is already
## on its way as the last one falls; the respawn time sets the pace (and the
## income, tuned with the harness). Each enters away from the hero (at least
## MIN_GAP, off camera when the field allows) and never west of `from_x`, so
## the way out and the arrival
## spot stay calm: enemies keep east of `from_x` less SAFE_MARGIN, so the
## west end (where the hero arrives and comes to) is a safe spot. Who comes
## is drawn from `pool` ({enemy: weight}); one in `elite_chance` is an
## elite: tougher, worth ELITE_REWARD times the XP, coins and loot rolls,
## named in gold, with a chance at the ground's own prizes (`elite_drops`,
## [{item, chance}]: the Epic gear of its district's bosses).
## Nothing locks the hero in and nothing here is saved: leaving and coming
## back starts a fresh field. Rewards are paid where every enemy's are
## (ZoneSim._defeat). Pure rules on ZoneSim's seeded rng, shared with the
## server.

## Ticks between spawns while the field first fills (half a second).
const FILL_TICKS := 30
## How far west of `from_x` an enemy may follow the hero (the safe spot is
## west of that line).
const SAFE_MARGIN := 120.0
## The nearest an enemy enters to the hero.
const MIN_GAP := 180.0
## Past this distance an entrance is off camera (half the 640 px canvas).
const OFF_CAMERA := 340.0
## An elite's toughness and what it is worth, against its plain kind.
const ELITE_HP := 3.0
const ELITE_POWER := 1.25
const ELITE_REWARD := 3.0
const MAX_CAP := 8
const MIN_RESPAWN := 30
const MAX_ELITE_CHANCE := 0.25
## Ticks between the members of a pack running in, and how far apart they
## enter.
const PACK_STAGGER := 12
const PACK_SPREAD := 28.0

var _timer := 0
var _filled := false
## Members of the arriving pack still to come in, where it enters and the
## ticks to the next one.
var _coming := 0
var _pack_x := 0.0
var _stagger := 0
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


## One step of the field: counts who is standing and, when it is time, sends
## the next one or the next pack in. Does nothing in an area without "spawning".
func tick(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	var data := spec(zone.content, zone.area_id)
	if data.is_empty():
		return
	_pay_elites(zone)
	var standing := 0
	var west := float(data["from_x"]) - SAFE_MARGIN
	for enemy in zone.enemies():
		if not enemy.is_ko() and zone.brains.has(enemy.id):
			standing += 1
			enemy.position.x = maxf(enemy.position.x, west)
	var cap := int(data["cap"])
	if _coming > 0:
		_stagger -= 1
		if _stagger <= 0:
			_coming -= 1
			_stagger = PACK_STAGGER
			var offset := zone.rng.randf_range(-PACK_SPREAD, PACK_SPREAD)
			_spawn(zone, data, events, _pack_x + offset)
		return
	if standing >= cap:
		_filled = true
		_timer = 0
		return
	if not _filled:
		_timer += 1
		if _timer >= FILL_TICKS:
			_timer = 0
			_spawn(zone, data, events)
		return
	var pack := mini(pack_size(data), cap)
	if cap - standing < pack:
		_timer = 0
		return
	_timer += 1
	if _timer < int(data["respawn_ticks"]):
		return
	_timer = 0
	_coming = pack
	_stagger = 0
	_pack_x = entry_x(zone, float(data["from_x"]))


## How many enemies come in together once the field has filled ("pack",
## default 1).
static func pack_size(data: Dictionary) -> int:
	return maxi(1, int(data.get("pack", 1)))


func _spawn(zone: ZoneSim, data: Dictionary, events: Array[ZoneEvent], at := -1.0) -> void:
	var kind := _draw(data["pool"], zone.rng)
	var west := maxf(float(data["from_x"]), zone.bounds.position.x + 12.0)
	var x := (
		entry_x(zone, float(data["from_x"]))
		if at < 0.0
		else clampf(at, west, zone.bounds.end.x - 12.0)
	)
	var lane := zone.bounds
	var y := zone.rng.randf_range(lane.position.y + 10.0, lane.end.y - 10.0)
	var enemy := zone.spawn_enemy(kind, Bodies.clear_spot(Vector2(x, y), zone.solids, lane))
	var elite := zone.rng.randf() < float(data.get("elite_chance", 0.0))
	if elite:
		_make_elite(zone, enemy)
		_elites[enemy.id] = true
	events.append(
		ZoneEvent.make("spawn", {"id": enemy.id, "kind": kind, "boss": false, "elite": elite})
	)


## Where along the field the next enemy enters: a random spot east of
## `from_x` at least MIN_GAP from the hero, off camera when one is, else the
## spot furthest from the hero.
static func entry_x(zone: ZoneSim, from_x: float) -> float:
	var west := maxf(from_x, zone.bounds.position.x + 12.0)
	var east := zone.bounds.end.x - 12.0
	var hero_x := zone.hero.position.x
	var best := west if absf(west - hero_x) > absf(east - hero_x) else east
	var near := -INF
	for i in 8:
		var x := zone.rng.randf_range(west, east)
		var gap := absf(x - hero_x)
		if gap >= OFF_CAMERA:
			return x
		if gap >= MIN_GAP and gap > near:
			near = gap
			best = x
	return best


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
		var loot: Dictionary = zone.content.enemy(enemy.kind).get("loot", {})
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
		var cap := int(data.get("cap", 0))
		if cap < 1 or cap > MAX_CAP:
			out.append("%s.cap: 1 to %d" % [where, MAX_CAP])
		var pack := int(data.get("pack", 1))
		if pack < 1 or pack > cap:
			out.append("%s.pack: 1 to cap" % where)
		if int(data.get("respawn_ticks", 0)) < MIN_RESPAWN:
			out.append("%s.respawn_ticks: at least %d" % [where, MIN_RESPAWN])
		var chance := float(data.get("elite_chance", 0.0))
		if chance < 0.0 or chance > MAX_ELITE_CHANCE:
			out.append("%s.elite_chance: 0 to %s" % [where, MAX_ELITE_CHANCE])
		var from_x := float(data.get("from_x", -1.0))
		if from_x < 0.0 or from_x > float(area.get("width", 960)) - MIN_GAP:
			out.append(where + ".from_x: inside the area, with room east of it")
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
