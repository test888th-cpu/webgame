class_name LairRules
extends RefCounted
## A lair (the field truck's "Rematches", SessionRules.REMATCH) and its one
## shared mini-boss (areas.json "mini_boss", one of the bosses). The whole lair
## (its ten blocks) has ONE mini-boss at a time, never one per block or per
## player. It runs through:
##
##   WAITING (nothing out yet) -> ACTIVE (out: spawned in one block, at one
##   spot, with its health) -> defeated -> RESPAWN_WAIT -> ACTIVE ...
##
## * When its time comes (at once the first time, then PERIOD_SECONDS after
##   each defeat, or the lair's "mini_boss_respawn_seconds") it turns up in one
##   eligible block picked at random ("mini_boss_blocks", every block when left
##   out), at a random spot along that block's street, clear of the edges where
##   heroes walk in. The pick is seeded by the lair and the time it was due, so
##   everyone (and the future server) agrees on the same block and spot.
## * It comes out the moment its time comes, even into the block a hero is
##   already standing in (watch, twice a second): no walking out and back in.
##   A hero elsewhere in the lair is told where it is ("lair_status").
## * Out, it stays until beaten: time passing, heroes leaving or nobody near
##   never take it away. Its health and place are recorded twice a second
##   (watch) and when a hero walks off (depart), so coming back, a reload or a
##   closed tab finds the same wounded mini-boss, not a new one.
## * Its defeat is resolved once (on_defeat checks the spawn is still out), and
##   starts exactly one wait for the next.
##
## Each spawn has its own number ("encounter"), so a defeat, a save or a
## reconnect never resolves the wrong one twice.
##
## Where the state lives: today, in the hero's own save (PlayerProfile.lairs),
## kept current in memory and written by the game's usual saves (every 20 s,
## on leaving the tab or closing, at once on a defeat). That is local,
## single-player persistence. Online (IL-7) the zone server holds one record
## per lair for every player and persists it itself, with these same rules;
## that is not built yet. Times are passed in. Pure rules, shared with the
## server.

const PERIOD_SECONDS := 1800
const WAITING := "waiting_for_spawn"
const ACTIVE := "active"
const RESPAWN_WAIT := "respawn_wait"
const STATES := [WAITING, ACTIVE, RESPAWN_WAIT]
## How far (px) from either end of a block a spawn stays (heroes walk in
## there), unless the lair sets "mini_boss_spawn_margin".
const SPAWN_MARGIN := 200.0
## How often (ticks) watch looks at the lair: twice a second.
const WATCH_TICKS := 30
## How close (px) to a hero a mini-boss may appear before it is set further off.
const HERO_CLEARANCE := 160.0


## The mini-boss roaming `lair_id`, or "".
static func boss(content: ContentDB, lair_id: String) -> String:
	return str(content.area(lair_id).get("mini_boss", ""))


## How far from either end of a block the mini-boss of `lair_id` turns up.
static func spawn_margin(content: ContentDB, lair_id: String) -> float:
	return float(content.area(lair_id).get("mini_boss_spawn_margin", SPAWN_MARGIN))


## Seconds from a defeat to the next mini-boss of `lair_id`: the lair's
## "mini_boss_respawn_seconds", else PERIOD_SECONDS (the default until the
## owner settles it).
static func respawn_seconds(content: ContentDB, lair_id: String) -> int:
	return int(content.area(lair_id).get("mini_boss_respawn_seconds", PERIOD_SECONDS))


## The blocks a mini-boss of `lair_id` may turn up in, from 1.
static func eligible_blocks(content: ContentDB, lair_id: String) -> Array[int]:
	var out: Array[int] = []
	for block: Variant in content.area(lair_id).get("mini_boss_blocks", []):
		out.append(int(block))
	if out.is_empty():
		for block in range(1, BlockRules.count(content, lair_id) + 1):
			out.append(block)
	return out


## Saved state cleaned to the known fields (PlayerProfile.from_dict).
static func clean(saved: Variant) -> Dictionary:
	var data: Dictionary = saved if saved is Dictionary else {}
	var out := {
		"state": str(data.get("state", WAITING)),
		"encounter": maxi(0, int(data.get("encounter", 0))),
		"block": maxi(0, int(data.get("block", 0))),
		"x": float(data.get("x", 0.0)),
		"y": float(data.get("y", 0.0)),
		"hp": int(data.get("hp", -1)),
		"max_hp": maxi(0, int(data.get("max_hp", 0))),
		"spawned_at": maxi(0, int(data.get("spawned_at", 0))),
		"defeated_at": maxi(0, int(data.get("defeated_at", 0))),
		"next_at": maxi(0, int(data.get("next_at", 0))),
	}
	if out["state"] not in STATES:
		out["state"] = WAITING
	if out["state"] == WAITING and out["next_at"] > 0:
		out["state"] = RESPAWN_WAIT
	return out


## `lair_id`'s state at `now`, bringing its mini-boss out when it is due (once:
## an ACTIVE one is never spawned again). Stored in `profile`.
static func observe(
	profile: PlayerProfile, content: ContentDB, lair_id: String, now: int
) -> Dictionary:
	var state := clean(profile.lairs.get(lair_id, {}))
	if boss(content, lair_id) != "" and state["state"] != ACTIVE and now >= state["next_at"]:
		var due_at: int = state["next_at"]
		var spot := spot_of(content, lair_id, due_at)
		state["state"] = ACTIVE
		state["encounter"] += 1
		state["block"] = block_of(content, lair_id, due_at)
		state["x"] = spot.x
		state["y"] = spot.y
		state["hp"] = -1
		state["max_hp"] = 0
		state["spawned_at"] = now
	profile.lairs[lair_id] = state
	return state


## When the next mini-boss of `lair_id` is due (0: now).
static func due(profile: PlayerProfile, lair_id: String) -> int:
	return int(clean(profile.lairs.get(lair_id, {}))["next_at"])


## The block the mini-boss due at `due_at` turns up in: one of the eligible
## blocks, picked by a generator seeded with the lair and the due time.
static func block_of(content: ContentDB, lair_id: String, due_at: int) -> int:
	var blocks := eligible_blocks(content, lair_id)
	return blocks[_rng(lair_id, due_at, "block").randi_range(0, blocks.size() - 1)]


## Where along its block the mini-boss due at `due_at` turns up: a random x
## clear of both ends (SPAWN_MARGIN), a random depth in the lane.
static func spot_of(content: ContentDB, lair_id: String, due_at: int) -> Vector2:
	var rng := _rng(lair_id, due_at, "spot")
	var width := float(content.area(lair_id).get("width", 960))
	var low := ZoneSim.EDGE_MARGIN + spawn_margin(content, lair_id)
	var high := maxf(low, width - ZoneSim.EDGE_MARGIN - spawn_margin(content, lair_id))
	var depth := ZoneSim.LANE_TOP + 15.0
	return Vector2(
		rng.randf_range(low, high), rng.randf_range(depth, depth + ZoneSim.LANE_DEPTH - 30.0)
	)


static func _rng(lair_id: String, due_at: int, what: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s:%d:%s" % [lair_id, due_at, what]).hash()
	return rng


## True when the mini-boss is out in block `block` of `lair_id` at `now`.
static func here(
	profile: PlayerProfile, content: ContentDB, lair_id: String, block: int, now: int
) -> bool:
	if boss(content, lair_id) == "":
		return false
	var state := observe(profile, content, lair_id, now)
	return state["state"] == ACTIVE and state["block"] == block


## Puts the mini-boss into `zone` when it is out in its block at `now`: at its
## spot (clear of walls, and of the hero), with the health it was left on.
## Returns it, or null.
static func arrive(zone: ZoneSim, now: int) -> Fighter:
	if AreaRules.kind(zone.content, zone.area_id) != AreaRules.LAIR:
		return null
	if not here(zone.profile, zone.content, zone.area_id, zone.block, now):
		return null
	var state: Dictionary = zone.profile.lairs[zone.area_id]
	var at := Vector2(state["x"], state["y"])
	if absf(at.x - zone.hero.position.x) < HERO_CLEARANCE:
		var away := 1.0 if at.x >= zone.hero.position.x else -1.0
		at.x = clampf(
			zone.hero.position.x + away * HERO_CLEARANCE, zone.bounds.position.x, zone.bounds.end.x
		)
		if absf(at.x - zone.hero.position.x) < HERO_CLEARANCE:
			at.x = zone.hero.position.x - away * HERO_CLEARANCE
	at = Bodies.clear_spot(at, zone.solids, zone.bounds)
	var fighter := zone.spawn_enemy(boss(zone.content, zone.area_id), at)
	if int(state["hp"]) > 0:
		fighter.hp = mini(int(state["hp"]), fighter.max_hp)
	state["max_hp"] = fighter.max_hp
	return fighter


## The mini-boss on its feet in `zone`, or null.
static func present(zone: ZoneSim) -> Fighter:
	for enemy in zone.enemies():
		if enemy.kind == boss(zone.content, zone.area_id) and not enemy.is_ko():
			return enemy
	return null


## Records the mini-boss's health and place from `zone` (its block) into the
## lair's state, while it is out and standing. Memory only: the game's saves
## write it.
static func sync(zone: ZoneSim) -> void:
	if AreaRules.kind(zone.content, zone.area_id) != AreaRules.LAIR:
		return
	var state := clean(zone.profile.lairs.get(zone.area_id, {}))
	var standing := present(zone)
	if state["state"] != ACTIVE or state["block"] != zone.block or standing == null:
		return
	state["hp"] = standing.hp
	state["max_hp"] = standing.max_hp
	state["x"] = standing.position.x
	state["y"] = standing.position.y
	zone.profile.lairs[zone.area_id] = state


## A hero walking off `zone` (any way out): the mini-boss stays where it is,
## with the health it has now, for whoever comes next.
static func depart(zone: ZoneSim) -> void:
	sync(zone)


## Runs after each zone tick (Game.step), with that tick's `events` (returned,
## with any added). Twice a second in a lair: a defeat in `events` is resolved
## (once; the game's own call then finds it done), the health and place are
## recorded (sync), and when the lair's mini-boss is due it comes out: into
## this block at once ("spawn"), wherever the hero stands in it, or, when it
## is out in another block, the hero is told ("lair_status").
static func watch(zone: ZoneSim, now: int, events: Array[ZoneEvent]) -> Array[ZoneEvent]:
	var lair := zone.area_id
	if AreaRules.kind(zone.content, lair) != AreaRules.LAIR or boss(zone.content, lair) == "":
		return events
	for event in events:
		if event.type == "defeat":
			on_defeat(zone.profile, zone.content, lair, str(event.data.get("kind", "")), now)
	if zone.tick_count % WATCH_TICKS != 0:
		return events
	sync(zone)
	var before := clean(zone.profile.lairs.get(lair, {}))
	var state := observe(zone.profile, zone.content, lair, now)
	if state["state"] != ACTIVE:
		return events
	if state["block"] == zone.block:
		if present(zone) == null:
			var out := arrive(zone, now)
			if out:
				events.append(
					ZoneEvent.make("spawn", {"id": out.id, "kind": out.kind, "boss": true})
				)
	elif before["state"] != ACTIVE or before["encounter"] != state["encounter"]:
		var text := status_text(zone.profile, zone.content, lair, now)
		events.append(ZoneEvent.make("lair_status", {"block": state["block"], "text": text}))
	return events


## A defeat of `kind` in `area_id` at `now`: when it is that lair's mini-boss
## and one is out, it is resolved (once) and the next is due
## respawn_seconds later. True when it was resolved now.
static func on_defeat(
	profile: PlayerProfile, content: ContentDB, area_id: String, kind: String, now: int
) -> bool:
	if AreaRules.kind(content, area_id) != AreaRules.LAIR or kind != boss(content, area_id):
		return false
	var state := clean(profile.lairs.get(area_id, {}))
	if state["state"] != ACTIVE:
		return false
	state["state"] = RESPAWN_WAIT
	state["hp"] = 0
	state["defeated_at"] = now
	state["next_at"] = now + respawn_seconds(content, area_id)
	profile.lairs[area_id] = state
	return true


## The mini-boss's state in words (the field truck, "lair_status"): "<name>
## out in Block 4/10, HP 3200/9000" (HP only once a hero has met it and it is
## known; "unhurt" before), "<name> back in 12m" while it waits. The lair is
## looked at `now` (observe), so a spawn that is due shows as out.
static func status_text(
	profile: PlayerProfile, content: ContentDB, lair_id: String, now: int
) -> String:
	var kind := boss(content, lair_id)
	if kind == "":
		return ""
	var name := str(content.enemy(kind).get("name", kind))
	var state := observe(profile, content, lair_id, now)
	if state["state"] == ACTIVE:
		var where := "%s out in %s" % [name, BlockRules.label(content, lair_id, state["block"])]
		if state["hp"] > 0 and state["max_hp"] > 0:
			return where + ", HP %d/%d" % [state["hp"], state["max_hp"]]
		return where + ", unhurt" if state["hp"] < 0 else where
	var minutes := ceili(maxf(0.0, state["next_at"] - now) / 60.0)
	return "%s back in %dm" % [name, maxi(1, minutes)]


## What is wrong with the lairs: each names a boss as its mini-boss, is ten
## blocks long, and any eligible blocks and respawn time it sets are valid.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for lair_id in AreaRules.lairs(content):
		var where := "areas.%s" % lair_id
		var kind := boss(content, lair_id)
		if not content.enemy(kind).get("boss", false):
			out.append(where + ".mini_boss: a boss enemy")
		if BlockRules.count(content, lair_id) != 10:
			out.append(where + ".blocks: a lair is ten blocks for its mini-boss to roam")
		for block in eligible_blocks(content, lair_id):
			if block < 1 or block > BlockRules.count(content, lair_id):
				out.append("%s.mini_boss_blocks: %d is not a block" % [where, block])
		if respawn_seconds(content, lair_id) < 1:
			out.append(where + ".mini_boss_respawn_seconds: at least 1")
		var margin := spawn_margin(content, lair_id)
		if margin < 0.0 or margin * 2.0 >= float(content.area(lair_id).get("width", 960)):
			out.append(where + ".mini_boss_spawn_margin: from 0 to under half the width")
	for id: String in content.areas:
		var a: Dictionary = content.areas[id]
		var stray := false
		for field in ["mini_boss_blocks", "mini_boss_respawn_seconds", "mini_boss_spawn_margin"]:
			stray = stray or a.has(field)
		if (a.has("mini_boss") or stray) and AreaRules.kind(content, id) != AreaRules.LAIR:
			out.append("areas.%s: only a lair has a mini-boss" % id)
	return out
