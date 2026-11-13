class_name SessionRules
extends RefCounted
## The three session types the world is split into (ARCHITECTURE.md D9), and
## which one each area runs as. The zone allocator (M3) and the zone server
## (IL-7) read these rules so a story area can never be backed by shared
## state; today the single-player client reads them the same way.
##
## * STORY: a Story Instance. One per hero, holding exactly that hero. Its
##   enemies, boss HP and phase, encounters, quest steps, evidence and story
##   events belong to that hero alone. No other hero may enter, join, help or
##   interfere, and no daily cap, attempt cap or waiting time applies to it.
##   Every street area (AreaRules.STREET) is one, cleared or not.
## * SHARED: a Shared Area. The city, the farming grounds and the boss lairs
##   (a farming ground with a roaming mini-boss), where many heroes meet and
##   the shared spawning rules (FarmSpawner, LairRules) apply.
## * WORLD_BOSS: a World Boss/Event Area. Many heroes against one boss and one
##   health pool per round (WorldBossRules), on its own clock. It never gates
##   and is never gated by story progress.
##
## The instance key says which simulation a hero joins. Keys of different
## types never collide, and a story key always carries its owner, so two
## heroes can never land in the same story instance. Pure rules, shared with
## the server.

const STORY := "story_instance"
const SHARED := "shared_area"
const WORLD_BOSS := "world_boss_event"
const TYPES := [STORY, SHARED, WORLD_BOSS]
## A story instance holds its owner and nobody else.
const STORY_CAPACITY := 1
## Every area kind and the session type it runs as. A new kind must be added
## here (test_session_rules checks every kind is covered).
const BY_KIND := {
	AreaRules.STREET: STORY,
	AreaRules.CITY: SHARED,
	AreaRules.FARM: SHARED,
	AreaRules.LAIR: SHARED,
	AreaRules.WORLD_BOSS: WORLD_BOSS,
}


## STORY, SHARED or WORLD_BOSS for `area_id`.
static func session_type(content: ContentDB, area_id: String) -> String:
	return str(BY_KIND[AreaRules.kind(content, area_id)])


## True when `area_id`'s state belongs to one hero alone.
static func is_private(content: ContentDB, area_id: String) -> bool:
	return session_type(content, area_id) == STORY


## The instance `hero_id` joins in `area_id` at Unix time `now`:
## * a story area: "story/<hero>/<area>", the hero's own copy;
## * a shared area: "shared/<area>" (the allocator adds a shard number when
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
	return "shared/%s" % area_id


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
