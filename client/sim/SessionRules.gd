class_name SessionRules
extends RefCounted
## The session types the world is split into (ARCHITECTURE.md D9), and
## which one each area runs as. The zone allocator (M3) and the zone server
## (IL-7) read these rules so a story area can never be backed by shared
## state; today the single-player client reads them the same way.
##
## * STORY: a Story Instance. One per hero, holding exactly that hero. Its
##   enemies, boss HP and phase, encounters, quest steps, evidence and story
##   events belong to that hero alone. No other hero may enter, join, help or
##   interfere, and no daily cap, attempt cap or waiting time applies to it.
##   Every street area (AreaRules.STREET) is one, cleared or not. Its boss
##   fights can be replayed without limit (ReplayRules).
## * FARMING: a Farming Ground, shared. Normal enemies and its elites
##   (FarmSpawner); never a boss or a mini-boss (problems).
## * REMATCH: a lair (the field truck's "Rematches"), shared, ten blocks with
##   ONE mini-boss among them (LairRules) on top of the camps.
## * WORLD_BOSS: a World Boss arena, shared: many heroes against one boss and
##   one health pool per round (WorldBossRules), on its own clock, with its
##   reinforcements (BossMechanics). It never gates and is never gated by the
##   story.
## * HUB: the city, shared: merchants, taxis, no fights.
##
## The instance key says which simulation a hero joins. Keys of different
## types never collide, and a story key always carries its owner, so two
## heroes can never land in the same story instance. Pure rules, shared with
## the server.

const STORY := "story_instance"
const FARMING := "farming_ground"
const REMATCH := "rematch"
const WORLD_BOSS := "world_boss_event"
const HUB := "hub"
const TYPES := [STORY, FARMING, REMATCH, WORLD_BOSS, HUB]
## The shared types: one copy for everyone (sharded by the allocator when full).
const SHARED_TYPES := [FARMING, REMATCH, WORLD_BOSS, HUB]
## A story instance holds its owner and nobody else.
const STORY_CAPACITY := 1
## Every area kind and the session type it runs as. A new kind must be added
## here (test_session_rules checks every kind is covered).
const BY_KIND := {
	AreaRules.STREET: STORY,
	AreaRules.CITY: HUB,
	AreaRules.FARM: FARMING,
	AreaRules.LAIR: REMATCH,
	AreaRules.WORLD_BOSS: WORLD_BOSS,
}


## The session type (one of TYPES) `area_id` runs as.
static func session_type(content: ContentDB, area_id: String) -> String:
	return str(BY_KIND[AreaRules.kind(content, area_id)])


## True when `area_id`'s state belongs to one hero alone.
static func is_private(content: ContentDB, area_id: String) -> bool:
	return session_type(content, area_id) == STORY


## The instance `hero_id` joins in `area_id` at Unix time `now`:
## * a story area: "story/<hero>/<area>", the hero's own copy;
## * a shared area: "<type>/<area>" (the allocator adds a shard number when
##   one copy is full);
## * a world boss arena: "world_boss/<boss>/<round>", one per round of the
##   boss's clock, the same for everyone.
## "" when a story key is asked for without a hero, so no story instance is
## ever opened without an owner.
static func instance_key(content: ContentDB, area_id: String, hero_id: String, now: int) -> String:
	match session_type(content, area_id):
		STORY:
			return "" if hero_id == "" else "story/%s/%s" % [hero_id, area_id]
		WORLD_BOSS:
			var boss := arena_boss(content, area_id)
			var round := int(WorldBossRules.window(content, boss, now)["round"]) if boss else 0
			return "world_boss/%s/%d" % [boss if boss else area_id, round]
	return "%s/%s" % [session_type(content, area_id), area_id]


## The world boss fought in arena `area_id`, or "" when none is.
static func arena_boss(content: ContentDB, area_id: String) -> String:
	for boss: String in content.world_bosses:
		if str(content.world_bosses[boss].get("area", "")) == area_id:
			return boss
	return ""


## True when `hero_id` may join an instance of `area_id` that `occupants`
## (hero ids) are already in. A story instance admits only its owner: it is
## empty, or holds the owner alone (a reconnect within the grace period).
## Shared and world boss instances admit anyone; their population caps are
## the allocator's (PERFORMANCE.md), not a rule of the area.
static func may_join(
	content: ContentDB, area_id: String, hero_id: String, owner_id: String, occupants: Array
) -> bool:
	if hero_id == "":
		return false
	if session_type(content, area_id) != STORY:
		return true
	if hero_id != owner_id:
		return false
	for other: Variant in occupants:
		if str(other) != hero_id:
			return false
	return occupants.size() <= STORY_CAPACITY


## What would mix the types up, one message each (empty when nothing): a
## farming ground holding a boss (story, lair or world boss) in its pool,
## camps, fights or placed enemies. ContentDB.validate adds these.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for area_id in AreaRules.farms(content):
		var area := content.area(area_id)
		var kinds: Array = area.get("spawning", {}).get("pool", {}).keys()
		for placed: Dictionary in area.get("placed", []):
			kinds.append(placed.get("enemy", ""))
		for encounter: Dictionary in area.get("encounters", []):
			for wave: Array in encounter.get("waves", []):
				kinds.append_array(wave)
		for kind: Variant in kinds:
			if content.enemy(str(kind)).get("boss", false):
				out.append("areas.%s: a farming ground has no boss (%s)" % [area_id, kind])
	return out
