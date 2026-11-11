class_name LairRules
extends RefCounted
## A lair's mini-boss (areas.json "mini_boss", one of the bosses): it roams
## the lair's blocks among the camps, turning up in one block picked at random
## each time, with no warning and no arena: it is simply there. Once beaten it
## comes back PERIOD_SECONDS later, in another block. The profile keeps when
## each lair's next one is due ("lairs", unix seconds; due at once when not
## kept), so leaving and coming back does not bring it early. Times are passed
## in; the block is a hash of the lair and the due time, so it is the same for
## every visit until it is beaten. Pure rules, shared with the server.

const PERIOD_SECONDS := 1800


## The mini-boss roaming `lair_id`, or "".
static func boss(content: ContentDB, lair_id: String) -> String:
	return str(content.area(lair_id).get("mini_boss", ""))


## When the next mini-boss of `lair_id` is due (0: now).
static func due(profile: PlayerProfile, lair_id: String) -> int:
	return int(profile.lairs.get(lair_id, 0))


## The block the mini-boss due at `due_at` turns up in, from 1.
static func block_of(content: ContentDB, lair_id: String, due_at: int) -> int:
	var key := "%s:%d" % [lair_id, due_at]
	return 1 + absi(key.hash()) % BlockRules.count(content, lair_id)


## True when the mini-boss is out in block `block` of `lair_id` at `now`.
static func here(
	profile: PlayerProfile, content: ContentDB, lair_id: String, block: int, now: int
) -> bool:
	if boss(content, lair_id) == "" or now < due(profile, lair_id):
		return false
	return block == block_of(content, lair_id, due(profile, lair_id))


## Puts the mini-boss into `zone` when it is out in its block at `now`, ahead
## of the hero in the middle of the street. Returns it, or null.
static func arrive(zone: ZoneSim, now: int) -> Fighter:
	if AreaRules.kind(zone.content, zone.area_id) != AreaRules.LAIR:
		return null
	if not here(zone.profile, zone.content, zone.area_id, zone.block, now):
		return null
	var at := Vector2(zone.bounds.get_center().x, ZoneSim.LANE_TOP + ZoneSim.LANE_DEPTH / 2.0)
	return zone.spawn_enemy(boss(zone.content, zone.area_id), at)


## A defeat of `kind` in `area_id` at `now`: when it is that lair's mini-boss,
## the next one is due PERIOD_SECONDS later. True when it was.
static func on_defeat(
	profile: PlayerProfile, content: ContentDB, area_id: String, kind: String, now: int
) -> bool:
	if AreaRules.kind(content, area_id) != AreaRules.LAIR or kind != boss(content, area_id):
		return false
	profile.lairs[area_id] = now + PERIOD_SECONDS
	return true


## What is wrong with the lairs: each names a boss as its mini-boss and is
## more than one block long.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for lair_id in AreaRules.lairs(content):
		var where := "areas.%s" % lair_id
		var kind := boss(content, lair_id)
		if not content.enemy(kind).get("boss", false):
			out.append(where + ".mini_boss: a boss enemy")
		if BlockRules.count(content, lair_id) < 2:
			out.append(where + ".blocks: a lair is several blocks for its mini-boss to roam")
	return out
